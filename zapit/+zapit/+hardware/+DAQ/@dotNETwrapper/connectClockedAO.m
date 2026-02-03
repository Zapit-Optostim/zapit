function connectClockedAO(obj, varargin)
    % Set up a clocked AO task
    %
    % function zapit.DAQ.dotNETwrapper.connectClockedAO
    %
    % Purpose
    % Create a clocked AO task for opto-stimulus delivery. 
    % The connection options are set by properties in the dotNETwrapper
    % class. see: .device_ID, .AOchans, .AOrange, .samplesPerSecond
    %
    % Inputs (optional)
    % fixedDurationWaveform - If true, the user is planning to specify a waveform
    %                       of a fixed duration and continuous samples is disabled.
    %                       In this scenario, the value for numSamplesPerChannel
    %                       is irrelevant here.
    % numSamplesPerChannel - Size of the buffer
    % samplesPerSecond - determines output rate and default comes from YAML file.
    % taskName - 'clockedAO' by default.
    % verbose - false by default
    % hardwareTriggered - false by default. If true, task waits for trigger (PFI0 by default
    %            and this line can be changed in the settings YAML)
    %
    % The task writes to the default number of AO lines (likely all four).

    import NationalInstruments.DAQmx.*
    %Parse optional arguments
    params = inputParser;
    params.CaseSensitive = false;

    params.addParameter('fixedDurationWaveform', false, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('numSamplesPerChannel', 1000, @(x) isnumeric(x) && isscalar(x));
    params.addParameter('samplesPerSecond', obj.samplesPerSecond, @(x) isnumeric(x) && isscalar(x));
    params.addParameter('taskName', 'clockedAO', @(x) ischar(x));
    params.addParameter('verbose', false, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('hardwareTriggered', false, @(x) islogical(x) || x==0 || x==1);

    params.parse(varargin{:});

    fixedDurationWaveform=params.Results.fixedDurationWaveform;
    numSamplesPerChannel=params.Results.numSamplesPerChannel;
    samplesPerSecond=params.Results.samplesPerSecond;
    taskName=params.Results.taskName;
    verbose=params.Results.verbose;
    hardwareTriggered=params.Results.hardwareTriggered;

    % If we are already connected we don't proceed
    if ~isempty(obj.hAO) && isvalid(obj.hAO) && obj.hAO.AOChannels.Count>0 && ...
            strcmp(char(obj.hAO.AOChannels.All.VirtualName), taskName)
        if verbose
            fprintf('DAQ connection to task %s already made. Skipping.\n', taskName)
        end

        % If we don't need to re-connect we may still need to stop the current task.
        % If finite samples are being presented we need to stop it before we can write more
        if strcmp(obj.hAO.Timing.SampleQuantityMode,'FiniteSamples')
            obj.stopStimulation;
        end

        return
    end

    % Clear any pre-existing AO tasks that may exist
    obj.stopAndDeleteAOTask

    if verbose
        fprintf('Creating clocked AO task on %s\n', obj.device_ID)
    end

    obj.hAO = NationalInstruments.DAQmx.Task(taskName);

    % Set output channels
    channelName = obj.genChanString(obj.AOchans);

    obj.hAO.AOChannels.CreateVoltageChannel(channelName, taskName, ...
                    -obj.AOrange, obj.AOrange, AOVoltageUnits.Volts);

    % Configure the task sample clock, the sample size and mode to be continuous
    % and set the size of the output buffer
    if fixedDurationWaveform
        sampleMode = SampleQuantityMode.FiniteSamples;
    else
        sampleMode = SampleQuantityMode.ContinuousSamples;
    end

    obj.hAO.Timing.ConfigureSampleClock('', ...
                samplesPerSecond, ...
                SampleClockActiveEdge.Rising, ...
                sampleMode, ...
                numSamplesPerChannel);


    % allow sample regeneration
    obj.hAO.Stream.WriteRegenerationMode = WriteRegenerationMode.AllowRegeneration;

    obj.hAO.Control(TaskAction.Verify);

    obj.hAOtaskWriter = AnalogMultiChannelWriter(obj.hAO.Stream);
    % Configure the trigger
    if hardwareTriggered
        if verbose
            fprintf('Configuring a hardware trigger on line %s\n', ...
                obj.settings.NI.triggerChannel)
        end
        obj.hAO.Triggers.StartTrigger.ConfigureDigitalEdgeTrigger(...
                    obj.settings.NI.triggerChannel, ...
                    DigitalEdgeStartTriggerEdge.Rising);
    end

end % connectClockedAO