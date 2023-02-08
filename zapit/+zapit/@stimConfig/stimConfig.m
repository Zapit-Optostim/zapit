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

    end

    % Getters and setters
    methods

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

            % TODO -- we need to make sure that the number of samples per second here is the right number
            obj.numSamplesPerChannel = obj.parent.DAQ.samplesPerSecond/obj.stimFreqInHz;

            % make up samples for scanner channels (of course calibratedPointsInVolts is already in volt format)
            % pre-allocate the waveforms array: 1st dim is samples, 2nd dim is channel, 3rd dim is conditions
            waveforms = zeros(obj.numSamplesPerChannel,4,length(calibratedPointsInVolts)); % matrix for each channel

            
            % Calculate some constants that we will need in multiple places further below.

            % find edges of half cycles (the indexes at which the beam moves or laser changes state)
            pointsPerTrial = obj.parent.settings.experiment.maxStimPointsPerCondition;
            obj.edgeSamples = ceil(linspace(1, obj.numSamplesPerChannel, pointsPerTrial+1));
            sampleInterval = 1/obj.parent.DAQ.samplesPerSecond; 

            % The blanking time is the period during which the beam is off and the scanners slowly
            % transition from one place to the next. Defined in ms.
            % a setting.
            blankingTime_ms = obj.parent.settings.experiment.blankingTime_ms;

            % The number of samples that correspond to the blanking time.
            blankingSamples = round( (blankingTime_ms*1E-3)/sampleInterval );


            % Fill in the matrices for the galvos
            for ii = 1:length(calibratedPointsInVolts) % Loop over stim conditions

                % If this position is a single point we duplicate it to spoof two points
                if size(calibratedPointsInVolts{ii},1) == 1
                    t_volts = repmat(calibratedPointsInVolts{ii},pointsPerTrial,1);
                else
                    t_volts = calibratedPointsInVolts{ii};
                end

                % The array t_volts is 2 by 2 with the first column being is ML coords (x mirror)
                % and second column being AP (y mirror). The rows indicate positions in this trial.
                % This is why for the single trial case we are repeating the row. Longer term we
                % may need a different system here, if we opt for multiple points.

                % Explicitly extract X and Y scanner voltages from t_volts.
                % These are column vectors. The first column is the first location and the
                % second column is the second location.
                xVolts = t_volts(:,1)';
                yVolts = t_volts(:,2)';


                % Make the full waveforms for X and Y. The logic here is that one cycle of the
                % waveform plays out over numSamplesPerChannel samples. So we want the beam to be
                % in each of the positions for half the time. We will define this using the number
                % points per trial to make this a bit more explicit and perhaps more fure proof
                Y = repmat(yVolts, obj.numSamplesPerChannel/pointsPerTrial, 1);
                X = repmat(xVolts, obj.numSamplesPerChannel/pointsPerTrial, 1);


                % The beam will now go to the correct locations but the scanners will generate a lot
                % of noise because the waveforms have no shaping. We will therefore swing the
                % scanners slowly from one position to the next over a period of 1 ms.

                % This does the ramp at the start of the waveform: it modifies the first column
                X(1:blankingSamples,1) = linspace(xVolts(2),xVolts(1),blankingSamples);
                Y(1:blankingSamples,1) = linspace(yVolts(2),yVolts(1),blankingSamples);

                % This does the ramp at the middle of the waveform: it modifies the second column
                X(1:blankingSamples,2) = linspace(xVolts(1),xVolts(2),blankingSamples);
                Y(1:blankingSamples,2) = linspace(yVolts(1),yVolts(2),blankingSamples);

                % Turn the two columns into a row vector and add it into the waveforms array.
                % Here the first column is the X scan waveform and the second is the Y waveform.
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
            end % for ii


            % Handling masking for periods beam is moving and one vs two locations
            MASK = ones(obj.numSamplesPerChannel,1);

            for ii=1:blankingSamples
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

    end % methods (getters and setters)


end % config
