classdef dotNETwrapper < zapit.hardware.DAQ
    % Zapit NI DAQ class using the .NET wrapper for NI DAQmx
    %
    % zapit.hardware.DAQ.dotNETwrapper
    %
    % This class wraps the .NET NI DAQmx wrapper, allowing zapit.pointer to easily
    % set up clocked and unclocked AO scenarios as well as unclocked AI. No clocked
    % AI is needed for Zapit.
    %
    %
    % Instantiating:
    % The properties used for connecting with the DAQ are obtained in this order:
    % 1. From param/value argument pairs on construction.
    % 2. From the settings YAML file.
    % 3. From the hard-coded properties in this object
    %
    % You can mix and match. e.g. if you supply the device name as a param/value
    % pair but nothing else, then the rest of the settings are obtained from
    % settings YAML (assuming it exists).
    %
    %
    % * Note on AO lines:
    % The assumption is that the AO lines drive the following hardware:
    % 0 - Galvo X
    % 1 - Galvo Y
    % 2 - Laser control voltage signal
    % 3 - Masking LED
    %
    %
    % Rob Campbell - SWC 2023

    properties
        hAOtaskWriter % Class for writing data to AO lines
        hAIreader % Class for reading from AI lines
    end



    methods

        function obj = dotNETwrapper(varargin)
            % Constructor
            %
            % function zapit.DAQ.dotNETwrapper.dotNETwrapper
            %
            % Purpose
            % The main purpose of the constructor is to set up default parameters.
            %

            nidaqmx.add_DAQmx_Assembly
            import NationalInstruments.DAQmx.*

            obj = obj@zapit.hardware.DAQ(varargin{:});
            fprintf('Connecting to NI hardware via .NET DAQmx.\n')
        end % Constructor


        % TODO -- can the destructor go to the superclass?
        function delete(obj)
            % Destructor
            %
            % function zapit.DAQ.dotNETwrapper.delete
            %

            if isa(obj.hAO, 'NationalInstruments.DAQmx.Task')
                obj.hAO.Dispose
            end
            if isa(obj.hAI, 'NationalInstruments.DAQmx.Task')
                obj.hAI.Dispose
            end
            delete(obj.hAI)
            delete(obj.hAO)
            delete(obj.hAOtaskWriter)
        end % delete


        % TODO -- these stop and start methods are not obviously related to the AO task by their name
        function start(obj)
            % Start the AO task
            %
            % function zapit.DAQ.dotNETwrapper.start
            %
            % Purpose
            % Start the AO task

            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.doingClockedAcquisition = true;
            obj.hAO.Start
        end % start


        function stop(obj)
            % Stop the AO task
            %
            % function zapit.DAQ.dotNETwrapper.stop
            %
            % Purpose
            % Stop the AO task

            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.hAO.Stop
        end % stop



        function isDone = isAOTaskDone(obj)
            % Return true if the AO task is done
            %
            % function zapit.DAQ.dotNETwrapper.isAOTaskDone
            isDone = obj.hAO.IsDone;
        end % isAOTaskDone


        function stopAndDeleteAOTask(obj)
            % Stop and then delete the AO task
            %
            % function zapit.DAQ.dotNETwrapper.stopAndDeleteAOTask
            %
            % Purpose
            % Stop the task and then delete it, which will run DAQmxClearTask

            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end

            obj.stop
            obj.doingClockedAcquisition = false;
            obj.hAO.Dispose;
            delete(obj.hAO);
        end % stopAndDeleteAOTask


        function stopAndDeleteAITask(obj)
            %
            % function zapit.DAQ.dotNETwrapper.stopAndDeleteAITask
            %
            % Purpose
            % Stops the AI task and then deletes it.

            if isempty(obj.hAI) || ~isvalid(obj.hAI)
                return
            end
            obj.hAI.Stop;    % Calls DAQmxStopTask
            obj.hAI.Dispose;
            delete(obj.hAI);
        end % stopAndDeleteAITask


        function connectUnclockedAI(obj, chan, verbose)
            % connectUnclockedAO(obj)
            %
            % Create a task that is unclocked AI and can be used for misc tasks.
            %
            % function zapit.DAQ.dotNETwrapper.connectUnclockedAI
            %
            % Inputs
            % chan - which channel to connect. Must be supplied as an integer.
            % verbose - [optional, false by default]. Reports to screen what it is doing if true

            import NationalInstruments.DAQmx.*

            if nargin<3
                verbose = false;
            end

            obj.stopAndDeleteAITask


            if verbose
                fprintf('Creating unclocked AI task on %s\n', obj.device_ID)
            end

            taskName = 'unclockedai';
            obj.hAI = NationalInstruments.DAQmx.Task(taskName);
            chan = [obj.device_ID,'/ai',num2str(chan)];

            obj.hAI.AIChannels.CreateVoltageChannel(chan, taskName, ...
                            AITerminalConfiguration.Differential, ...
                            -obj.AOrange, obj.AOrange, AIVoltageUnits.Volts);

            obj.hAI.Control(TaskAction.Verify)

            obj.hAIreader = AnalogSingleChannelReader(obj.hAI.Stream);



        end % connectUnclockedAI

        function connectUnclockedAO(obj, verbose)
            % connectUnclockedAO(obj)
            %
            % function zapit.DAQ.dotNETwrapper.connectUnclockedAO
            %
            % Create a task that is unclocked AO and can be used for sample setup.
            % The connection options are set by properties in the dotNETwrapper
            % class. see: .device_ID, .AOchans, .AOrange,
            %
            % Inputs
            % verbose - [optional, false by default]. Reports to screen what it is doing if true

            import NationalInstruments.DAQmx.*

            if nargin<2
                verbose = false;
            end

            % If we are already connected we don't proceed
            if ~isempty(obj.hAO) && isvalid(obj.hAO) && obj.hAO.AOChannels.Count>0 && ...
                    startsWith(char(obj.hAO.AOChannels.All.VirtualName), 'unclockedao') %TODO: not the task name!
                return
            end

            obj.stopAndDeleteAOTask

            if verbose
                fprintf('Creating unclocked AO task on %s\n', obj.device_ID)
            end

            taskName = 'unclockedao';
            obj.hAO = NationalInstruments.DAQmx.Task(taskName);
            channelName = obj.genChanString(obj.AOchans);

            obj.hAO.AOChannels.CreateVoltageChannel(channelName, taskName, ...
                            -obj.AOrange, obj.AOrange, AOVoltageUnits.Volts);

            obj.hAO.Control(TaskAction.Verify);

            obj.hAOtaskWriter = AnalogMultiChannelWriter(obj.hAO.Stream);

        end % connectUnclockedAO


        function connectClockedAO(obj, varargin)
            % Set up a clocked AO task
            %
            % function zapit.DAQ.dotNETwrapper.connectClockedAO
            %
            % Purpose
            % Create a task that is clocked AO and can be used for sample setup.
            % The connection options are set by proprties in the dotNETwrapper
            % class. see: .device_ID, .AOchans, .AOrange, .samplesPerSecond
            %
            % Inputs (optional)
            % numSamplesPerChannel - Size of the buffer
            % samplesPerSecond - determines output rate and default comes from YAML file. Likely
            %                   this will be about 1E6.
            % taskName - 'clockedao' by default
            % verbose - false by default
            % hardwareTriggered - false by default. If true, task waits for trigger (PFI0 by default
            %            and this line can be changed in the settings YAML)
            %
            % The task writes to the default number of AO lines (likely all four).

            import NationalInstruments.DAQmx.*
            %Parse optional arguments
            params = inputParser;
            params.CaseSensitive = false;

            params.addParameter('numSamplesPerChannel', 1000, @(x) isnumeric(x) && isscalar(x));
            params.addParameter('samplesPerSecond', obj.samplesPerSecond, @(x) isnumeric(x) && isscalar(x));
            params.addParameter('taskName', 'clockedAO', @(x) ischar(x));
            params.addParameter('verbose', false, @(x) islogical(x) || x==0 || x==1);
            params.addParameter('hardwareTriggered', false, @(x) islogical(x) || x==0 || x==1);

            params.parse(varargin{:});

            numSamplesPerChannel=params.Results.numSamplesPerChannel;
            samplesPerSecond=params.Results.samplesPerSecond;
            taskName=params.Results.taskName;
            verbose=params.Results.verbose;
            hardwareTriggered=params.Results.hardwareTriggered;

            % If we are already connected we don't proceed
            if ~isempty(obj.hAO) && isvalid(obj.hAO) && obj.hAO.AOChannels.Count>0 && ...
                    startsWith(char(obj.hAO.AOChannels.All.VirtualName), taskName) %TODO: not the task name!
                return
            end

            obj.stopAndDeleteAOTask

            if verbose
                fprintf('Creating clocked AO task on %s\n', obj.device_ID)
            end

            obj.hAO = NationalInstruments.DAQmx.Task(taskName);

            % Set output channels
            channelName = obj.genChanString(obj.AOchans);

            obj.hAO.AOChannels.CreateVoltageChannel(channelName, taskName, ...
                            -obj.AOrange, obj.AOrange, AOVoltageUnits.Volts);

            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hAO.Timing.ConfigureSampleClock('', ...
                        samplesPerSecond, ...
                        SampleClockActiveEdge.Rising, ...
                        SampleQuantityMode.ContinuousSamples, ... % And we set this to continuous
                        numSamplesPerChannel);


            % allow sample regeneration
            obj.hAO.Stream.WriteRegenerationMode = WriteRegenerationMode.AllowRegeneration;

            obj.hAO.Control(TaskAction.Verify);

            obj.hAOtaskWriter = AnalogMultiChannelWriter(obj.hAO.Stream);
            % Configure the trigger
            if hardwareTriggered
                if verbose
                    fprintf('Configuring a hardware trigger on line %s\n', ...
                        obj.settings.NI.triggerChannel)
                end
                obj.hAO.Triggers.StartTrigger.ConfigureDigitalEdgeTrigger(...
                            obj.settings.NI.triggerChannel, ...
                            DigitalEdgeStartTriggerEdge.Rising);
            end

        end % connectClockedAO


        function writeAnalogData(obj,waveforms)
            % Write analog data to the buffer
            %
            % function zapit.DAQ.dotNETwrapper.writeAnalogData
            %
            % Purpose
            % Write analod data to the buffer and also log in a property the
            % data that were written.

            % The Vidrio DAQmx wrapper reports values out of range even
            % when these do not exist. This happend during the rampdown.
            % The following line is just an additional chack.
            if any(abs(max(waveforms,[],1))>10)
                fprintf(' ** There are waveform data that exceed the +/- 10V range **\n')
            end

            % If this is a long waveform we cache it
            if size(waveforms,1)>1
                obj.lastWaveform = waveforms;
            end

            % We want to auto-start only the on-demand tasks because zapit.pointer has methods
            % that calls DAQmx start for the clocked operations.
            verbose = false; % For debugging
            if strcmp(char(obj.hAO.Timing.SampleTimingType),'OnDemand')
                if verbose
                    fprintf('Writing to buffer: on-demand\n')
                end
                obj.hAOtaskWriter.WriteMultiSample(true,waveforms');
            else
                if verbose
                    fprintf('Writing to buffer: clocked\n')
                end
                obj.hAOtaskWriter.WriteMultiSample(false,waveforms');
            end
        end % writeAnalogData


        function data = readAnalogData(obj)
            % Read analog data from the DAQ
            %
            % function zapit.DAQ.vidriowrapper.readAnalogData
            %
            % Purpose
            % Thin wrapper to read analog data.
            data = obj.hAIreader.ReadSingleSample;
        end % readAnalogData


        function nSamples = numSamplesInBuffer(obj)
            % Return the number of samples in the buffer
            %
            % function zapit.DAQ.dotNETwrapper.numSamplesInBuffer
            %
            % Purpose
            % Return the number of samples in the buffer

            if isempty(obj.hAO)
                nSamples = 0;
            else
                %TODO - This is indirect. I can not as yet find which property in the
                % class contains the buffer size. The approach here won't produce errors,
                % I don't think, so let's stay with this for now.
                nSamples = length(obj.lastWaveform);
            end
        end % numSamplesInBuffer


        function chanString = genChanString(obj,chans)
            % Generate a channel string for connecting to the DAQ
            %
            % function zapit.DAQ.dotNETwrapper.genChanString(chans)
            %
            % Purpose
            % Turns a vector, like [0,3], into a string that the wrapper will
            % accept as a channel name.
            %
            % Inputs
            % chans - scalar or vector of channels names.
            %
            % Outputs
            % chanString - a string that the .NET wrapper will accept. e.g. 'Dev1/ao1,Dev1/ao3'

            C = arrayfun(@(x) sprintf('%s/ao%d', obj.device_ID,x), chans, ...
                    'UniformOutput',false);

            if length(C) == 1
                chanString = C{1};
                return
            end

            C = strcat(C{:});
            C = strrep(C,'D',',D');
            C(1) = [];

            chanString = C;
        end % genChanString

    end % methods

end % classdef
