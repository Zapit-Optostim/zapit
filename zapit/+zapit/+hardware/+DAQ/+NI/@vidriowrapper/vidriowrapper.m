classdef vidriowrapper < handle
    % Zapit NI DAQ class using Vidrio's wrapper for NI DAQmx
    %
    % zapit.hardware.DAQ.vidriowrapper
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
        hAO  % A reference to an object that provides access to the DAQ's API for the AO task
        hAI  % A reference to an object that provides access to the DAQ's API for the AI task

        % The following are default parameters for the class (see above)
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
        lastWaveform = [] % The last waveform sent to the DAQ for AO
    end %close GUI-related properties


    methods

        function obj = vidriowrapper(varargin)

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

        end % Constructor

        function delete(obj)
            delete(obj.hAI)
            delete(obj.hAO)
        end

        function start(obj)
            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.hAO.start
        end


        function stop(obj)
            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.hAO.stop
        end


        function stopAndDeleteAOTask(obj)
            % stopAndDeleteAOTask(obj)
            %
            % Stop the task and then delete it, which will run DAQmxClearTask
            if isempty(obj.hAO) || ~isvalid(obj.hAO)
                return
            end
            obj.hAO.stop;    % Calls DAQmxStopTask
            delete(obj.hAO);
        end % stopAndDeleteAOTask


        function stopAndDeleteAITask(obj)
            if isempty(obj.hAI) || ~isvalid(obj.hAI)
                return
            end
            obj.hAI.stop;    % Calls DAQmxStopTask
            delete(obj.hAI);
        end % stopAndDeleteAITask


        function connectUnclockedAI(obj, chans, verbose)
            % connectUnclockedAO(obj)
            %
            % Create a task that is unclocked AI and can be used for misc tasks.
            %
            % Inputs
            % chans - which chans to conect. Must be supplied.
            % verbose - 

            if nargin<3
                verbose = false;
            end

            obj.stopAndDeleteAITask

            obj.hAI = zapit.hardware.vidrio_daqmx.Task('unclockedai');

            if verbose
                fprintf('Creating unclocked AI task on %s\n', obj.device_ID)
            end
            obj.hAI.createAIVoltageChan(obj.device_ID, ...
                                        chans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
        end % connectUnclockedAI

        function connectUnclockedAO(obj, verbose)
            % connectUnclockedAO(obj)
            %
            % Create a task that is unclocked AO and can be used for sample setup.

            if nargin<2
                verbose = false;
            end

            obj.stopAndDeleteAOTask

            obj.hAO = zapit.hardware.vidrio_daqmx.Task('unclockedao');

            if verbose
                fprintf('Creating unclocked AO task on %s\n', obj.device_ID)
            end
            obj.hAO.createAOVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
        end % connectUnclockedAO


        function connectClockedAO(obj, varargin)
            % Start a clocked task. Optional input args:
            %
            % Inputs (optional)
            % numSamplesPerChannel - Size of the buffer
            % samplesPerSecond - determines output rate and default comes from YAML file. Likely
            %                   this will be about 1E6.
            % taskName - 'clockedao' by default
            % verbose - false by default
            % hardwareTriggered - false by default. If true, task waits for trigger (PFI0 by default
            %            and this line can be changed in the settings YAML)
            %
            % The task writes to the default number of AO lines (likely all four).

            %Parse optional arguments
            params = inputParser;
            params.CaseSensitive = false;

            params.addParameter('numSamplesPerChannel', 1000, @(x) isnumeric(x) && isscalar(x));
            params.addParameter('samplesPerSecond', obj.samplesPerSecond, @(x) isnumeric(x) && isscalar(x));
            params.addParameter('taskName', 'clockedAO', @(x) ischar(x));
            params.addParameter('verbose', false, @(x) islogical(x) || x==0 || x==1);
            params.addParameter('hardwareTriggered', false, @(x) islogical(x) || x==0 || x==1);

            params.parse(varargin{:});

            numSamplesPerChannel=params.Results.numSamplesPerChannel;
            samplesPerSecond=params.Results.samplesPerSecond;
            taskName=params.Results.taskName;
            verbose=params.Results.verbose;
            hardwareTriggered=params.Results.hardwareTriggered;


            obj.stopAndDeleteAOTask

            if verbose
                fprintf('Creating clocked AO task on %s\n', obj.device_ID)
            end
            
            %% Create the inactivation task
            obj.hAO = zapit.hardware.vidrio_daqmx.Task(taskName);
            
            % Set output channels
            obj.hAO.createAOVoltageChan(obj.device_ID, ...
                                        obj.AOchans, ...
                                        [], ...
                                        -obj.AOrange, ...
                                        obj.AOrange);
            
            
            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hAO.cfgSampClkTiming(samplesPerSecond, 'DAQmx_Val_ContSamps', numSamplesPerChannel, 'OnboardClock');
            obj.hAO.cfgOutputBuffer(numSamplesPerChannel);
            
            % allow sample regeneration
            obj.hAO.set('writeRegenMode', 'DAQmx_Val_AllowRegen');
            obj.hAO.set('writeRelativeTo','DAQmx_Val_FirstSample');
            
            % Configure the trigger
            if hardwareTriggered
                obj.hAO.cfgDigEdgeStartTrig(obj.settings.NI.triggerChannel, 'DAQmx_Val_Rising');
            end

        end % connectClockedAO


        function writeAnalogData(obj,waveforms)
            % Write analog data to the buffer
            %
            % Purpose
            % Write analod data to the buffer and also log in a property the
            % data that were written.

            obj.lastWaveform = waveforms;
            obj.hAO.writeAnalogData(waveforms);
        end % writeAnalogData


        function setLaserPowerControlVoltage(obj,laserControlVoltage)
            if ~isvalid(obj.hAO) || ~strcmp(obj.hAO.taskName, 'unclockedao')
                obj.connectUnclockedAO
            end
            obj.hAO.writeAnalogData([obj.lastXgalvoVoltage, obj.lastYgalvoVoltage, laserControlVoltage])

            % update cached values
            obj.lastLaserVoltage = laserControlVoltage; 
        end % setLaserPowerControlVoltage


        function moveBeamXY(obj,beamXY)
            if ~isvalid(obj.hAO) || ~strcmp(obj.hAO.taskName, 'unclockedao')
                obj.connectUnclockedAO
            end
            beamXY = beamXY(:)'; % Ensure column vector
            obj.hAO.writeAnalogData([beamXY, obj.lastLaserVoltage])

            % update cached values
            obj.lastXgalvoVoltage = beamXY(1);
            obj.lastYgalvoVoltage = beamXY(2);
        end % moveBeamXY

    end % methods

end % classdef
