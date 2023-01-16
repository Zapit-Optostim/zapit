classdef (Abstract) NI < zapit.hardware.DAQ.DAQ
%%  NI
%
% The NI abstract class is a software entity that is associated with an NI DAQ.
% This class does not assume any particular API for communicating with the DAQ.
%
% Instantiating:
% If called with no arguments regarding settings, the properties used 
% for connecting with the DAQ are obtained in this order:
% 1. From param/value argument pairs on construction. 
% 2. From the settings YAML file. 
% 3. From the hard-coded properties in this object
%
% You can mix and match. e.g. if you supply the device name as a param/value 
% pair but nothing else, then the rest of the settings  are obtained from 
% settings YAML (assuming it exists).
%
%
% Analog lines are:
% 0 -- Galvo X
% 1 -- Galvo Y
% 2 -- Laser control voltage signal
%
%
% Rob Campbell - SWC 2022


    properties 
        % The following are default parameters for the class (see above)
        device_ID = 'Dev1'
        samplesPerSecond = 10E3
        AOrange = 10
        AOchans = 0:4
        triggerChannel = 'PFI0'
    end %close public properties

    properties (Hidden)

    end %close hidden properties



    methods
        function obj = NI(varargin)
            obj = obj@zapit.hardware.DAQ.DAQ(varargin{:});

            % Settings are read from YAML in zapit.hardware.DAQ.DAQ

            % If there are valid settings in a parameter file, then we replace the hard-coded values with these
            if isfield(obj.settings.NI,'device_ID')
                obj.device_ID = obj.settings.NI.device_ID;
            end
            if isfield(obj.settings.NI,'samplesPerSecond')
                obj.samplesPerSecond = obj.settings.NI.samplesPerSecond;
            end
            if isfield(obj.settings.NI,'AOrange')
                obj.AOrange = obj.settings.NI.AOrange;
            end
            if isfield(obj.settings.NI,'AOchans')
                obj.AOchans = obj.settings.NI.AOchans;
            end
            if isfield(obj.settings.NI,'triggerChannel')
                obj.triggerChannel = obj.settings.NI.triggerChannel;
            end

            % Now we run the parameter parser. We use as defaults the properties above
            params = inputParser;
            params.CaseSensitive = false;
            
            params.addParameter('device_ID', obj.device_ID, @(x) ischar(x));
            params.addParameter('samplesPerSecond', obj.samplesPerSecond, @(x) isnumeric(x));
            params.addParameter('AOrange', obj.AOrange, @(x) isnumeric(x));
            params.addParameter('AOchans', obj.AOchans, @(x) isnumeric(x));
            params.addParameter('triggerChannel', obj.triggerChannel, @(x) ischar(x));
            params.parse(varargin{:});

            % Then replace the properties with the results of the parser. This will
            % mean that anything specified as an input arg will take precedence
            obj.device_ID= params.Results.device_ID;
            obj.samplesPerSecond = params.Results.samplesPerSecond;
            obj.AOrange = params.Results.AOrange;
            obj.AOchans = params.Results.AOchans;
            obj.triggerChannel = params.Results.triggerChannel;
            %(seems circular, but works nicely)

        end
    end

    methods (Abstract)

        connectUnclockedAI(obj,chans)
        % connectUnclockedAO(obj)
        %
        % Create a task that is unclocked AI and can be used for misc tasks.
        %
        % Inputs
        % chans - which chans to conect. Must be supplied.

        connectUnclockedAO(obj)
        % connectUnclockedAO(obj)
        %
        % Create a task that is unclocked AO and can be used for sample setup.

        connectClockedAO(obj)
        % connectClockedAO(obj)
        %
        % Create a task that is clocked AO and can be used for running the experiment

        stopAndDeleteAOTask(obj)
        % stopAndDeleteAOTask(obj)
        %
        % Stop the task and then delete it, which will run DAQmxClearTask
    end


end %close classdef
