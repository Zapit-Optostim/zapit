classdef stimConfig < handle

    % class for handling the configuration files used to
    % determine where the laser stim locations are
    %
    % Rob Campbell - SWC 2022

    properties

        configFileName % file name of the loaded stimConfig file


        laserPowerInMW
        stimFreqInHz
        stimLocations
        % powerOption -  if 1 send 2 mW, if 2 send 4 mW (mean)
        powerOption = 1 % TODO leave for now but delete as soon as possible

    end % properties

    properties (Hidden)
        parent  % the zapit.pointer to which this is attached
        numSamplesPerChannel
    end

    % read-only properties that are associated with getters
    properties(SetAccess=protected, GetAccess=public)
        chanSamples % The waveforms to be sent to the scanners
    end


    methods

        function obj = stimConfig(fname)
            % Construct a stimConfig file object and load data
            obj.loadConfig(fname)
        end % Constructor


        function delete(obj)
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

            for ii = 1:length(obj.stimLocations)
                fieldName = sprintf('stimLocations%02d',ii);
                data.(fieldName) = obj.stimLocations(ii);
            end

            data.laserPowerInMW = obj.laserPowerInMW;
            data.stimFreqInHz = obj.stimFreqInHz;

            zapit.yaml.WriteYaml(fname,data);
        end % writeConfig


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
            %
            cPoints = {};

            if isempty(obj.parent.refPointsSample)
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

            numHalfCycles = 4; % The number of half cycles to buffer

            % TODO -- we need to make sure that the number of samples per second here is the right number
            obj.numSamplesPerChannel = obj.parent.DAQ.samplesPerSecond/obj.stimFreqInHz*(numHalfCycles/2);

            % find edges of half cycles
            cycleEdges = linspace(1, obj.numSamplesPerChannel, numHalfCycles+1);
            edgeSamples = ceil(cycleEdges(1,:));

            % make up samples for scanner channels (of course calibratedPointsInVolts is already in volt format)
            scanChnl = zeros(obj.numSamplesPerChannel,2,length(calibratedPointsInVolts)); % matrix for each channel
            lghtChnl = zeros(obj.numSamplesPerChannel,2,2); % 1st dim is samples, 2nd dim is channel, 3rd dim is conditions

            %% make up scanner volts to switch between two areas
            for inactSite = 1:length(calibratedPointsInVolts)

                % inactSite gets column from the coordinates library
                xVolts = calibratedPointsInVolts{inactSite}(:,1);
                yVolts = calibratedPointsInVolts{inactSite}(:,2);
                for cycleNum = 1:(length(edgeSamples)-1)
                    segStart = edgeSamples(cycleNum);
                    segStop = edgeSamples(cycleNum+1);
                    siteIndx = rem(cycleNum+1,2)+1; % check whether it's an odd (rem = 1) or even (rem = 0) number and then add 1 to get an index
                    scanChnl(segStart:segStop,1,inactSite) = xVolts(siteIndx);
                    scanChnl(segStart:segStop,2,inactSite) = yVolts(siteIndx);
                end

            end

            %% make up samples for laser and masking light channels
            anlgOut = ones(1,obj.numSamplesPerChannel) * obj.parent.laser_mW_to_control(obj.laserPowerInMW); %Write the correct control voltage
            digitalAmplitude = 4;
            digOut = ones(1,obj.numSamplesPerChannel) * digitalAmplitude;

            % allow 1 ms around halfcycle change to be 0 (in case scanners are not in the right spot
            % TODO -- this should be based on empirical values
            MASK = ones(1,obj.numSamplesPerChannel);
            sampleInterval = 1/obj.parent.DAQ.samplesPerSecond;
            nSamplesInOneMS = 1E-3 / sampleInterval;

            for ii=1:nSamplesInOneMS
                MASK(edgeSamples(1:end-1)+(ii-1))=0;
            end

            anlgOut = anlgOut.*MASK;
            digOut = digOut.*MASK;

            lghtChnl(:,1) = anlgOut;              % analog laser output
            lghtChnl(:,2) = digOut*(5/digitalAmplitude);    % analog masking light output
            lghtChnl(:,3) = digOut;               % digital laser gate


            %% save all samples in a structure to access as object property
            chanSamples.scan = scanChnl;
            % x-by-2-by-6, where rows are samples, columns are channels, and 3rd dim
            % is which area is selected

            chanSamples.light = lghtChnl;
            % x-by-3-by-2, where rows are samples, columns are channels, and 3rd dim
            % is whether laser is off or on


        end % get.chanSamples

    end % methods


end % config
