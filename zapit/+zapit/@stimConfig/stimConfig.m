classdef stimConfig < handle

    % Configuration file handling class
    %
    % zapit.stimConfig
    %
    % Purpose
    % This class handles configuration files used to determine where the laser stim
    % locations are. Methods in this class generate the waveforms used for stimulus
    % presentation. This class loads stimulus config YML files and interprets them.
    %
    % Rob Campbell - SWC 2022

    properties

        configFileName % file name of the loaded stimConfig file

        laserPowerInMW
        stimModulationFreqHz
        stimLocations
        offRampDownDuration_ms

    end % properties

    properties (Hidden)
        parent  % the zapit.pointer to which this is attached
        numSamplesPerChannel % Number of samples per channel to send to the DAQ.
        atlasData    % The atlas data from the loaded .mat file. Shows top-down ARA view in stereotaxic coords
        logFileStem = 'zapit_log_' % The stem of the log file name. zapit.pointer will use this to search for the file
    end

    properties (Hidden, SetAccess=protected)
        dutyCycle = 0.5 % With one or two stimuli, the beam will always be on half the time.
                        % It is is with respect to this standard that we set laser powers for all other situations
    end

    % read-only properties that are associated with getters
    properties(SetAccess=protected, GetAccess=public)
        chanSamples % The waveforms to be sent to the scanners
        blankingTime_ms
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


        function blankingTime_ms = get.blankingTime_ms(obj)
            % Return blanking time in ms from the zapit settings
            %
            % zapit.stimConfig.blankingTime_ms
            %
            % Purpose
            % Return blanking time in ms from the Zapit settings file. If possible,
            % obtains this value from the attached zapit.pointer but if that's not
            % possible it reads the settings file and finds it from there. The blanking
            % time is the period during which the beam is off and the scanners slowly
            % transition from one place to the next. Defined in ms.

            if isempty(obj.parent)
                settings = zapit.settings.readSettings;
            else
                settings = obj.parent.settings;
            end
            blankingTime_ms = settings.experiment.blankingTime_ms;

        end % get.blankingTime_ms


        function chanSamples = get.chanSamples(obj)
            % Prepares voltages for each photostimulation site
            %
            % zapit.stimConfig.chanSamples
            %
            % Purpose
            % The calibratedPoints getter returns the locations of stimulus points in
            % sample space. The calibratedPointsInVolts converts this to volts. This
            % method uses these voltage values to generate waveforms that can be played
            % with a clocked NI output task in order stimulate the sample at the laser
            % power and rep rate defined by properties of this class.
            %
            % Inputs
            % none
            %
            % Outputs
            % chanSamples
            %
            % Original by Maja Skretowska - SWC 2021
            % Updated by Rob Campbell - SWC 2023 to cope with new stimulus structure

            % Pull in data from method

            if isempty(obj.parent)
                fprintf(['zapit.pointer not connected to zapit.stimConfig. ', ...
                    'Not making waveforms.\n'])
                chanSamples = [];
                return
            end

            % Cache so it does not get re-generated repeatedly
            calibratedPointsInVolts = obj.calibratedPointsInVolts;

            obj.numSamplesPerChannel = obj.parent.DAQ.samplesPerSecond/obj.stimModulationFreqHz;

            % Make up samples for scanner channels (of course calibratedPointsInVolts is
            % already in volt format) pre-allocate the waveforms array: 1st dim is samples,
            % 2nd dim is channel, 3rd dim is conditions.
            waveforms = zeros(obj.numSamplesPerChannel,4,length(calibratedPointsInVolts));

            % The number of samples that correspond to the blanking time. The blanking
            % time is the period during which the beam is off and the scanners slowly
            % transition from one place to the next. This is defined in ms and will be
            % constant within a trial regardless of how many positions are presented
            % within a trial.
            sampleInterval = 1/obj.parent.DAQ.samplesPerSecond;
            blankingSamples = round( (obj.blankingTime_ms*1E-3)/sampleInterval );


            % STEP ONE -- Fill in the matrices for the galvos
            for ii = 1:length(calibratedPointsInVolts) % Loop over stim conditions

                % If this position is a single point we duplicate it to spoof two points
                pointsPerTrial = length(calibratedPointsInVolts{ii});
                if size(calibratedPointsInVolts{ii},1) == 1
                    t_volts = repmat(calibratedPointsInVolts{ii},pointsPerTrial,1);
                else
                    t_volts = calibratedPointsInVolts{ii};
                end

                % The array t_volts is 2 by 2 with the first column being is ML coords
                % (x mirror) and second column being AP (y mirror). The rows indicate
                % positions in this trial. This is why for the single trial case we are
                % repeating the row. Longer term we may need a different system here, if
                % we opt for multiple points.

                % Explicitly extract X and Y scanner voltages from t_volts.
                % These are column vectors. The first column is the x scanner voltage
                % and the second is the y location.

                xVolts = t_volts(:,1)';
                yVolts = t_volts(:,2)';


                % TODO -- update following doc because we now have multiple points.
                % Make the full waveforms for X and Y. The logic here is that one cycle of
                % the waveform plays out over numSamplesPerChannel samples. So we want the
                % beam to be in each of the two positions for half the time. We will define
                % this using the number points per trial to make this a bit more explicit
                % and perhaps more future proof.
                Y = repmat(yVolts, ceil(obj.numSamplesPerChannel/pointsPerTrial), 1);
                X = repmat(xVolts, ceil(obj.numSamplesPerChannel/pointsPerTrial), 1);


                % The beam will now go to the correct locations but the scanners will
                % generate a lot of noise because the waveforms have no shaping. We will
                % therefore swing the scanners slowly from one position to the next over
                % a period of roughly 1 ms (exact number is in settings file).

                % This does the ramp at the start of the waveform transitions (even)
                oldway = false; % WHEN TRUE. WE MAKE WAVEFORMS THE OLD WAY

                % The following does not produce results identical to the above, but
                % it's very close. Within a sample.
                kernel = ones(blankingSamples,1)/blankingSamples;
                X = X(:);
                Xsmooth = conv(circshift(X,blankingSamples*2),kernel,'valid');
                Xsmooth(end:end+blankingSamples-1) = Xsmooth(end);
                Xsmooth = circshift(Xsmooth,blankingSamples*-1);
                % Note that the following line (also for Y) will truncate the waveform
                % slightly. This happens when the number of stimulus locations does not
                % produce a whole number when divided by the number of stimuli in the
                % buffer. See lines ~208 and 209 where X and Y are defined. This is
                % not an easy thing to fix. If we lose a sample or two here and there
                % from one stimulus it shouldn't matter or be noticeable.
                waveforms(:,1,ii) = Xsmooth(1:size(waveforms,1));
                Y = Y(:);
                Ysmooth = conv(circshift(Y,blankingSamples*2),kernel,'valid');
                Ysmooth(end:end+blankingSamples-1) = Ysmooth(end);
                Ysmooth = circshift(Ysmooth,blankingSamples*-1);
                waveforms(:,2,ii) = Ysmooth(1:size(waveforms,1));

            end % for ii


            %%
            % Handling masking for periods beam is moving and one vs two locations



            % These two lines define variables that allow us to tweak the onset and offset
            % of the beam blanking to take into account latency of the scanners.
            % See zapit.settings.default_settings for a description of what these lines do
            blankOnsetShift_ms = obj.parent.settings.experiment.blankOnsetShift_ms;
            blankOffsetShift_ms = obj.parent.settings.experiment.blankOffsetShift_ms;

            % The following two lines convert ms to samples.
            blankOnsetShift_samples = round((blankOnsetShift_ms*1E-3)/sampleInterval);
            blankOffsetShift_samples = round((blankOffsetShift_ms*1E-3)/sampleInterval);


            % STEP TWO -- Fill in the matrices for the laser power signal
            waveforms(:,3,:) = 1; % We will fill in with laser power control voltage in sendSamples
            waveforms(:,4,:) = 5; % 5v TTL
            for ii = 1:length(calibratedPointsInVolts) % Loop over stim conditions

                pointsPerTrial = length(calibratedPointsInVolts{ii});
                edgeSamples = ceil(linspace(1, obj.numSamplesPerChannel, pointsPerTrial+1));

                blankingMask = ones(obj.numSamplesPerChannel,1);
                for kk=1:(blankingSamples+blankOnsetShift_samples+blankOffsetShift_samples)
                    blankingMask(edgeSamples(1:end-1)+(kk-1))=0;
                end

                waveforms(:,3:4,ii) = waveforms(:,3:4,ii) .* blankingMask;

                % If this has one stim condition we must turn off the beam
                if size(calibratedPointsInVolts{ii},1) == 1
                    edgesToZero = edgeSamples(2:2:end)+1;
                    distanceBetweenEdges = median(diff(edgeSamples));

                    for kk=1:length(edgesToZero)
                        s = edgesToZero(kk);
                        e = s+distanceBetweenEdges;
                        if e > obj.numSamplesPerChannel
                            e = obj.numSamplesPerChannel;
                        end
                        waveforms(s:e,3,ii) = 0; % The laser AO line
                    end
                end

            end



            %%
            % Handle case where we want an ephys waveform
            for ii=1:length(obj.stimLocations)

                if ~isfield(obj.stimLocations(ii).Attributes,'ephysWaveform') || ...
                    obj.stimLocations(ii).Attributes.ephysWaveform == false
                    continue
                end
                waveforms(:,3,ii) = obj.filterForEphys(waveforms(:,3,ii));
            end


            % Now we circularly shift the waveforms to deal with the wrapping issue.
            % TODO: What is the reason for doing this?
            waveforms(:,3:4,:) = circshift(waveforms(:,3:4,:),-blankOnsetShift_samples,1);

            if size(waveforms,1) ~= obj.numSamplesPerChannel
                fprintf('Expected waveform size: %d but actual is %d. BAD! REPORT THIS ERROR!', ...
                    obj.numSamplesPerChannel, size(waveforms,1))
            end
            % Output
            chanSamples = waveforms;

        end % get.chanSamples

    end % methods (getters and setters)


end % config
