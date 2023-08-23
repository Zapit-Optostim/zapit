function varargout = sendSamples(obj, varargin)
    % Send waveforms for stimulation to the DAQ. Stimulation starts immediately or following a trigger.
    %
    % [conditionNum, laserOn, waveforms] = zapit.pointer.sendSamples(newTrial, verbose)
    %
    %
    % Purpose
    % This method is a critical part of the API for running experiments using Zapit. It writes
    % the stimulation waveforms for a single trial to the DAQ. The photostimulation either starts
    % immediately or after receipt of a digital trigger, depending on the state of the
    % "hardwareTriggered" input argument. The default is to wait for a trigger. Unless specified
    % explicitly, the stimulus (locations to photoactivate) is chosen at random. If the user has
    % defined an experiment directory via the GUI (or directly with zapit.pointer.experimentPath)
    % then trial data are logged to disk automatically.
    % Only runs if zapit.pointer.isReadyToStim returns true
    %
    %
    % Inputs [param/value pairs]
    % 'conditionNum' - Integer but empty by default. This is the index of the condition number to
    %                  present. If empty or -1 a random one is chosen.
    % 'laserOn' - [bool, true by default] If true the laser is on. If false the galvos move but
    %              the laser is off. If empty or -1, a random laser state is chosen.
    % 'stimDurationSeconds' - [scalar, -1 by default] If >0 once the waveform is sent to the DAQ
    %             and begins to play it will do so for a pre-defined time period before
    %             ramping down and stopping. e.g. if stimDurationSeconds is 1.5 then
    %             the waveform will play for 1.5 seconds then will ramp down and stop.
    % 'hardwareTriggered' [bool, true by default] If true the DAQ waits for a hardware trigger before
    %                   presenting the waveforms.
    % 'logging' - [bool, true by default] If true we write log files automatically if the user has
    %             defined a valid directory in zapit.pointer.experimentPath.
    % 'verbose' - [bool, false by default] If true print debug messages to screen.
    %
    %
    % Outputs
    % conditionNum - optionally return the condition number (index of this stimulus)
    % laserOn - optionally return whether or not the laser was on.
    % waveforms - optionally return the waveforms for debug.
    % All outputs are -1 if the method failed to run.
    %
    %
    % Examples
    % .sendSamples('laserOn',[]) % Present random condition with random laser on/off state
    % .sendSamples('hardwareTriggered', false) % Choose random sample and present immediately
    % .sendSamples('conditionNumber',3) % Play condition 3 after receiving a hardware trigger
    %
    %
    % Notes
    % * How are the waveforms generated?
    % The waveforms are obtained here with a call to stimConfig.chanSamples. i.e.
    % The user can call this at the CLI using "cs = hZP.stimConfig.chanSamples"
    % Then, for example, cs(:,:,3) are the waveforms for condition 3.
    % How is this generated?
    % The zapit.stimConfig class contains three methods that are used to make waveforms to
    % send to the DAQ. These methods are automatically run sequentially:
    % calibratedPoints -> calibratedPointsInVolts -> chanSamples (a getter)
    %
    %
    % Rob Campbell - SWC 2022
    % (from original by Maja Skretowska - SWC 2020-2022)


    %Parse optional arguments
    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('conditionNumber', [], @(x) isnumeric(x) && (isscalar(x) || isempty(x) || x == -1));
    params.addParameter('laserOn', true, @(x) isempty(x) || islogical(x) || x == 0 || x == 1 || x == -1);
    params.addParameter('stimDurationSeconds', -1, @(x) isnumeric(x) && (isscalar(x) || isempty(x) || x == -1));
    params.addParameter('hardwareTriggered', true, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('logging', true, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('verbose', false, @(x) islogical(x) || x==0 || x==1);

    params.parse(varargin{:});
    conditionNumber = params.Results.conditionNumber;
    laserOn = params.Results.laserOn;
    stimDurationSeconds = parms.Results.stimDurationSeconds;
    hardwareTriggered = params.Results.hardwareTriggered;
    logging = params.Results.logging;
    verbose = params.Results.verbose;

    if ~obj.isReadyToStim
        fprintf('zapit.pointer.%s -- Not ready to stimulate\n', mfilename)
        if nargout>0
            varargout{1} = -1;
        end

        if nargout>1
            varargout{2} = -1;
        end

        if nargout>2
            varargout{3} = -1;
        end
        return
    end

    % Choose a random condition if necessary
    if isempty(conditionNumber) || conditionNumber == -1
        r = randperm(obj.stimConfig.numConditions);
        conditionNumber = r(1);
    end

    % Choose random laser state if necessary
    if isempty(laserOn) || laserOn == -1
        r = randperm(2)-1;
        laserOn = r(1);
    end


    % If the user has specified an experiment directory path, we check whether a stimulus parameter
    % log file exists there and make one if not.
    if logging && ~isempty(obj.experimentPath) && exist(obj.experimentPath,'dir')
        d = dir(fullfile(obj.experimentPath,[obj.stimConfig.logFileStem,'*']));

        if isempty(d)
            % The user has defined an experiment directory and it does not contain a
            % stimulus parameter log file. We make one.
            logParamFname = obj.stimConfig.logStimulusParametersToFile(obj.experimentPath);
            fprintf('Writing stimulus parameter log file to %s\n', ...
                fullfile(obj.experimentPath,logParamFname))
        end

        % By this point there must be a parameter log file and, since we are logging, we write
        % a trial log file also.
        obj.stimConfig.logTrialToFile(obj.experimentPath, conditionNumber, laserOn, hardwareTriggered)
    end


    if verbose
        fprintf('Stimulating area %d\n', conditionNumber)
    end

    %%
    % Set up the waveforms

    % The current rampdown should be what is requested by this trial
    obj.stimConfig.offRampDownDuration_ms = ...
            obj.stimConfig.stimLocations(conditionNumber).Attributes.offRampDownDuration_ms;

    % Make the waveforms to play


    % if the stimulus duration was not specified by the user it will play
    % continuously until the user stops it. We first query stimConfig to get
    % one cycle of the waveform back
    waveforms = obj.stimConfig.chanSamples(:,:,conditionNumber);

    if stimDurationSeconds > 0
        % If the user has asked for a fixed duration, we make the required waveforms by
        % expanding the above.

        % 1. Repeat it to make the duration we need
        oneCyclePeriod = length(waveforms)/obj.DAQ.samplesPerSecond;
        numCyclesNeeded = round(stimDurationSeconds/oneCyclePeriod);
        tmp_waveforms = repmat(waveforms, [numCyclesNeeded,1]);

        % Now we add a rampdown
        if obj.stimConfig.offRampDownDuration_ms < 1
            % Just turn off laser (col 3) and masking LED (col 4) on last sample
            tmp_waveforms(3:4,:)=0;
        else
            % Make a temporary rampdown matrix
            numCyclesInRampDown = (obj.stimConfig.offRampDownDuration_ms*1E-3) / oneCyclePeriod;
            rampdownWaveform = repmat(waveforms,[numCyclesInRampDown,1]);

            % rampdown the laser line
            rampdownWaveform(:,3) = rampdownWaveform(:,3) .*  ...
                                linspace(1,0,length(rampdownWaveform))';

            % Then shut off masking LED
            rampdownWaveform(end,4) = 0;
            tmp_waveforms = [waveform; rampdownWaveform];
        end

        waveforms = tmp_waveforms;
    end



    % Disable laser if requested (masking LED remains on)
    if laserOn == 0
        waveforms(:,3) = 0;
    end

    % It will only connect if the existing task name is different
    % Force it to re-connect to DAQ if the user has previously presented
    % waveforms that had a different triggering type.
    if hardwareTriggered
        taskName = 'sendSamplesHtrig'; % Hardware trigger
    else
        taskName = 'sendSamplesSTrig'; % Software trigger
    end

    if stimDurationSeconds > 0
        taskName = [taskName,'FixedDur']; % Append string indicating fixed stim duration
    end

    obj.DAQ.connectClockedAO('fixedDurationWaveform', stimDurationSeconds > 0, ...
                            'numSamplesPerChannel', size(waveforms,1), ...
                            'hardwareTriggered', hardwareTriggered, ...
                            'taskName', taskName, ...
                            'verbose', false);



    % Write voltage samples onto the task
    obj.DAQ.writeAnalogData(waveforms);

    % Start the execution of the new task. Waveforms will only play immediately if
    % we are not waiting for a hardware trigger.
    obj.DAQ.start


    % If stim duration is fixed we wait for it to stop before stopping the task
    if  stimDurationSeconds > 0
        obj.DAQ.waitUntilAOTaskDone; % Block until the task is complete. (TODO: abstract this?)
        obj.DAQ.stop
    end

    %%
    if nargout>0
        varargout{1} = conditionNumber;
    end

    if nargout>1
        varargout{2} = laserOn;
    end

    if nargout>2
        varargout{3} = obj.waveforms;
    end

end % sendSamples
