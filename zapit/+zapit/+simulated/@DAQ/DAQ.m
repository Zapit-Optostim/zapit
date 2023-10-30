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
        samplesPerSecond % will be filled in with the value from the user settings file
        AOrange = 10
        AOchans = 0:3
        AIchans = 0;
        triggerChannel = 'PFI0'
        lastWaveform
    end %close public properties

    properties (Hidden)
        settings % Settings read from file
        parent  %A reference of the parent object (likely zapit.pointer) to which this component is attached
        delayStop %Timer used to implement a short delay before stopping AO
    end %close hidden properties


    % These properties may be used by the zapit.pointer API or its GUI.
    properties (Hidden, SetObservable, AbortSet)
        lastXgalvoVoltage  = 0
        lastYgalvoVoltage  = 0
        lastLaserVoltage = 0
        doingClockedAcquisition = false; % Set to true if we are doing a clocked acquisition
    end %close GUI-related properties


    methods
        function obj = DAQ()
            obj.settings = zapit.settings.readSettings;
            obj.hAI.readAnalogData = @(x) rand(length(obj.AIchans),1); % assumes unclocked
            obj.hAO.isTaskDone = true;
            obj.hAO.taskName = '';

            obj.delayStop = timer('Name', 'delayStopTimer', ...
                                'TimerFcn', @(~,~) obj.stop, ...
                                'StartDelay',0.2);
        end % Constructor

        function delete(obj)
            if isa(obj.delayStop,'timer')
                stop(obj.delayStop)
                delete(obj.delayStop)
            end
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
            obj.doingClockedAcquisition = false;
            obj.hAO.isTaskDone = true;
        end

        function stopAndDeleteAITask(obj)
        end % stopAndDeleteAITask

        function setLaserPowerControlVoltage(obj,laserVoltage)
            obj.lastLaserVoltage = laserVoltage;
        end % setLaserPowerControlVoltage

        function start(obj)
            obj.doingClockedAcquisition = true;
        end % start

        function stop(obj)
            obj.hAO.isTaskDone = true;
            obj.doingClockedAcquisition = false;
        end % stop

        function sampleQuantityMode = returnAOSampleQuantityMode(obj)
            sampleQuantityMode = 'SIMULATED';
        end % returnSampleQuantityMode

        function waitUntilAOTaskDone(obj)
            obj.hAO.isTaskDone = true;
            obj.doingClockedAcquisition = false;
        end

        function isDone = isAOTaskDone(obj)
            isDone = obj.hAO.isTaskDone;
        end % isAOTaskDone

        function isRunning = isFiniteSamplePlaying(obj)
            isRunning = false;
        end % isFiniteSamplePlaying

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
