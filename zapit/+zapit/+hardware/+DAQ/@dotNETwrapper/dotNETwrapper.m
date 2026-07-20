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
        hAOtaskWriter  % Class for writing data to AO lines
        hDOtaskWriter  % Class for writing data to DO lines
        hAIreader      % Class for reading from AI lines
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

            NET.addAssembly('NationalInstruments.DAQmx');
            import NationalInstruments.DAQmx.*

            obj = obj@zapit.hardware.DAQ(varargin{:});
            fprintf('Connecting to NI hardware via .NET DAQmx.\n')
        end % Constructor


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
            if isa(obj.hDO, 'NationalInstruments.DAQmx.Task')
                obj.hDO.Dispose
            end
            delete(obj.hAI)
            delete(obj.hAO)
            delete(obj.hDO)
            delete(obj.hAOtaskWriter)
            delete(obj.hDOtaskWriter)
        end % delete


        function startStimulation(obj)
            % Start stimulation by starting the AO task
            %
            % function zapit.DAQ.dotNETwrapper.startStimulation
            %
            % Purpose
            % Starts the AO task. Is called by, for example, pointer.sendSamples



            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end

            if isempty(obj.hDO) || ~isvalid(obj.hDO)
                doDO = false;
            else
                doDO = true;
            end

            obj.doingClockedAcquisition = true;
            if doDO && obj.hDO.IsDone
                obj.hDO.Start
            end

            if obj.hAO.IsDone % Stops a start command being issued if it has already started                
                obj.hAO.Start
            end
        end % startStimulation


        function stopStimulation(obj)
            % Stop stimulation by stopping the AO and DO tasks
            %
            % function zapit.DAQ.dotNETwrapper.stopStimulation
            %
            % Purpose
            % Stops the AO task. Is called by, for example, pointer.sendSamples

            if ~isempty(obj.hAO) && isvalid(obj.hAO)
               obj.hAO.Stop
            end

            if ~isempty(obj.hDO) && isvalid(obj.hDO)
                obj.hDO.Stop
            end
        end % stopStimulation


        function waitUntilAOTaskDone(obj)
            % Wait until the AO task is done (Blocking)
            %
            % function zapit.DAQ.dotNETwrapper.waitUntilAOTaskDone
            obj.hAO.WaitUntilDone;
        end % waitUntilAOTaskDone


        function isDone = isAOTaskDone(obj)
            % Return true if the AO task is done
            %
            % function zapit.DAQ.dotNETwrapper.isAOTaskDone
            isDone = obj.hAO.IsDone;
        end % isAOTaskDone


        function isRunning = isFiniteSamplePlaying(obj)
            % Return true if we are playing a finite waveform
            %
            % zapit.DAQ.dotNETwrapper.isFiniteSamplePlaying
            if ~obj.hAO.IsDone && strcmp(obj.hAO.Timing.SampleQuantityMode,'FiniteSamples')
                isRunning = true;
            else
                isRunning = false;
            end
        end % isFiniteSamplePlaying


        function sampleQuantityMode = returnAOSampleQuantityMode(obj)
            % Return the sample quantity mode of the DAQ as a string
            %
            % function zapit.DAQ.dotNETwrapper.returnAOSampleQuantityMode
            sampleQuantityMode = obj.hAO.Timing.SampleQuantityMode;
        end % returnSampleQuantityMode


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

            obj.hAO.Stop
            obj.doingClockedAcquisition = false;
            obj.hAO.Dispose;
            delete(obj.hAO);
        end % stopAndDeleteAOTask


        function stopAndDeleteDOTask(obj)
            % Stop and then delete the DO task
            %
            % function zapit.DAQ.dotNETwrapper.stopAndDeleteDOTask
            %
            % Purpose
            % Stop the task and then delete it, which will run DAQmxClearTask

            if isempty(obj.hDO) || ~isvalid(obj.hDO)
                return
            end

            fprintf('Stopping and deleting the DO task\n')
            obj.hDO.Stop
            obj.hDO.Dispose;
            delete(obj.hDO);
            obj.hDO=[];
        end % stopAndDeleteDOTask


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


        function chanString = genChanString(obj,chans,chanType)
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
            % chanType - optional string defining the channel type to build. 'ao' by default
            %
            % Outputs
            % chanString - a string that the .NET wrapper will accept. e.g. 'Dev1/ao1,Dev1/ao3'
            %            Note the 'ao' here comes from the chanType input argument. 

            if nargin<3
                chanType = 'ao';
            end

            C = arrayfun(@(x) sprintf('%s/%s%d', obj.device_ID,chanType,x), chans, ...
                    'UniformOutput',false);

            if length(C) == 1
                chanString = C{1};
                return
            end

            C=cellfun(@(x) [x,','],C,'UniformOutput',false);
            C = strcat(C{:});
            C(end) = [];

            chanString = C;
        end % genChanString

    end % methods

end % classdef
