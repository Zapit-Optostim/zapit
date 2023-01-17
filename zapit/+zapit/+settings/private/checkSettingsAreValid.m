function [settings,allValid] = checkSettingsAreValid(settings)
    % Check that all settings that are read in are valid
    %
    % function [settings,allValid] = checkSettingsAreValid(settings)
    %
    % Purpose
    % Attempt to stop weird errors that could be caused by the user entering a weird setting.
    % This function *also* converts some values from cells to vectors, as this is happens
    % when they are read in from the YAML. Consequently, this function must be run after data 
    % are read in!
    %
    %
    % Rob Campbell - SWC 2023


    DEFAULT_SETTINGS = default_settings;
    allValid=true;


    %% 
    %
    % general settings

    if ~isnumeric(settings.general.maxSettingsBackUpFiles)
        fprintf('general.maxSettingsBackUpFiles should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.general.maxSettingsBackUpFiles)
        settings.general.maxSettingsBackUpFiles = DEFAULT_SETTINGS.general.maxSettingsBackUpFiles;
        allValid=false;
    elseif settings.general.maxSettingsBackUpFiles <= 0 
        fprintf('general.maxSettingsBackUpFiles should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.general.maxSettingsBackUpFiles)
        settings.general.maxSettingsBackUpFiles = DEFAULT_SETTINGS.general.maxSettingsBackUpFiles;
        allValid=false;
    end


    %% 
    %
    % hardware DAQ (NI) settings

    if ~ischar(settings.NI.device_ID)
        fprintf('NI.device_ID should be a string. Setting it to "%s"\n', DEFAULT_SETTINGS.NI.device_ID)
        settings.NI.device_ID = DEFAULT_SETTINGS.NI.device_ID;
        allValid=false;
    end


    if ~isnumeric(settings.NI.samplesPerSecond)
        fprintf('NI.samplesPerSecond should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.NI.samplesPerSecond)
        settings.NI.samplesPerSecond = DEFAULT_SETTINGS.NI.samplesPerSecond;
        allValid=false;
    elseif settings.NI.samplesPerSecond <= 0 
        fprintf('NI.samplesPerSecond should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.NI.samplesPerSecond)
        settings.NI.samplesPerSecond = DEFAULT_SETTINGS.NI.samplesPerSecond;
        allValid=false;
    end


    if ~isnumeric(settings.NI.AOrange)
        fprintf('NI.AOrange should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.NI.AOrange)
        settings.NI.AOrange = DEFAULT_SETTINGS.NI.AOrange;
        allValid=false;
    elseif settings.NI.AOrange <= 0 
        fprintf('NI.AOrange should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.NI.AOrange)
        settings.NI.AOrange = DEFAULT_SETTINGS.NI.AOrange;
        allValid=false;
    end


    if iscell(settings.NI.AOchans)
        settings.NI.AOchans = cell2mat(settings.NI.AOchans);
    end


    if ~ischar(settings.NI.triggerChannel)
        fprintf('NI.triggerChannel should be a string. Setting it to "%s"\n', DEFAULT_SETTINGS.NI.triggerChannel)
        settings.NI.triggerChannel = DEFAULT_SETTINGS.NI.triggerChannel;
        allValid=false;
    end


    %%
    %
    % scanners

    if ~isnumeric(settings.scanners.voltsPerPixel)
        fprintf('NI.samplesPerSecond should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.scanners.voltsPerPixel)
        settings.scanners.voltsPerPixel = DEFAULT_SETTINGS.scanners.voltsPerPixel;
        allValid=false;
    elseif settings.scanners.voltsPerPixel <= 0 
        fprintf('scanners.voltsPerPixel should be >0. Setting it to default value\n')
        settings.scanners.voltsPerPixel = DEFAULT_SETTINGS.scanners.voltsPerPixel;
        allValid=false;
    end


    %%
    %
    % laser

    if ~ischar(settings.laser.name)
        fprintf('laser.name should be a string. Setting it to "%s"\n', DEFAULT_SETTINGS.laser.name)
        settings.laser.name = DEFAULT_SETTINGS.laser.name;
        allValid=false;
    end


    if iscell(settings.laser.laserMinMaxControlVolts)
        settings.laser.laserMinMaxControlVolts = cell2mat(settings.laser.laserMinMaxControlVolts);
    end


    if iscell(settings.laser.laserMinMax_mW)
        settings.laser.laserMinMax_mW = cell2mat(settings.laser.laserMinMax_mW);
    end



    %%
    %
    % camera

    if ~isnumeric(settings.camera.connection_index)
        fprintf('camera.connection_index should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.camera.connection_index)
        settings.camera.connection_index = DEFAULT_SETTINGS.camera.connection_index;
        allValid=false;
    elseif settings.camera.connection_index<=0
        fprintf('camera.connection_index should be >0. Setting it to %d \n', ...
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


    if ~isnumeric(settings.camera.micronsPerPixel)
        fprintf('camera.micronsPerPixel should be a number. Setting it to %0.3f \n', ...
            DEFAULT_SETTINGS.camera.micronsPerPixel)
        settings.camera.micronsPerPixel = DEFAULT_SETTINGS.camera.micronsPerPixel;
        allValid=false;
    elseif settings.camera.micronsPerPixel<=0
        fprintf('camera.micronsPerPixel should be >0. Setting it to %0.3f \n', ...
            DEFAULT_SETTINGS.camera.micronsPerPixel)
        settings.camera.micronsPerPixel = DEFAULT_SETTINGS.camera.micronsPerPixel;
        allValid=false;
    end


    %%
    %
    % calibrateScanners

    if ~isnumeric(settings.calibrateScanners.areaThreshold)
        fprintf('calibrateScanners.areaThreshold should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.areaThreshold)
        settings.calibrateScanners.areaThreshold = DEFAULT_SETTINGS.calibrateScanners.areaThreshold;
        allValid=false;
    elseif settings.calibrateScanners.areaThreshold<=0
        fprintf('calibrateScanners.areaThreshold should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.areaThreshold)
        settings.calibrateScanners.areaThreshold = DEFAULT_SETTINGS.calibrateScanners.areaThreshold;
        allValid=false;
    end


    if ~isnumeric(settings.calibrateScanners.calibration_power_mW)
        fprintf('calibrateScanners.calibration_power_mW should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.calibration_power_mW)
        settings.calibrateScanners.calibration_power_mW = DEFAULT_SETTINGS.calibrateScanners.calibration_power_mW;
        allValid=false;
    elseif settings.calibrateScanners.calibration_power_mW<=0
        fprintf('calibrateScanners.calibration_power_mW should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.calibration_power_mW)
        settings.calibrateScanners.calibration_power_mW = DEFAULT_SETTINGS.calibrateScanners.calibration_power_mW;
        allValid=false;
    end


    if ~isnumeric(settings.calibrateScanners.beam_calib_exposure)
        fprintf('calibrateScanners.beam_calib_exposure should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.beam_calib_exposure)
        settings.calibrateScanners.beam_calib_exposure = DEFAULT_SETTINGS.calibrateScanners.beam_calib_exposure;
        allValid=false;
    elseif settings.calibrateScanners.beam_calib_exposure<=0
        fprintf('calibrateScanners.beam_calib_exposure should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.beam_calib_exposure)
        settings.calibrateScanners.beam_calib_exposure = DEFAULT_SETTINGS.calibrateScanners.beam_calib_exposure;
        allValid=false;
    end


    if ~isnumeric(settings.calibrateScanners.bufferPixels)
        fprintf('calibrateScanners.bufferPixels should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.bufferPixels)
        settings.calibrateScanners.bufferPixels = DEFAULT_SETTINGS.calibrateScanners.bufferPixels;
        allValid=false;
    elseif settings.calibrateScanners.bufferPixels<=0
        fprintf('calibrateScanners.bufferPixels should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.bufferPixels)
        settings.calibrateScanners.bufferPixels = DEFAULT_SETTINGS.calibrateScanners.bufferPixels;
        allValid=false;
    end


    if ~isnumeric(settings.calibrateScanners.pointSpacingInPixels)
        fprintf('calibrateScanners.pointSpacingInPixels should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.pointSpacingInPixels)
        settings.calibrateScanners.pointSpacingInPixels = DEFAULT_SETTINGS.calibrateScanners.pointSpacingInPixels;
        allValid=false;
    elseif settings.calibrateScanners.pointSpacingInPixels<=0
        fprintf('calibrateScanners.pointSpacingInPixels should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateScanners.pointSpacingInPixels)
        settings.calibrateScanners.pointSpacingInPixels = DEFAULT_SETTINGS.calibrateScanners.pointSpacingInPixels;
        allValid=false;
    end


    %%
    %
    % calibrateSample

    if ~isnumeric(settings.calibrateSample.refAP)
        fprintf('calibrateSample.refAP should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateSample.refAP)
        settings.calibrateSample.refAP = DEFAULT_SETTINGS.calibrateSample.refAP;
        allValid=false;
    elseif settings.calibrateSample.refAP<=0
        fprintf('calibrateSample.refAP should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.calibrateSample.refAP)
        settings.calibrateSample.refAP = DEFAULT_SETTINGS.calibrateSample.refAP;
        allValid=false;
    end

    %%
    %
    % experiment

    if ~isnumeric(settings.experiment.defaultLaserFrequencyHz)
        fprintf('experiment.defaultLaserFrequencyHzd should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.experiment.defaultLaserFrequencyHz)
        settings.experiment.defaultLaserFrequencyHz = DEFAULT_SETTINGS.experiment.defaultLaserFrequencyHz;
        allValid=false;
    elseif settings.experiment.defaultLaserFrequencyHz<=0
        fprintf('experiment.defaultLaserFrequencyHz should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.experiment.defaultLaserFrequencyHz)
        settings.experiment.defaultLaserFrequencyHz = DEFAULT_SETTINGS.experiment.defaultLaserFrequencyHz;
        allValid=false;
    end


    if ~isnumeric(settings.experiment.defaultLaserPowerMW)
        fprintf('experiment.defaultLaserPowerMW should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.experiment.defaultLaserPowerMW)
        settings.experiment.defaultLaserPowerMW = DEFAULT_SETTINGS.experiment.defaultLaserPowerMW;
        allValid=false;
    elseif settings.experiment.defaultLaserPowerMW<=0
        fprintf('experiment.defaultLaserPowerMW should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.experiment.defaultLaserPowerMW)
        settings.experiment.defaultLaserPowerMW = DEFAULT_SETTINGS.experiment.defaultLaserPowerMW;
        allValid=false;
    end


    if ~isnumeric(settings.experiment.maxStimPointsPerCondition)
        fprintf('experiment.maxStimPointsPerCondition should be a number. Setting it to %d \n', ...
            DEFAULT_SETTINGS.experiment.maxStimPointsPerCondition)
        settings.experiment.maxStimPointsPerCondition = DEFAULT_SETTINGS.experiment.maxStimPointsPerCondition;
        allValid=false;
    elseif settings.experiment.maxStimPointsPerCondition<=0
        fprintf('experiment.maxStimPointsPerCondition should be >0. Setting it to %d \n', ...
            DEFAULT_SETTINGS.experiment.maxStimPointsPerCondition)
        settings.experiment.maxStimPointsPerCondition = DEFAULT_SETTINGS.experiment.maxStimPointsPerCondition;
        allValid=false;
    end

