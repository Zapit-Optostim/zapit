classdef vidriowrapper < zapit.hardware.DAQ.NI.NI
    % Zapit NI DAQ class using Vidrio's wrapper for NI DAQmx
    %
    % Rob Campbell - SWC 2022

    % Note: undocumented methods are definition of abstract methods declared in
    % zapit.hardware.DAQ.NI.NI so please see there for documentation.


    properties
    end % properties

    methods

        function obj = vidriowrapper(varargin)
            obj = obj@zapit.hardware.DAQ.NI.NI(varargin{:});
        end % Constructor


        function connect(obj,connectionType)
            % TODO -- I think we don't use this. 
            switch connectionType
                case 'unclocked'
                    obj.connectUnlocked
                case 'clocked'
                    body
                otherwise
                    fprintf('Unknown connection type %s in zapit.hardware.DAQ.NI.vidriowrapper.connect\n', connectionType)
            end % switch
        end % connect


        function start(obj)
            % Definition of abstract class declared in zapit.hardware.DAQ
            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.hAO.start
        end


        function stop(obj)
            % Definition of abstract class declared in zapit.hardware.DAQ
            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.hAO.stop
        end


        function stopAndDeleteAOTask(obj)
            % Definition of abstract class declared in zapit.hardware.DAQ.NI
            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.hAO.stop;    % Calls DAQmxStopTask
            delete(obj.hAO);
        end % stopAndDeleteAOTask


        function stopAndDeleteAITask(obj)
            % Definition of abstract class declared in zapit.hardware.DAQ.NI
            if isempty(obj.hAI) || ~isvalid(obj.hAI)
                return
            end
            obj.hAI.stop;    % Calls DAQmxStopTask
            delete(obj.hAI);
        end % stopAndDeleteAITask


        function connectUnclockedAI(obj, chans, verbose)
            if nargin<3
                verbose = false;
            end

            obj.stopAndDeleteAITask

            obj.hAI = dabs.ni.daqmx.Task('unclockedai');

            if verbose
                fprintf('Creating unclocked AI task on %s\n', obj.device_ID)
            end
            obj.hAI.createAIVoltageChan(obj.device_ID, ...
                                        chans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
        end % connectUnclockedAI

        function connectUnclockedAO(obj, verbose)
            if nargin<2
                verbose = false;
            end

            obj.stopAndDeleteAOTask

            obj.hAO = dabs.ni.daqmx.Task('unclockedao');

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
            % Start a clocked task. Optional input args:
            %
            % Inputs (optional)
            % numSamplesPerChannel - Size of the buffer
            % samplesPerSecond - determines output rate and default comes from YAML file. Likely
            %                   this will be about 1E6.
            % taskName - 'clockedao' by default
            % verbose - false by default
            % makeTriggerable - false by default. If true, task waits for trigger (PFI0 by default
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
            params.addParameter('makeTriggerable', false, @(x) islogical(x) || x==0 || x==1);

            params.parse(varargin{:});

            numSamplesPerChannel=params.Results.numSamplesPerChannel;
            samplesPerSecond=params.Results.samplesPerSecond;
            taskName=params.Results.taskName;
            verbose=params.Results.verbose;
            makeTriggerable=params.Results.makeTriggerable;


            obj.stopAndDeleteAOTask

            if verbose
                fprintf('Creating clocked AO task on %s\n', obj.device_ID)
            end
            
            %% Create the inactivation task
            obj.hAO = dabs.ni.daqmx.Task(taskName);
            
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
            if makeTriggerable
                obj.hAO.cfgDigEdgeStartTrig(obj.triggerChannel, 'DAQmx_Val_Rising');
            end

        end % connectClockedAO


        function writeAnalogData(obj,waveforms)
            % Write analog data to the buffer
            %
            % Purpose
            % Write analod data to the buffer and also log in a property the
            % data that were written.

            obj.lastWaveform = waveforms;
            obj.hAO.writeAnalogData(waveforms);
        end % writeAnalogData


        function setLaserPowerControlVoltage(obj,laserControlVoltage)
            if ~isvalid(obj.hAO) || ~strcmp(obj.hAO.taskName, 'unclockedao')
                obj.connectUnclockedAO
            end
            obj.hAO.writeAnalogData([obj.lastXgalvoVoltage, obj.lastYgalvoVoltage, laserControlVoltage])

            % update cached values
            obj.lastLaserVoltage = laserControlVoltage; 
        end % setLaserPowerControlVoltage


        function moveBeamXY(obj,beamXY)
            if ~isvalid(obj.hAO) || ~strcmp(obj.hAO.taskName, 'unclockedao')
                obj.connectUnclockedAO
            end
            beamXY = beamXY(:)'; % Ensure column vector
            obj.hAO.writeAnalogData([beamXY, obj.lastLaserVoltage])

            % update cached values
            obj.lastXgalvoVoltage = beamXY(1);
            obj.lastYgalvoVoltage = beamXY(2);
        end % moveBeamXY

    end % methods

end % classdef
