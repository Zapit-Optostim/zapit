classdef vidriowrapper < zapit.hardware.DAQ.NI.NI
    % Zapit NI DAQ class using Vidrio's wrapper for NI DAQmx
    %
    % Rob Campbell - SWC 2022
    properties
    end

    methods

        function obj = vidriowrapper(varargin)
            obj = obj@zapit.hardware.DAQ.NI.NI(varargin{:});
        end

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


        function connectUnlocked(obj)
            obj.hC = dabs.ni.daqmx.Task('unclocked');
            obj.hC.createAOVoltageChan(obj.deviceName, 0:2, [], -obj.AIrange, obj.AIrange);
        end % createUnclockedTask

        function connectClocked(obj)

            numSamplesPerChannel = obj.numSamplesPerChannel;    % HOW TO DO THIS? CAN WE DO LATER?
            
            %% Create the inactivation task
            obj.hC = dabs.ni.daqmx.Task('clocked');
            
            % Set output channels
            obj.hTask.createAOVoltageChan(obj.deviceName, 0:2, [], -obj.AIrange, obj.AIrange);
            
            
            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hTask.cfgSampClkTiming(obj.sampleRate, 'DAQmx_Val_ContSamps', numSamplesPerChannel, 'OnboardClock');
            obj.hTask.cfgOutputBuffer(numSamplesPerChannel);
            
            % allow sample regeneration
            obj.hTask.set('writeRegenMode', 'DAQmx_Val_AllowRegen');
            obj.hTask.set('writeRelativeTo','DAQmx_Val_FirstSample');
            
            % Configure the trigger
            obj.hTask.cfgDigEdgeStartTrig(obj.triggerChannel, 'DAQmx_Val_Rising');
            

        function setLaserPowerControlVoltage(obj,laserControlVoltage)
            obj.hTask.writeAnalogData([obj.lastXgalvoVoltage, obj.lastYgalvoVoltage, laserControlVoltage])

            % update cached values
            obj.lastLaserVoltage = laserControlVoltage; 
        end

        function moveBeamXY(obj,beamXY)
            beamXY = beamXY(:)'; % Ensure column vector
            obj.hTask.writeAnalogData([beamXY, obj.lastLaserVoltage])

            % update cached values
            obj.lastXgalvoVoltage = beamXY(1);
            obj.lastYgalvoVoltage = beamXY(2);
        end

    end
end