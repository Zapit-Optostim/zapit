function [settings,allValid] = checkSettingsAreValid(settings)
    % Check that all settings that are read in are valid
    %
    % function [settings,allValid] = checkSettingsAreValid(settings)
    %
    % Purpose
    % Attempt to stop weird errors that could be caused by the user entering a weird setting
    %
    % Rob Campbell - SWC 2023


    allValid=true;

    if ~ischar(settings.NI.device_ID)
        fprintf('NI.device_ID should be a string. Setting it to "%s"\n', DEFAULT_SETTINGS.SYSTEM.ID)
        settings.NI.device_ID = DEFAULT_SETTINGS.SNI.device_ID;
        allValid=false;
    end

    % TODO -- if there are no cell arrays that are supposed to be there, we can replace with a loop
    % Or maybe we can have for some (like the lasers, a min and a max field so all are scalers)
    if iscell(settings.NI.AOchans)
        settings.NI.AOchans = cell2mat(settings.NI.AOchans);
    end

    if iscell(settings.laser.laserMinMaxControlVolts)
        settings.laser.laserMinMaxControlVolts = cell2mat(settings.laser.laserMinMaxControlVolts);
    end

    if iscell(settings.laser.laserMinMax_mW)
        settings.laser.laserMinMax_mW = cell2mat(settings.laser.laserMinMax_mW);
    end

    if ~isnumeric(settings.camera.connection_index)
        fprintf('camera.connection_index should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.camera.connection_index)
        settings.camera.connection_index = DEFAULT_SETTINGS.camera.connection_index;
        allValid=false;
    elseif settings.camera.connection_index<=0
        fprintf('Scamera.connection_index should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.camera.connection_index)
        settings.camera.connection_index = DEFAULT_SETTINGS.camera.connection_index;
        allValid=false;
    end


    if ~isnumeric(settings.camera.default_exposure)
        fprintf('camera.default_exposure should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.camera.default_exposure)
        settings.camera.default_exposure = DEFAULT_SETTINGS.camera.default_exposure;
        allValid=false;
    end


    if ~isnumeric(settings.camera.beam_calib_exposure)
        fprintf('camera.beam_calib_exposure should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.camera.beam_calib_exposure)
        settings.camera.beam_calib_exposure = DEFAULT_SETTINGS.camera.beam_calib_exposure;
        allValid=false;
    end




    if ~allValid
        fprintf('\n ********************************************************************\n')
        fprintf(' * YOU HAVE INVALID VALUES IN %s (see above). \n', settingsFile)
        fprintf(' * They have been replaced with valid defaults. \n')
        fprintf(' **********************************************************************\n')
    end

