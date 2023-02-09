function [settings,setTests] = default_settings
    % Return a set of default system settings to write to a file in the settings directory
    %
    % function default_settings
    %
    % Purpose
    % Defines the default settings of Zapit. These are what are written to YAML when there
    % is no settings file. If the settings file has invalid values, these are corrected with
    % values found here. The function also defines a structure with identical fields but with
    % function handles defining tests for each item. These functions are defined as static
    % methods in the class settingsValuesTests
    %
    % Inputs
    % none
    %
    % Outputs
    % settings - default_settings
    % setTests - structure with tests required for each field as a cell array of function
    %               handles. The functions are static methods of the class settingsValuesTests.
    %
    % Rob Campbell - 2023

    import zapit.settings.settingsValuesTests.*

    %% General
    settings.general.maxSettingsBackUpFiles = 50;  % Default value
    setTests.general.maxSettingsBackUpFiles = {@check_isnumeric, @check_isZeroOrGreaterScalar}; % Tests of the default value

    settings.general.openPythonBridgeOnStartup = 0;
    setTests.general.openPythonBridgeOnStartup = {@check_isLogicalScalar};


    %% NI
    settings.NI.device_ID = 'Dev1';
    setTests.NI.device_ID = {@check_ischar};

    settings.NI.samplesPerSecond = 100000;
    setTests.NI.samplesPerSecond = {@check_isnumeric, @check_isscalar};

    settings.NI.triggerChannel = 'PFI0';
    setTests.NI.triggerChannel = {@check_ischar};

    settings.NI.wrapper = 'dotnet'; % 'vidrio' or 'dotnet'
    setTests.NI.wrapper = {@check_ischar};


    %% Scanners
    settings.scanners.voltsPerPixel = 2.2E-3;
    setTests.scanners.voltsPerPixel = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    settings.scanners.invertXscanner = 0;
    setTests.scanners.invertXscanner = {@check_isLogicalScalar};

    settings.scanners.invertYscanner = 0;
    setTests.scanners.invertYscanner = {@check_isLogicalScalar};


    %% Lasers
    settings.laser.name = 'obis';
    setTests.laser.name = {@check_ischar};

    settings.laser.laserMinMaxControlVolts = [0,5];
    setTests.laser.laserMinMaxControlVolts = {@convert_cell2mat};

    settings.laser.laserMinMax_mW = [0,75];
    setTests.laser.laserMinMax_mW = {@convert_cell2mat};

    settings.laser.maxValueInGUI = 30;
    setTests.laser.maxValueInGUI = {@check_isnumeric, @check_isZeroOrGreaterScalar};


    %% Camera
    settings.camera.connectionIndex = 1;
    setTests.camera.connectionIndex = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    settings.camera.default_exposure = 400;
    setTests.camera.default_exposure = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    settings.camera.micronsPerPixel = 19.3;
    setTests.camera.micronsPerPixel = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    settings.camera.flipImageUD = 0;
    setTests.camera.flipImageUD = {@check_isLogicalScalar};

    settings.camera.flipImageLR = 0;
    setTests.camera.flipImageLR = {@check_isLogicalScalar};


    %% calibrateScanners
    settings.calibrateScanners.areaThreshold = 500;
    setTests.calibrateScanners.areaThreshold = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    settings.calibrateScanners.calibration_power_mW = 10;
    setTests.calibrateScanners.calibration_power_mW = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    settings.calibrateScanners.beam_calib_exposure = 200;
    setTests.calibrateScanners.beam_calib_exposure = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    settings.calibrateScanners.bufferMM = 2;
    setTests.calibrateScanners.bufferMM = {@check_isnumeric, @check_isscalar};

    settings.calibrateScanners.pointSpacingInMM = 2;
    setTests.calibrateScanners.pointSpacingInMM = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    settings.calibrateSample.refAP = 3;
    setTests.calibrateSample.refAP = {@check_isnumeric, @check_isscalar}; % Ideally restrict between -8 and 5


    %% Experiment
    settings.experiment.defaultDutyCycleHz = 40;
    setTests.experiment.defaultDutyCycleHz = {@check_isnumeric, @check_isscalar};

    settings.experiment.defaultLaserPowerMW = 5;
    setTests.experiment.defaultLaserPowerMW = {@check_isnumeric, @check_isscalar};;

    settings.experiment.offRampDownDuration_ms = 250;
    setTests.experiment.offRampDownDuration_ms = {@check_isnumeric, @check_isscalar};

    settings.experiment.maxStimPointsPerCondition = 2;
    setTests.experiment.maxStimPointsPerCondition = {@check_isnumeric, @check_isscalar};

    settings.experiment.blankingTime_ms = 1.5;
    setTests.experiment.blankingTime_ms = {@check_isnumeric, @check_isZeroOrGreaterScalar};


    %% Cache
    settings.cache.ROI = [];
    setTests.cache.ROI = {@convert_cell2mat};

    settings.cache.previouslyLoadedFiles = [];
    setTests.cache.previouslyLoadedFiles = {};

end % default_settings
