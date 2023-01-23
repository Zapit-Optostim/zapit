classdef DAQ < handle
%%  DAQ
%
% Class to simulate a DAQ.
%
%
% An example of a class that inherits DAQ is NI.
%
% Rob Campbell - SWC 2022


    properties 

        hAO
        hAI

        device_ID = 'Dev1'
        samplesPerSecond = 10E3
        AOrange = 10
        AOchans = 0:4
        AIchans = 0;
        triggerChannel = 'PFI0'
        lastWaveform
    end %close public properties

    properties (Hidden)
        settings % Settings read from file
        parent  %A reference of the parent object (likely zapit.pointer) to which this component is attached
    end %close hidden properties


    % These properties may be used by the zapit.pointer API or its GUI.
    properties (Hidden, SetObservable, AbortSet)
        lastXgalvoVoltage  = 0
        lastYgalvoVoltage  = 0
        lastLaserVoltage = 0
    end %close GUI-related properties


    methods
        function obj = DAQ()
            obj.settings = zapit.settings.readSettings;
            obj.hAI.readAnalogData = @(x) rand(length(obj.AIchans),1); % assumes unclocked
            obj.hAO.isTaskDone = true;
            obj.hAO.taskName = '';
        end % Constructor

        function delete(obj)
        end

        function  success = connect(obj)
            success = true;
        end

        function connectUnclockedAI(obj,chans)
            obj.AIchans = chans;
        end
        
        function connectUnclockedAO(obj,verbose)
        end

        function connectClockedAO(obj,varargin)
            obj.hAO.isTaskDone = false;
        end

        function stopAndDeleteAOTask(obj)
            obj.lastWaveform = [];
            obj.hAO.isTaskDone = true;
        end

        function stopAndDeleteAITask(obj)
        end

        function moveBeamXY(obj,beamXYvoltage)
            obj.lastXgalvoVoltage = beamXYvoltage(1);
            obj.lastYgalvoVoltage = beamXYvoltage(2);
        end

        function setLaserPowerControlVoltage(obj,laserVoltage)
            obj.lastLaserVoltage = laserVoltage;
        end

        function start(obj)
        end

        function stop(obj)
            obj.hAO.isTaskDone = false;
        end

        function writeAnalogData(obj,waveforms)
            % Simulates write of analog data to the buffer
            %
            % function zapit.simulated.DAQ.writeAnalogData
            %
            % Purpose
            % Write analod data to the buffer and also log in a property the
            % data that were written.

            obj.lastWaveform = waveforms;
        end % writeAnalogData

        function nSamples = numSamplesInBuffer(obj)
            % Return the number of samples in the buffer
            %
            % function zapit.simulated.DAQ.numSamplesInBuffer
            %
            % Purpose
            % Return the number of samples in the buffer

            if isempty(obj.lastWaveform)
                nSamples = 0;
            else
                nSamples = length(obj.lastWaveform);
            end
        end % numSamplesInBuffer


    end %close methods




end %close classdef
