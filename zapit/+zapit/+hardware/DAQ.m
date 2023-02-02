classdef (Abstract) DAQ < handle

    properties
        hAO  % A reference to an object that provides access to the DAQ's API for the AO task
        hAI  % A reference to an object that provides access to the DAQ's API for the AI task

        % The following are default parameters for the class (see above)
        device_ID = 'Dev1'
        samplesPerSecond = 10E5
        AOrange = 10
        AOchans = 0:3
        triggerChannel = 'PFI0'
    end %close public properties


    properties (Hidden)
        settings % Settings read from file
        parent    %A reference of the parent object (likely zapit.pointer) to which this component is attached
        delayStop %Timer used to implement a short delay before stopping AO
    end %close hidden properties


    % These properties may be used by the zapit.pointer API or its GUI.
    properties (Hidden, SetObservable, AbortSet)
        lastWaveform = [] % The last waveform sent to the DAQ for AO
        doingClockedAcquisition = false; % Set to true if we are doing a clocked acquisition
    end %close GUI-related properties


    methods

        function obj = DAQ(varargin)

            % Pull in the input arguments and set defaults
            obj.settings = zapit.settings.readSettings;

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
            if isfield(obj.settings.NI,'triggerChannel')
                obj.triggerChannel = obj.settings.NI.triggerChannel;
            end

            % Now we run the parameter parser. We use as defaults the properties above
            params = inputParser;
            params.CaseSensitive = false;

            params.addParameter('device_ID', obj.device_ID, @(x) ischar(x));
            params.addParameter('samplesPerSecond', obj.samplesPerSecond, @(x) isnumeric(x));
            params.addParameter('AOrange', obj.AOrange, @(x) isnumeric(x));
            params.addParameter('triggerChannel', obj.triggerChannel, @(x) ischar(x));
            params.parse(varargin{:});

            % Then replace the properties with the results of the parser. This will
            % mean that anything specified as an input arg will take precedence
            obj.device_ID= params.Results.device_ID;
            obj.samplesPerSecond = params.Results.samplesPerSecond;
            obj.AOrange = params.Results.AOrange;
            obj.triggerChannel = params.Results.triggerChannel;
            %(seems circular, but works nicely)

            obj.delayStop = timer('TimerFcn',@(~,~) obj.stop,'StartDelay',0.2);
        end % Constructor

    end

end
