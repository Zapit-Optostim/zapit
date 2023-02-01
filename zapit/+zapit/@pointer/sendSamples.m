function varargout = sendSamples(obj, varargin)
    % Take X/Y coordinates of two points and cycle the laser between them.
    %
    % [conditionNum, laserOn, waveforms] = zapit.pointer.sendSamples(obj,newTrial,verbose)
    %
    %
    % Purpose
    % Take X/Y coordinates of two points and exchange the laser between them at freqLaser for
    % pulseDuration seconds, locking it at a given point for tOpen ms. The parameters to actually
    % stimulate are obtained from the structure, t_trial, which is supplied as an obligatory
    % input argument (see below).
    % This function builds an n by 4 matrix of waveforms to send to the DAQ. The first two columns
    % are the scanner waveforms. The last two are the laser power and masking light.
    %
    % Inputs [param/value pairs]
    % 'conditionNum' - Integer but empty by default. This is the index of the condition number to
    %                  present. If empty or -1 a random one is chosen.
    % 'laserOn' - [bool, true by default] If true the laser is on. If false the galvos move but laser is off.
    %              If empty or -1 a random laser state is chosen.
    % 'hardwareTriggered' [bool, true by default] If true the DAQ waits for a hardware trgger before 
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
    %
    %   
    % Examples
    % .sendSamples('laserOn',[]) % Present random condition with random laser on/off state
    % .sendSamples('hardwareTriggered', false) % Present random sample and do not wait for hardware trigger
    % .sendSamples('conditionNumber',3) % Play condition 3 after receiving a hardware trigger
    %
    % Rob Campbell - SWC 2022 
    % (from original by Maja Skretowska - SWC 2020-2022)


    %Parse optional arguments
    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('conditionNumber', [], @(x) isnumeric(x) && (isscalar(x) || isempty(x) || x == -1));
    params.addParameter('laserOn', true, @(x) isempty(x) || islogical(x) || x == 0 || x == 1 || x == -1);
    params.addParameter('hardwareTriggered', true, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('logging', true, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('verbose', false, @(x) islogical(x) || x==0 || x==1);

    params.parse(varargin{:});
    conditionNumber = params.Results.conditionNumber;
    laserOn = params.Results.laserOn;
    hardwareTriggered = params.Results.hardwareTriggered;
    logging = params.Results.logging;
    verbose = params.Results.verbose;


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


    % Make the waveforms to play
    cs = obj.stimConfig.chanSamples;
    waveforms = cs(:,:,conditionNumber);

    % Disable laser if requested
    if laserOn == 0
        waveforms(:,3) = 0;
    end

    % It will only connect if the existing task name is different
    obj.DAQ.connectClockedAO('numSamplesPerChannel',size(waveforms,1), ...
                            'hardwareTriggered', hardwareTriggered, ...
                            'taskName','sendSamples');
  
    
    % The current rampdown should be what is requested by this trial
    obj.stimConfig.offRampDownDuration_ms = ...
            obj.stimConfig.stimLocations(conditionNumber).Attributes.offRampDownDuration_ms;


    % write voltage samples onto the task
    obj.DAQ.writeAnalogData(waveforms);

    % start the execution of the new task
    obj.DAQ.start;

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
