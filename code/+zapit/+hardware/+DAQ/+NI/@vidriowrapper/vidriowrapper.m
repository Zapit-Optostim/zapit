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
            if isempty(obj.hC) || ~isvalid(obj.hC)
                return
            end
            obj.hC.start
        end


        function stop(obj)
            % Definition of abstract class declared in zapit.hardware.DAQ
            if isempty(obj.hC) || ~isvalid(obj.hC)
                return
            end
            obj.hC.stop
        end


        function stopAndDeleteTask(obj)
            % Definition of abstract class declared in zapit.hardware.DAQ.NI
            if isempty(obj.hC) || ~isvalid(obj.hC)
                return
            end
            obj.hC.stop;    % Calls DAQmxStopTask
            delete(obj.hC); % The destructor (dabs.ni.daqmx.Task.delete) calls DAQmxClearTask
        end % stopAndDeleteTask


        function connectUnclocked(obj, verbose)
            if nargin<2
                verbose = false;
            end

            obj.stopAndDeleteTask

            obj.hC = dabs.ni.daqmx.Task('unclocked');

            if verbose
                fprintf('Creating unclocked task on %s\n', obj.device_ID)
            end
            obj.hC.createAOVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
        end % connectUnclocked


        function connectClocked(obj, numSamplesPerChannel, makeTriggerable, verbose)

            if nargin<2 || isempty(numSamplesPerChannel)
                numSamplesPerChannel = 1000;
            end

            if nargin<3 || isempty(makeTriggerable)
                makeTriggerable = false;
            end

            if nargin<4
                verbose = false;
            end


            obj.stopAndDeleteTask

            if verbose
                fprintf('Creating clocked task on %s\n', obj.device_ID)
            end
            
            %% Create the inactivation task
            obj.hC = dabs.ni.daqmx.Task('clocked');
            
            % Set output channels
            obj.hC.createAOVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
            
            
            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hC.cfgSampClkTiming(obj.samplesPerSecond, 'DAQmx_Val_ContSamps', numSamplesPerChannel, 'OnboardClock');
            obj.hC.cfgOutputBuffer(numSamplesPerChannel);
            
            % allow sample regeneration
            obj.hC.set('writeRegenMode', 'DAQmx_Val_AllowRegen');
            obj.hC.set('writeRelativeTo','DAQmx_Val_FirstSample');
            
            % Configure the trigger
            if makeTriggerable
                obj.hC.cfgDigEdgeStartTrig(obj.triggerChannel, 'DAQmx_Val_Rising');
            end

        end % connectClocked


        function setLaserPowerControlVoltage(obj,laserControlVoltage)
            if ~strcmp(obj.hC.taskName, 'unclocked')
                return
            end
            obj.hC.writeAnalogData([obj.lastXgalvoVoltage, obj.lastYgalvoVoltage, laserControlVoltage])

            % update cached values
            obj.lastLaserVoltage = laserControlVoltage; 
        end % setLaserPowerControlVoltage


        function moveBeamXY(obj,beamXY)
            if ~strcmp(obj.hC.taskName, 'unclocked')
                return
            end
            beamXY = beamXY(:)'; % Ensure column vector
            obj.hC.writeAnalogData([beamXY, obj.lastLaserVoltage])

            % update cached values
            obj.lastXgalvoVoltage = beamXY(1);
            obj.lastYgalvoVoltage = beamXY(2);
        end % moveBeamXY

    end % methods

end % classdef
