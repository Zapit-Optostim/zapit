classdef vidriowrapper < zapit.hardware.DAQ.NI.NI
    % Zapit NI DAQ class using Vidrio's wrapper for NI DAQmx
    %
    % Rob Campbell - SWC 2022

    % Note: undocumented methods are definition of abstract methods declared in
    % zapit.hardware.DAQ.NI.NI so please see there for documentation.


    properties
    end

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


        function stopAndDeleteTask(obj)
            obj.hC.stop;    % Calls DAQmxStopTask
            delete(obj.hC); % The destructor (dabs.ni.daqmx.Task.delete) calls DAQmxClearTask
        end % stopAndDeleteTask


        function connectUnclocked(obj, verbose)
            if nargin<2
                verbose = false;
            end
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


        function connectClocked(obj)

            numSamplesPerChannel = obj.numSamplesPerChannel;    % HOW TO DO THIS? CAN WE DO LATER?
            
            %% Create the inactivation task
            obj.hC = dabs.ni.daqmx.Task('clocked');
            
            % Set output channels
            obj.hC.createAOVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
            
            
            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hC.cfgSampClkTiming(obj.sampleRate, 'DAQmx_Val_ContSamps', numSamplesPerChannel, 'OnboardClock');
            obj.hC.cfgOutputBuffer(numSamplesPerChannel);
            
            % allow sample regeneration
            obj.hC.set('writeRegenMode', 'DAQmx_Val_AllowRegen');
            obj.hC.set('writeRelativeTo','DAQmx_Val_FirstSample');
            
            % Configure the trigger
            obj.hC.cfgDigEdgeStartTrig(obj.triggerChannel, 'DAQmx_Val_Rising');
        end
            

        function setLaserPowerControlVoltage(obj,laserControlVoltage)
            obj.hC.writeAnalogData([obj.lastXgalvoVoltage, obj.lastYgalvoVoltage, laserControlVoltage])

            % update cached values
            obj.lastLaserVoltage = laserControlVoltage; 
        end


        function moveBeamXY(obj,beamXY)
            beamXY = beamXY(:)'; % Ensure column vector
            obj.hC.writeAnalogData([beamXY, obj.lastLaserVoltage])

            % update cached values
            obj.lastXgalvoVoltage = beamXY(1);
            obj.lastYgalvoVoltage = beamXY(2);
        end

    end
end
