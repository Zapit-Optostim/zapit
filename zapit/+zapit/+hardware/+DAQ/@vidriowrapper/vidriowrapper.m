classdef vidriowrapper < zapit.hardware.DAQ
    % Zapit NI DAQ class using Vidrio's wrapper for NI DAQmx
    %
    % zapit.hardware.DAQ.vidriowrapper
    %
    % This class wraps Vidrio's NI DAQmx wrapper, allowing zapit.pointer to easily 
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
    % Rob Campbell - SWC 2022


    methods

        function obj = vidriowrapper(varargin)
            % Constructor
            %
            % function zapit.DAQ.vidriowrapper.vidriowrapper
            %
            % Purpose
            % The main purpose of the constructor is to set up default parameters.
            %
            obj = obj@zapit.hardware.DAQ(varargin{:});

        end % Constructor

        % TODO -- can the destructor go to the superclass?
        function delete(obj)
            % Destructor
            %
            % function zapit.DAQ.vidriowrapper.delete
            %

            delete(obj.hAI)
            delete(obj.hAO)
        end % delete


        % TODO -- these stop and start methods are not obviously related to the AO task by their name
        function start(obj)
            % Start the AO task
            %
            % function zapit.DAQ.vidriowrapper.start
            % 
            % Purpose
            % Start the AO task

            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.doingClockedAcquisition = true;
            obj.hAO.start
        end % start


        function stop(obj)
            % Stop the AO task
            %
            % function zapit.DAQ.vidriowrapper.stop
            % 
            % Purpose
            % Stop the AO task

            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.hAO.stop
        end % stop


        function stopAndDeleteAOTask(obj)
            % Stop and then delete the AO task
            %
            % function zapit.DAQ.vidriowrapper.stopAndDeleteAOTask
            %
            % Purpose
            % Stop the task and then delete it, which will run DAQmxClearTask

            obj.stop
            obj.doingClockedAcquisition = false;
            delete(obj.hAO);
        end % stopAndDeleteAOTask


        function stopAndDeleteAITask(obj)
            % 
            % function zapit.DAQ.vidriowrapper.stopAndDeleteAITask
            %
            % Purpose
            % Stops the AI task and then deletes it. 

            if isempty(obj.hAI) || ~isvalid(obj.hAI)
                return
            end
            obj.hAI.stop;    % Calls DAQmxStopTask
            delete(obj.hAI);
        end % stopAndDeleteAITask


        function connectUnclockedAI(obj, chan, verbose)
            % connectUnclockedAO(obj)
            %
            % Create a task that is unclocked AI and can be used for misc tasks.
            %
            % function zapit.DAQ.vidriowrapper.connectUnclockedAI
            %
            % Inputs
            % chan - which channel to connect. Must be supplied as an integer.
            % verbose - [optional, false by default]. Reports to screen what it is doing if true

            if nargin<3
                verbose = false;
            end

            obj.stopAndDeleteAITask

            obj.hAI = zapit.hardware.vidrio_daqmx.Task('unclockedai');

            if verbose
                fprintf('Creating unclocked AI task on %s\n', obj.device_ID)
            end
            obj.hAI.createAIVoltageChan(obj.device_ID, ...
                                        chan, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
        end % connectUnclockedAI

        function connectUnclockedAO(obj, verbose)
            % connectUnclockedAO(obj)
            %
            % function zapit.DAQ.vidriowrapper.connectUnclockedAO
            %
            % Create a task that is unclocked AO and can be used for sample setup.
            % The connection options are set by proprties in the vidriowrapper
            % class. see: .device_ID, .AOchans, .AOrange, 
            %
            % Inputs
            % verbose - [optional, false by default]. Reports to screen what it is doing if true

            if nargin<2
                verbose = false;
            end

            % If we are already connected we don't proceed
            if ~isempty(obj.hAO) && isvalid(obj.hAO) && strcmp(obj.hAO.taskName, 'unclockedao')
                return
            end

            obj.stopAndDeleteAOTask

            obj.hAO = zapit.hardware.vidrio_daqmx.Task('unclockedao');

            if verbose
                fprintf('Creating unclocked AO task on %s\n', obj.device_ID)
            end
            obj.hAO.createAOVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
        end % connectUnclockedAO


        function connectClockedAO(obj, varargin)
            % Set up a clocked AO task
            %
            % function zapit.DAQ.vidriowrapper.connectClockedAO
            %
            % Purpose
            % Create a task that is clocked AO and can be used for sample setup.
            % The connection options are set by proprties in the vidriowrapper
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


            obj.stopAndDeleteAOTask

            if verbose
                fprintf('Creating clocked AO task on %s\n', obj.device_ID)
            end
            
            obj.hAO = zapit.hardware.vidrio_daqmx.Task(taskName);
            
            % Set output channels
            obj.hAO.createAOVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
            
            
            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hAO.cfgSampClkTiming(samplesPerSecond, 'DAQmx_Val_ContSamps', numSamplesPerChannel, 'OnboardClock');
            obj.hAO.cfgOutputBuffer(numSamplesPerChannel);
            
            % allow sample regeneration
            obj.hAO.set('writeRegenMode', 'DAQmx_Val_AllowRegen');
            obj.hAO.set('writeRelativeTo','DAQmx_Val_FirstSample');
            
            % Configure the trigger
            if hardwareTriggered
                obj.hAO.cfgDigEdgeStartTrig(obj.settings.NI.triggerChannel, 'DAQmx_Val_Rising');
            end

        end % connectClockedAO


        function writeAnalogData(obj,waveforms)
            % Write analog data to the buffer
            %
            % function zapit.DAQ.vidriowrapper.writeAnalogData
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
            obj.hAO.writeAnalogData(waveforms);
        end % writeAnalogData


        function nSamples = numSamplesInBuffer(obj)
            % Return the number of samples in the buffer
            %
            % function zapit.DAQ.vidriowrapper.numSamplesInBuffer
            %
            % Purpose
            % Return the number of samples in the buffer

            if isempty(obj.hAO)
                nSamples = 0;
            else
                nSamples = obj.hAO.sampQuantSampPerChan;
            end
        end % numSamplesInBuffer




    end % methods

end % classdef
