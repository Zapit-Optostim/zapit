function runThroughAllStimPointsWithLogging
    % Demo showing how to present stimuli and also log which locations wwere presented.
    %
    % function runThroughAllStimPointsWithLogging
    %
    % Purpose
    % Create a folder called 'zapit_logging_demo' on the Desktop and run a mini experiment.
    % add log files to the folder. If the folder already exists we just add log files to it
    % and only delete existing log files.
    %
    % Inputs
    % none
    %
    % Outputs
    % none
    %
    % Rob Campbell - SWC 2023


    % Get the API object from the base workspace
    hZP = zapit.utils.getObject;
    if isempty(hZP)
        return
    end


    if hZP.isReadyToStim == false
        fprintf('Zapit is not ready to stimulate.\n')
        return
    end

    % Make log folder
    logFolder = fullfile(zapit.utils.getDesktopPath,'zapit_logging_demo');
    if ~exist(logFolder,'dir')
        mkdir(logFolder);
    end

    % Delete existing log files
    logFiles = dir(fullfile(logFolder,'zapit_*__*.yml'));
    for ii=1:length(logFiles)
        delete(fullfile(logFiles(ii).folder, logFiles(ii).name))
    end

    % Set this as the experiment folder
    hZP.experimentPath = logFolder;
    stimDuration = 0.25;
    nStimuli = 5;

    for ii = 1:nStimuli
        hZP.sendSamples('hardwareTriggered', false) % Starts a random stimulus right away
        pause(stimDuration)
        hZP.stopOptoStim
        pause(0.3) % Because of https://github.com/Zapit-Optostim/zapit/issues/102
    end

    % Stop logging to the folder
    hZP.clearExperimentPath


end % runThroughAllStimPoints
