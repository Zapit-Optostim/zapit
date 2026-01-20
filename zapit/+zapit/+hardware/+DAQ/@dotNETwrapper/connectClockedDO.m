function connectClockedDO(obj, varargin)
    % Set up a clocked DO task that will be triggered and synced to the AO task
    %
    % function zapit.DAQ.dotNETwrapper.connectClockedDO
    %
    % Purpose
    % Create clocked DO task that will deliver digital waveforms for things like
    % the LED masking light. The clocked DO task will be syncronised to the AO 
    % waveform so connectClockedAO will need to have been run first. 
    %
    % Inputs (optional)
    % fixedDurationWaveform - If true, the user is planning to specify a waveform
    %                       of a fixed duration and continuous samples is disabled.
    %                       In this scenario, the value for numSamplesPerChannel
    %                       is irrelevant here.
    % numSamplesPerChannel - Size of the buffer
    % samplesPerSecond - determines output rate and default comes from YAML file.
    % taskName - 'clockedDO' by default.
    % verbose - false by default
    % hardwareTriggered - false by default. If true, task waits for trigger (PFI0 by default
    %            and this line can be changed in the settings YAML)
    %
    % The task writes to the default number of AO lines (likely all four).

    import NationalInstruments.DAQmx.*
    %Parse optional arguments
    params = inputParser;
    params.CaseSensitive = false;


    % TODO -- should get this stuff from the AO task and should return a failure to 
    % build if the AO task has not already been set up
    params.addParameter('fixedDurationWaveform', false, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('numSamplesPerChannel', 1000, @(x) isnumeric(x) && isscalar(x));
    params.addParameter('samplesPerSecond', obj.samplesPerSecond, @(x) isnumeric(x) && isscalar(x));
    params.addParameter('taskName', 'clockedDO', @(x) ischar(x));
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
    if ~isempty(obj.hDO) && isvalid(obj.hDO))
        if verbose
            fprintf('DAQ connection to task %s already made. Skipping.\n', taskName)
        end

        % If we don't need to re-connect we may still need to stop the current task.
        % If finite samples are being presented we need to stop it before we can write more
        if strcmp(obj.hDO.Timing.SampleQuantityMode,'FiniteSamples') % UNTESTED!
            obj.stop
        end

        return
    end

    obj.stopAndDeleteDOTask % NOT WRITTEN

    if verbose
        fprintf('Creating clocked DO task on %s\n', obj.device_ID)
    end

    % Create a task and set up output channels
    obj.hDO = NationalInstruments.DAQmx.Task(taskName);
    
    obj.hDO.DOChannels.CreateChannel( ...
            [obj.device_ID,'/port0']
           'do0', ...
            ChannelLineGrouping.OneChannelForAllLines);


    % Configure the task sample clock, the sample size and mode to be continuous
    % and set the size of the output buffer
    if fixedDurationWaveform
        sampleMode = SampleQuantityMode.FiniteSamples;
    else
        sampleMode = SampleQuantityMode.ContinuousSamples;
    end


    % * Configure the sampling rate and buffer size of the DO task. 
    % Note that we are using the AO sample clock for the DO. 
    obj.hDO.Timing.ConfigureSampleClock( ...
        ['/', obj.device_ID, '/ao/SampleClock'], ...
        samplesPerSecond, ...
        SampleClockActiveEdge.Rising, ...
        sampleMode, ...
        numSamplesPerChannel);

    % allow sample regeneration
    obj.hDO.Stream.WriteRegenerationMode = WriteRegenerationMode.AllowRegeneration;

    obj.hDO.Control(TaskAction.Verify);


    obj.hDOtaskWriter = DigitalSingleChannelWriter(obj.hDO.Stream);

    % * Configure the DO task to start when the AO task starts
    obj.hDO.Triggers.StartTrigger.ConfigureDigitalEdgeTrigger(...
        ['/', obj.device_ID, '/ao/StartTrigger'], ...
        DigitalEdgeStartTriggerEdge.Rising); 


end % connectClockedAO