function settings = default_settings
    % Return a set of default system settings to write to a file in the settings directory
    %
    % settings = default_settings

    settings.NI.device_ID = 'Dev1';
    settings.NI.samplesPerSecond = 10000;
    settings.NI.AOrange = 10;
    settings.NI.AOchans = 0:2;
    settings.NI.triggerChannel = 'PFI0';

    settings.scanners.voltsPerPixel = 2.2E-3; %TODO -- replace with a different number

    settiings.laser.laserMinMaxControlVolts = [1.5,3.5]; %TODO -- replace with a different number
    settings.laser.laserMinMax_mW = [0,100]; %TODO -- replace with a different number

    settings.camera.connection_index = -1;
    settings.camera.default_exposure = 0;
    settings.camera.beam_calib_exposure = 0;
    settings.camera.micronsPerPixel = 19.3; %TODO -- replace with a different number


    settings.calibrateScanners.areaThreshold = 500;
    settings.calibrateScanners.calibration_power_mW = 10;
    settings.calibrateScanners.beam_calib_exposure = 0;
end % default_settings
