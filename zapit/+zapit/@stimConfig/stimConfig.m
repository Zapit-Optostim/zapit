classdef stimConfig < handle

    % Configuration file handling class
    %
    % zapit.stimConfig
    %
    % Purpose
    % This class handles configuration files used to determine where the laser stim locations are.
    %
    % Rob Campbell - SWC 2022

    properties

        configFileName % file name of the loaded stimConfig file

        laserPowerInMW
        stimFreqInHz
        stimLocations
        offRampDownDuration_ms

    end % properties

    properties (Hidden)
        parent  % the zapit.pointer to which this is attached
        numSamplesPerChannel
        atlasData
    end

    % read-only properties that are associated with getters
    properties(SetAccess=protected, GetAccess=public)
        chanSamples % The waveforms to be sent to the scanners
    end


    methods

        function obj = stimConfig(fname)
            % Construct a stimConfig file object and load data
            % 
            % zapit.stimConfig.stimConfig
            %

            % Load the atlas data so we can find brain areas names from coordinates
            load('atlas_data.mat')
            obj.atlasData = atlas_data;

            obj.loadConfig(fname)
        end % Constructor


        function delete(obj)
            % zapit.stimConfig.delete

        end % Destructor


        function loadConfig(obj,fname)
            % Load a YAML config file
            %
            % zaptit.stimConfig.loadConfig(fname)

            if ~exist(fname)
                fprintf('No config file found at "%s"\n', fname)
                return
            end

            data = zapit.yaml.ReadYaml(fname);

            obj.laserPowerInMW = data.laserPowerInMW;
            obj.stimFreqInHz = data.stimFreqInHz;
            obj.offRampDownDuration_ms = data.offRampDownDuration_ms;

            % Loop through a import all stimLocations
            obj.stimLocations = struct('ML',[],'AP',[]);
            ind = 1;
            while true
                fieldName = sprintf('stimLocations%02d',ind);
                if isfield(data,fieldName)
                    tmp = data.(fieldName);
                    if length(tmp.ML)>1
                        tmp.ML = cell2mat(tmp.ML);
                        tmp.AP = cell2mat(tmp.AP);
                    end
                    obj.stimLocations(ind) = tmp;
                else
                    break
                end
                ind = ind + 1;
            end
            obj.configFileName = fname;
        end % loadConfig


        function writeConfig(obj,fname)
            % Write a YAML config file
            %
            % zapit.stimConfig.writeConfig(fname)
            %
            % Purpose
            % Write properties into a stim config YAML file that can be re-read.

            data.laserPowerInMW = obj.laserPowerInMW;
            data.stimFreqInHz = obj.stimFreqInHz;
            data.offRampDownDuration_ms = obj.offRampDownDuration_ms;

            for ii = 1:length(obj.stimLocations)
                fieldName = sprintf('stimLocations%02d',ii);
                data.(fieldName) = obj.stimLocations(ii);
            end

            zapit.yaml.WriteYaml(fname,data);
        end % writeConfig


        function logStimulusParametersToFile(obj, filePath)
            % Write all relevant data associated with this set of stimuli to a YAML file
            %
            % function logStimulusParametersToFile(obj, filePath)
            %
            % Purpose
            % Create a log file so we know exactly under what conditions stimuli were
            % presented in an experiment. This includes not only stimulus locations and
            % parameters but also software version. It is critical to generate this file
            % or it may not be possible to analyse data afterwards.
             
            v = zapit.version;
            data.zapitVersion = v.message;

            v=ver('MATLAB');
            data.MATLAB = sprintf('%s %s version %s', v.Name, v.Release, v.Version);

            [~, hostname] = system('hostname');
            data.hostname = strip(hostname);

            data.laserPowerInMW = obj.laserPowerInMW;
            data.stimFreqInHz = obj.stimFreqInHz;
            data.offRampDownDuration_ms = obj.offRampDownDuration_ms;

            for ii = 1:length(obj.stimLocations)
                fieldName = sprintf('stimLocations%02d',ii);
                data.(fieldName) = obj.stimLocations(ii);
            end

            fname = sprintf('zapit_log_%s.yml', datestr(now,'yyyy_mm_dd__HH-MM'));

            zapit.yaml.WriteYaml(fullfile(filePath,fname), data);
        end % logStimulusParametersToFile


        function cPoints = calibratedPoints(obj) 
            % The stimulation locations after they have been calibrated to the sample
            % 
            % zapit.stimConfig.calibratedPoints
            %
            % Purpose
            % Places the stereotaxic target coords in stimLocations into the sample
            % space being imaged by the camera. It does this using the estimate of 
            % bregma plus one more stereotaxic point that are stored in refPointsSample.
            %
            % Inputs
            % none
            %
            % Outputs
            % A cell array of converted coordinates. The cells correspond in order to
            % the orginal data in the structure stimLocations. If the cells are 
            % concatenated as [cPoints{:}] then the first row is ML coords and second
            % row is AP coords. All in mm.
            %

            cPoints = {};

            if isempty(obj.parent.refPointsSample)
                fprintf('Sample has not been calibrated! Returning empty data! \n')
                return
            end

            for ii = 1:length(obj.stimLocations)
                tmpMat = [obj.stimLocations(ii).ML; obj.stimLocations(ii).AP];
                cPoints{ii} = zapit.utils.rotateAndScaleCoords(...
                            tmpMat, ...
                            obj.parent.refPointsStereotaxic, ...
                            obj.parent.refPointsSample);
            end
        end % calibratedPoints


        function cPointsVolts = calibratedPointsInVolts(obj)
            % Convert the calibrated points (sample space) into voltage values for the scanners
            %
            % zapit.stimConfig.calibratedPointsInVolts
            %
            % Purpose
            % This method returns voltage values that can be sent to the scanners in order
            % to point the beam at the locations defined calibratedPoints.
            %
            % Inputs
            % none
            %
            % Outputs
            % A cell array of coordinates converted into voltages. The cells correspond in order 
            % to the orginal data in the structure stimLocations. If the cells are concatenated 
            % as [cPointsVolts{:}] then the first column is ML coords and second column is AP 
            % coords. All in volts. NOTE this is transposed with respect to calibratedPoints
            %

            cPointsVolts = {};

            calibratedPoints = obj.calibratedPoints;

            if isempty(calibratedPoints)
                return 
            end

            for ii = 1:length(calibratedPoints)
                [xVolt, yVolt] = obj.parent.mmToVolt(calibratedPoints{ii}(1,:), ...
                                                    calibratedPoints{ii}(2,:));
                cPointsVolts{ii} = [xVolt' yVolt'];
            end

        end % calibratedPointsInVolts


        function print(obj)
            % Print to the command line the index, coordinates, and brain area of each condition
            %
            % zapit.stimConfig
            %
            % Purpose
            % Provide a summary of the conditions in this stimulus configuration file
            % by printing to the command line what is in each stimulus condition. Example
            % output:
            %
            %  1. ML = +2.57 / AP = -3.58  <-->  ML = -2.57 / AP = -3.58  1' visual 
            %  2. ML = +0.54 / AP = +0.17  <-->  ML = -0.54 / AP = +0.17  2' motor 
            %  3. ML = +1.94 / AP = -1.18  <-->  ML = -1.94 / AP = -1.18  1' somatosensory trunk
            %  4. ML = -0.04 / AP = -3.89  Superior colliculus zonal layer

            fprintf('\n')
            for ii=1:length(obj.stimLocations)
                tStim = obj.stimLocations(ii);
                areaNames = obj.getAreaNameFromCoords(tStim.ML, tStim.AP);

                fprintf('%d. ', ii)
                if length(tStim.ML)>1
                    fprintf('ML = %+0.2f / AP = %+0.2f  <-->  ML = %+0.2f / AP = %+0.2f  ', ...
                        tStim.ML(1), tStim.AP(1), tStim.ML(2), tStim.AP(2))

                    areaNames = unique(areaNames);
                    if length(areaNames) == 1
                        fprintf('%s\n', areaNames{1})
                    else
                        fprintf('%s  <-->  %s\n', areaNames{:})
                    end
                else
                    fprintf('ML = %+0.2f / AP = %+0.2f  %s\n', tStim.ML, tStim.AP, areaNames)
                end
            end % for
        end % print


        function chanSamples = get.chanSamples(obj)
            % Prepares voltages for each photostimulation site
            %
            % zapit.stimConfig.chanSamples
            %
            % Purpose
            % The calibratedPoints getter returns the locations of stimulus points in sample space.
            % The calibratedPointsInVolts converts this to volts. This method uses these voltage 
            % values to generate waveforms that can be played with a clocked NI output task in order
            % stimulate the sample at the laser power and rep rate defined by properties of this 
            % class. 
            %
            % Inputs
            % none
            %
            % Outputs
            % chanSamples
            %
            % Maja Skretowska - SWC 2021
            % Updated by Rob Campbell - SWC 2023 to cope with new stimulus structure

            if nargin<2
                calibratedPointsInVolts = obj.calibratedPointsInVolts;
            else
                calibratedPointsInVolts = IN;
            end

            numHalfCycles = 4; % The number of half cycles to buffer
                               % TODO -- see if 1 cycle works then we can get rid of this. 

            % TODO -- we need to make sure that the number of samples per second here is the right number
            obj.numSamplesPerChannel = obj.parent.DAQ.samplesPerSecond/obj.stimFreqInHz*(numHalfCycles/2);

            % make up samples for scanner channels (of course calibratedPointsInVolts is already in volt format)
            % In scanChnl, 1st dim is samples, 2nd dim is channel, 3rd dim is conditions
            scanChnl = zeros(obj.numSamplesPerChannel,2,length(calibratedPointsInVolts)); % matrix for each channel

            % Fill in the matrices for the galvos
            for inactSite = 1:length(calibratedPointsInVolts) % Loop over stim conditions

                % If this position is a single point we duplicate it to spoof two points
                if size(calibratedPointsInVolts{inactSite},1) == 1
                    t_volts = repmat(calibratedPointsInVolts{inactSite},2,1);
                else
                    t_volts = calibratedPointsInVolts{inactSite};
                end

                % inactSite gets column from the coordinates library
                xVolts = t_volts(:,1);
                xVolts = repmat(xVolts', 1, numHalfCycles/2);

                yVolts = t_volts(:,2);
                yVolts = repmat(yVolts', 1, numHalfCycles/2);

                % Repeat the above but vectorized
                Y = repmat(yVolts,obj.numSamplesPerChannel/numHalfCycles,1);
                X = repmat(xVolts,obj.numSamplesPerChannel/numHalfCycles,1);

                scanChnl(:,1,inactSite) = X(:);
                scanChnl(:,2,inactSite) = Y(:);

            end
            


            % fill in the matrices for the laser. Generally these will be the same for all 
            % conditions, but situations with one position will be different so we have to 
            % make them all (see repmat later)

            % find edges of half cycles (the indexes at which the beam moves or laser changes state)
            edgeSamples = ceil(linspace(1, obj.numSamplesPerChannel, numHalfCycles+1));
            % CAN ALSO DO: edgeSamples = [1; find(abs(diff(scanChnl(:,2,inactSite)))>0)+1; obj.numSamplesPerChannel]';

            laserControlVoltage = obj.parent.laser_mW_to_control(obj.laserPowerInMW);

            %% make up samples for laser and masking light channels
            anlgOut = ones(1,obj.numSamplesPerChannel) * laserControlVoltage; %Write the correct control voltage
            digOut = ones(1,obj.numSamplesPerChannel) * 5; % 5V TTL

            % allow 1 ms around halfcycle change to be 0 (in case scanners are not in the right spot
            MASK = ones(1,obj.numSamplesPerChannel);
            sampleInterval = 1/obj.parent.DAQ.samplesPerSecond;
            nSamplesInOneMS = 1E-3 / sampleInterval;

            for ii=1:nSamplesInOneMS
                MASK(edgeSamples(1:end-1)+(ii-1))=0;
            end

            anlgOut = anlgOut.*MASK;
            digOut = digOut.*MASK;

            lghtChnl(:,1) = anlgOut;  % analog laser output
            lghtChnl(:,2) = digOut;   % digital out for masking light

            % Expand out to match scanners
            lghtChnl = repmat(lghtChnl,[1,1,size(scanChnl,3)]);

            % Finally, we loop through and turn off laser on the even cycles when it's a single position
            % TODO -- I'm sure this can be vectorised
            edgesToZero = edgeSamples(2:2:end);
            distanceBetweenEdges = median(diff(edgeSamples));
            for ii=1:size(lghtChnl,3)
                if size(calibratedPointsInVolts{ii},1) >1
                    continue
                end

                for kk=1:length(edgesToZero)
                    s = edgesToZero(kk);
                    e = s+distanceBetweenEdges;
                    if e > size(lghtChnl,1)
                        e = size(lghtChnl,1);
                    end 
                    lghtChnl(s:e,1,ii) = 0;
                end
            end


            %% save all samples in a structure to access as object property
            chanSamples.scan = scanChnl;
            % x-by-2-by-nConditions, where rows are samples, columns are channels, and 3rd dim
            % is which area is selected

            chanSamples.light = lghtChnl;
            % x-by-3-by-nConditions, where rows are samples, columns are channels, and 3rd dim
            % is which area is selected

        end % get.chanSamples

    end % methods

    methods(Hidden)
        function [areaName,areaIndex] = getAreaNameFromCoords(obj,ML,AP)
            % Return brain area name from stereotaxic ML/AP coordinates
            %
            % zapit.stimConfig.getAreaNameFromCoords
            %
            % Purpose
            % Get the name of a brain area associated with ML/AP coords.
            %
            % Inputs
            % ML - mediolateral stereotaxic coord in mm
            % AP - anterioposterio stereotaxic coord in mm
            %
            % If the above are vectors of the same length, the function
            % will loop through and return a cell array of names associated
            % with all coords.
            %
            % Outputs
            % areaName - names of brain areas that are related to the coords. If one
            %           set of coords only then this is a string. If multiple, it's a cell
            %           array.
            % areaIndex - index values of area or areas. Scalar or vector accordingly

            if length(ML) ~= length(AP)
                areaIndex = [];
                areaName = [];
                return
            end

            brain_areas = obj.atlasData.dorsal_brain_areas;
            [~,indX] = arrayfun(@(x) min(abs(obj.atlasData.top_down_annotation.xData-x)), ML);
            [~,indY] = arrayfun(@(x) min(abs(obj.atlasData.top_down_annotation.yData-x)), AP);
            t_ind = arrayfun(@(x,y) obj.atlasData.top_down_annotation.data(x,y), indY, indX);
            areaIndex = arrayfun(@(x) find([brain_areas.area_index]==x), t_ind);
            areaName = arrayfun(@(x) brain_areas(x).names{1}, areaIndex, 'UniformOutput', false);

            if length(areaName)==1
                areaName = areaName{1};
            end

        end % getAreaNameFromCoords


    end % hidden methods


end % config
