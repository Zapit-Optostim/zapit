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
        atlasData    % The atlas data from the loaded .mat file. Shows top-down ARA view in stereotaxic coords
        edgeSamples  % Samples at which galvoes start to move. (see get.chanSamples) Here for plotChanSamples
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

            numHalfCycles = 2; % The number of half cycles to buffer

            % TODO -- we need to make sure that the number of samples per second here is the right number
            obj.numSamplesPerChannel = obj.parent.DAQ.samplesPerSecond/obj.stimFreqInHz*(numHalfCycles/2);

            % make up samples for scanner channels (of course calibratedPointsInVolts is already in volt format)
            % In scanChnl, 1st dim is samples, 2nd dim is channel, 3rd dim is conditions
            scanChnl = zeros(obj.numSamplesPerChannel,2,length(calibratedPointsInVolts)); % matrix for each channel

            
            % Calculate some constants that we will need in multiple places below            
            % find edges of half cycles (the indexes at which the beam moves or laser changes state)
            obj.edgeSamples = ceil(linspace(1, obj.numSamplesPerChannel, numHalfCycles+1));
            sampleInterval = 1/obj.parent.DAQ.samplesPerSecond; 
            nSamplesInOneMS = 1E-3 / sampleInterval;  % Number of samples in 1 ms. % TODO -- probably should have this as a setting


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
                xVolts = repmat(xVolts', 1, numHalfCycles/2); % TODO: Not needed if we definitely stick with 1 cycle

                yVolts = t_volts(:,2);
                yVolts = repmat(yVolts', 1, numHalfCycles/2); % TODO: Not needed if we definitely stick with 1 cycle

                % Make the full waveforms for X and Y
                Y = repmat(yVolts,obj.numSamplesPerChannel/numHalfCycles,1);
                X = repmat(xVolts,obj.numSamplesPerChannel/numHalfCycles,1);

                % apply the optional ramp to slow down the scanners and make the quieter.
                if true 
                    X(1:nSamplesInOneMS,1) = linspace(xVolts(1,2),xVolts(1,1),nSamplesInOneMS);
                    Y(1:nSamplesInOneMS,1) = linspace(yVolts(1,2),yVolts(1,1),nSamplesInOneMS);

                    X(1:nSamplesInOneMS,2) = linspace(xVolts(1,1),xVolts(1,2),nSamplesInOneMS);
                    Y(1:nSamplesInOneMS,2) = linspace(yVolts(1,1),yVolts(1,2),nSamplesInOneMS);
                end
                scanChnl(:,1,inactSite) = X(:);
                scanChnl(:,2,inactSite) = Y(:);

            end
            


            % fill in the matrices for the laser. Generally these will be the same for all 
            % conditions, but situations with one position will be different so we have to 
            % make them all (see repmat later)


            laserControlVoltage = obj.parent.laser_mW_to_control(obj.laserPowerInMW);

            %% make up samples for laser and masking light channels
            anlgOut = ones(1,obj.numSamplesPerChannel) * laserControlVoltage; %Write the correct control voltage
            digOut = ones(1,obj.numSamplesPerChannel) * 5; % 5V TTL

            % allow 1 ms around halfcycle change to be 0 (in case scanners are not in the right spot
            MASK = ones(1,obj.numSamplesPerChannel);

            for ii=1:nSamplesInOneMS
                MASK(obj.edgeSamples(1:end-1)+(ii-1))=0;
            end

            % Apply the mask
            lghtChnl(:,1) = anlgOut.*MASK;  % analog laser output
            lghtChnl(:,2) = digOut.*MASK;   % digital out for masking light

            % Expand out to match scanners
            lghtChnl = repmat(lghtChnl,[1,1,size(scanChnl,3)]);


            % Finally, we loop through and turn off laser on the even cycles when it's a single position
            % TODO -- I'm sure this can be vectorised
            edgesToZero = obj.edgeSamples(2:2:end);
            distanceBetweenEdges = median(diff(obj.edgeSamples));
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
