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

            obj.stopAndDeleteAOTask('hAI')

            obj.hAI = dabs.ni.daqmx.Task('unclocked');

            if verbose
                fprintf('Creating unclocked AI task on %s\n', obj.device_ID)
            end
            obj.hAO.createAIVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
        end % connectUnclockedAI

        function connectUnclockedAO(obj, verbose)
            if nargin<2
                verbose = false;
            end

            obj.stopAndDeleteAOTask

            obj.hAO = dabs.ni.daqmx.Task('unclocked');

            if verbose
                fprintf('Creating unclocked AO task on %s\n', obj.device_ID)
            end
            obj.hAO.createAOVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
        end % connectUnclockedAO


        function connectClockedAO(obj, numSamplesPerChannel, makeTriggerable, verbose)

            if nargin<2 || isempty(numSamplesPerChannel)
                numSamplesPerChannel = 1000;
            end

            if nargin<3 || isempty(makeTriggerable)
                makeTriggerable = false;
            end

            if nargin<4
                verbose = false;
            end


            obj.stopAndDeleteAOTask

            if verbose
                fprintf('Creating clocked AO task on %s\n', obj.device_ID)
            end
            
            %% Create the inactivation task
            obj.hAO = dabs.ni.daqmx.Task('clocked');
            
            % Set output channels
            obj.hAO.createAOVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
            
            
            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hAO.cfgSampClkTiming(obj.samplesPerSecond, 'DAQmx_Val_ContSamps', numSamplesPerChannel, 'OnboardClock');
            obj.hAO.cfgOutputBuffer(numSamplesPerChannel);
            
            % allow sample regeneration
            obj.hAO.set('writeRegenMode', 'DAQmx_Val_AllowRegen');
            obj.hAO.set('writeRelativeTo','DAQmx_Val_FirstSample');
            
            % Configure the trigger
            if makeTriggerable
                obj.hAO.cfgDigEdgeStartTrig(obj.triggerChannel, 'DAQmx_Val_Rising');
            end

        end % connectClockedAO


        function setLaserPowerControlVoltage(obj,laserControlVoltage)
            if ~strcmp(obj.hAO.taskName, 'unclocked')
                return
            end
            obj.hAO.writeAnalogData([obj.lastXgalvoVoltage, obj.lastYgalvoVoltage, laserControlVoltage])

            % update cached values
            obj.lastLaserVoltage = laserControlVoltage; 
        end % setLaserPowerControlVoltage


        function moveBeamXY(obj,beamXY)
            if ~strcmp(obj.hAO.taskName, 'unclocked')
                return
            end
            beamXY = beamXY(:)'; % Ensure column vector
            obj.hAO.writeAnalogData([beamXY, obj.lastLaserVoltage])

            % update cached values
            obj.lastXgalvoVoltage = beamXY(1);
            obj.lastYgalvoVoltage = beamXY(2);
        end % moveBeamXY

    end % methods

end % classdef
