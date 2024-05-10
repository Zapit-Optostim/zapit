function [settings,setTests] = default_settings
    % Return a set of default system settings to write to a file in the settings directory
    %
    % function [settings, setTests] = zapit.settings.default_settings
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


    % Import the functions we use for checking that stuff is valid
    import zapit.settings.settingsValuesTests.*


    %% NOTE!
    % In each case, every default setting value is defined on the first line then a test for its validity
    % is on the line after it.


    %% General
    settings.general.maxSettingsBackUpFiles = 50;  % Default value
    setTests.general.maxSettingsBackUpFiles = {@check_isnumeric, @check_isZeroOrGreaterScalar}; % Tests of the default value

    settings.general.openPythonBridgeOnStartup = 0; % Default value
    setTests.general.openPythonBridgeOnStartup = {@check_isLogicalScalar}; % Tests of the default value (same for each below)


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
    settings.experiment.defaultLaserModulationFrequencyHz = 40;
    setTests.experiment.defaultLaserModulationFrequencyHz = {@check_isnumeric, @check_isscalar};

    settings.experiment.defaultLaserPowerMW = 5;
    setTests.experiment.defaultLaserPowerMW = {@check_isnumeric, @check_isscalar};;

    settings.experiment.offRampDownDuration_ms = 250;
    setTests.experiment.offRampDownDuration_ms = {@check_isnumeric, @check_isscalar};

    settings.experiment.maxStimPointsPerCondition = 2;
    setTests.experiment.maxStimPointsPerCondition = {@check_isnumeric, @check_isscalar};

    % The following settings should provide minimum blanking time for Saturn 5 scanners
    % ThorLabs scanners are slower and will need larger numbers.
    settings.experiment.blankingTime_ms = 0.3;
    setTests.experiment.blankingTime_ms = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    % A positive value of blankOnsetShift_ms shifts the onset of the blanking time earlier.
    % Negative shifts it later. We shift it later because of the lag of the scanners
    settings.experiment.blankOnsetShift_ms = -0.12;
    setTests.experiment.blankOnsetShift_ms = {@check_isnumeric, @check_isscalar};

    % A positive value of blankOffsetShift_ms shifts the offset of the blanking time later.
    settings.experiment.blankOffsetShift_ms = 0.25;
    setTests.experiment.blankOffsetShift_ms = {@check_isnumeric, @check_isscalar};


    % The TCP/IP server
    settings.tcpServer.IP = 'localhost'; % This will need changing
    setTests.tcpServer.IP = {@check_isIPaddress};

    settings.tcpServer.port = 1488; % This can be left
    setTests.tcpServer.port = {@check_isnumeric, @check_isZeroOrGreaterScalar};

    settings.tcpServer.enable = false;
    setTests.tcpServer.enable = {@check_isLogicalScalar};



    %% Cache
    settings.cache.ROI = [];
    setTests.cache.ROI = {@convert_cell2mat};

    settings.cache.previouslyLoadedFiles = [];
    setTests.cache.previouslyLoadedFiles = {};

end % default_settings
