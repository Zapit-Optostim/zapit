classdef (Abstract) DAQ < handle
%%  DAQ
%
% The DAQ abstract class is a software entity that is associated with the DAQ.
% This is a generic DAQ that defines no behaviors but merely specifies the 
% properties and methods that all DAQs must define. 
%
%
% An example of a class that inherits DAQ is NI.
%
% Rob Campbell - SWC 2022


    properties 

        hC  % A reference to an object that provides access to the DAQ's API

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
    end

    methods (Abstract)
        success = connect(obj)
        % connect
        %
        % Behavior
        % Establishes a connection between the hardware device and the host PC. 
        % The method uses the deviceID property to establish the connection. 
        %
        % Outputs
        % success - true or false depending on whether a connection was established


        % The following I know we will need but they are not full documented yet. (TODO)

        moveBeamXY(obj,beamXYvoltage)

        setLaserPowerControlVoltage(obj,laserVoltage)

        start(obj)

        stop(obj)
        % Start task

    end %close abstract methods


    %The following methods are common to all DAQs
    methods
        function  delete(obj)
            delete(obj.hC)
        end
    end %close methods

end %close classdef
