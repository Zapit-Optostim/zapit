function varargout = logTrialToFile(obj, filePath, stimIndex, laserState, hardwareTriggered)
    % Write information on the current trial to the stimulus log file
    %
    % function fname = zapit.stimConfig.logTrialToFile(obj, filePath)
    %
    % Purpose
    % By the time this method is called we will already have a stimulus parameter log file
    % in the experiment directory. We will write to another file in this directory that will
    % contain only details about each tial. Each trial will be logged in this format:
    %
    % Timestamp, Stim Index, Laser state (true false), hardware triggered (true/false)
    %  2023-04-19 13:13:33, 4, 1, 1
    %
    % Inputs
    % filePath - the path to the file to write.
    % stimIndex - [positive scalar] the index of the stimulus that was presented
    % laserState - [0/1] true if the laser was on during this trial
    % hardwareTriggered - [0/1] true if the trial was triggered by the DAQ hardware
    %
    % Example:
    %  hZP.stimConfig.logTrialToFile(pwd,2,1,1)
    %
    % This method will likely only ever be called by zapit.pointer.sendSamples
    %
    % Rob Campbell - SWC 2023
     
    % Get the name of the parameter log file
    log_fname = sprintf('%s*.yml', obj.logFileStem);
    log_fname_path = fullfile(filePath, log_fname);


    % Bail out if it's not there
    d=dir(log_fname_path);
    if isempty(d)
        return
    end

    if length(d)>1
        fprintf('Warning: found multiple prameter log files in experiment directory\n')
    end

    % Make the trial fname
    trial_fname = strrep(d(end).name, '_log', '_trials');
    trial_fname_path = fullfile(filePath, trial_fname);

    % Create header line if the file does not exist
    if exist(trial_fname)
        lineToWrite = '';
    else
        lineToWrite = sprintf('Timestamp,Stim_Index,Laser_state,hardware_triggered\n');
    end

    % Build line
    lineToWrite = sprintf('%s%s,%d,%d,%d\n', ...
        lineToWrite, ...
        datestr(now,'yyyy-mm-dd HH:MM:SS'), ...
        stimIndex, ...
        laserState, ...
        hardwareTriggered);


    % Write the line
    fid = fopen(trial_fname_path,'a');
    fprintf(fid, lineToWrite);
    fclose(fid);




    if nargout>0
        varargout{1}=trial_fname_path;
    end

end % logStimulusParametersToFile
