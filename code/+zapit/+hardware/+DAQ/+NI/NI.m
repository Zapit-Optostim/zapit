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
        deviceName = 'Dev1'
        AOrange = 10
        sampleRate = 10E3
        triggerChannel = 'PFI0'
    end %close public properties

    properties (Hidden)

    end %close hidden properties



    methods
        function obj = NI(varargin)

            % TODO -- READ IN SETTINGS FROM YAML. Placeholder for now
            settings.DAQ.deviceName = 'Dev2'; %TODO
            settings.DAQ.AOrange = 10; %TODO
            settings.DAQ.sampleRate = 50000;
            settings.DAQ.triggerChannel = 'PFI0'

            % If there are valid settings in a parameter file, then we replace the hard-coded values with these
            if isfield(settings.DAQ,'deviceName')
                obj.deviceName = settings.DAQ.deviceName;
            end
            if isfield(settings.DAQ,'AOrange')
                obj.AOrange = settings.DAQ.AOrange;
            end
            if isfield(settings.DAQ,'sampleRate')
                obj.sampleRate = settings.DAQ.sampleRate;
            end
            if isfield(settings.DAQ,'triggerChannel')
                obj.triggerChannel = settings.DAQ.triggerChannel;
            end

            % Now we run the parameter parser. We use as defaults the properties above
            params = inputParser;
            params.CaseSensitive = false;
            
            params.addParameter('deviceName', obj.deviceName, @(x) ischar(x));
            params.addParameter('AOrange', obj.AOrange, @(x) isnumeric(x));
            params.addParameter('sampleRate', obj.sampleRate, @(x) isnumeric(x));
            params.addParameter('triggerChannel', obj.triggerChannel, @(x) ischar(x));
            params.parse(varargin{:});

            % Then replace the properties with the results of the parser. This will
            % mean that anything specified as an input arg will take precedence
            obj.deviceName = params.Results.deviceName;
            obj.AOrange = params.Results.AOrange;
            obj.sampleRate = params.Results.sampleRate;
            obj.triggerChannel = params.Results.triggerChannel;
            %(seems circular, but works nicely)

        end
    end

    methods (Abstract)
        connectUnlocked(obj)
    end


end %close classdef
