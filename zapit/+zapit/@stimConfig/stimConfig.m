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
        logFileStem = 'zapit_log_' % The stem of the log file name. zapit.pointer will use this to search for the file
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


        function n = numConditions(obj)
            % Return the number of stimulus conditions.
            %
            % zapit.stimConfig.numConditions
            %
            % Purpose
            % Return the number of stimulus conditions
            % 
            % Inputs
            % none
            % 
            % Outputs
            % n - scalar defining the number of conditions

            n = length(obj.stimLocations);

        end % numConditions


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

            for ii = 1:obj.numConditions
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

            % Pull in data from method
            calibratedPointsInVolts = obj.calibratedPointsInVolts;

            numHalfCycles = 2; % The number of half cycles to buffer

            % TODO -- we need to make sure that the number of samples per second here is the right number
            obj.numSamplesPerChannel = obj.parent.DAQ.samplesPerSecond/obj.stimFreqInHz*(numHalfCycles/2);

            % make up samples for scanner channels (of course calibratedPointsInVolts is already in volt format)
            % pre-allocate the waveforms array: 1st dim is samples, 2nd dim is channel, 3rd dim is conditions
            waveforms = zeros(obj.numSamplesPerChannel,4,length(calibratedPointsInVolts)); % matrix for each channel

            
            % Calculate some constants that we will need in multiple places below            
            % find edges of half cycles (the indexes at which the beam moves or laser changes state)
            obj.edgeSamples = ceil(linspace(1, obj.numSamplesPerChannel, numHalfCycles+1));
            sampleInterval = 1/obj.parent.DAQ.samplesPerSecond; 
            nSamplesInOneMS = 1E-3 / sampleInterval;  % Number of samples in 1 ms. % TODO -- probably should have this as a setting


            % Fill in the matrices for the galvos
            for ii = 1:length(calibratedPointsInVolts) % Loop over stim conditions

                % If this position is a single point we duplicate it to spoof two points
                if size(calibratedPointsInVolts{ii},1) == 1
                    t_volts = repmat(calibratedPointsInVolts{ii},2,1);
                else
                    t_volts = calibratedPointsInVolts{ii};
                end

                xVolts = t_volts(:,1);
                xVolts = repmat(xVolts', 1, numHalfCycles/2); % TODO: Not needed if we definitely stick with 1 cycle

                yVolts = t_volts(:,2);
                yVolts = repmat(yVolts', 1, numHalfCycles/2); % TODO: Not needed if we definitely stick with 1 cycle

                % Make the full waveforms for X and Y
                Y = repmat(yVolts,obj.numSamplesPerChannel/numHalfCycles,1);
                X = repmat(xVolts,obj.numSamplesPerChannel/numHalfCycles,1);

                % apply a ramp to slow down the scanners and make the quieter.
                X(1:nSamplesInOneMS,1) = linspace(xVolts(1,2),xVolts(1,1),nSamplesInOneMS);
                Y(1:nSamplesInOneMS,1) = linspace(yVolts(1,2),yVolts(1,1),nSamplesInOneMS);

                X(1:nSamplesInOneMS,2) = linspace(xVolts(1,1),xVolts(1,2),nSamplesInOneMS);
                Y(1:nSamplesInOneMS,2) = linspace(yVolts(1,1),yVolts(1,2),nSamplesInOneMS);

                waveforms(:,1,ii) = X(:);
                waveforms(:,2,ii) = Y(:);

                % Fill in the laser analog values based on laser power defined for this
                % trial specifically. The shapes of these waveforms will vary depending on
                % whether we have one or two positions in this trial. This will be dealt
                % with later.
                t_mW = obj.stimLocations(ii).Attributes.laserPowerInMW;
                laserControlVoltage = obj.parent.laser_mW_to_control(t_mW);
                waveforms(:,3,ii) = ones(1,obj.numSamplesPerChannel) * laserControlVoltage;

                % The masking light
                waveforms(:,4,ii) = ones(1,obj.numSamplesPerChannel) * 5; % 5V TTL
            end % for


            % Handling masking for periods beam is moving and one vs two locations
            MASK = ones(obj.numSamplesPerChannel,1);

            for ii=1:nSamplesInOneMS
                MASK(obj.edgeSamples(1:end-1)+(ii-1))=0;
            end

            % Apply the mask
            waveforms(:,3:4,:) = bsxfun(@times, waveforms(:,3:4,:), MASK);
            
            % Finally, we loop through and turn off laser on the even cycles when it's a single position
            % TODO -- I'm sure this can be vectorised
            edgesToZero = obj.edgeSamples(2:2:end);
            distanceBetweenEdges = median(diff(obj.edgeSamples));
            for ii=1:size(waveforms,3)
                if size(calibratedPointsInVolts{ii},1) >1
                    continue
                end

                for kk=1:length(edgesToZero)
                    s = edgesToZero(kk);
                    e = s+distanceBetweenEdges;
                    if e > size(waveforms,1)
                        e = size(waveforms,1);
                    end 
                    waveforms(s:e,3,ii) = 0; % The laser AO line
                end
            end


            % Output
            chanSamples = waveforms;

        end % get.chanSamples


    end % methods


end % config
