function settings = default_settings
    % Return a set of default system settings to write to a file in the settings directory
    %
    % settings = default_settings

    settings.NI.device_ID = 'Dev1';

    settings.camera.connection_index = -1;
    settings.camera.default_exposure = 0;
    settings.camera.beam_calib_exposure = 0;
