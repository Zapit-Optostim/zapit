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
        triggerChannel = 'PFI0'

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
        end % Constructor

        function  delete(obj)
        end

        function  success = connect(obj)
            success = true;
        end

        function connectUnclockedAI(obj,chans)
        end
        
        function connectUnclockedAO(obj)
        end

        function connectClockedAO(obj)
        end

        function stopAndDeleteAOTask(obj)
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
        end

    end %close methods




end %close classdef
