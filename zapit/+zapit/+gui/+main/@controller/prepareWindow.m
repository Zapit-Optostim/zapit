function prepareWindow(obj)
    % Prepare the window
    %
    % zapit.gui.main.controller.prepareWindow
    %
    % Purpose
    % Set up the figure window, attach callbacks and listeners, etc.
    %
    %
    % Rob Campbell - SWC 2023

    % Insert and empty image into axes.
    obj.refreshImage


    %Make the GUI resizable on small screens
    sSize = get(0,'ScreenSize');
    if sSize(4)<=900
        obj.hFig.Resize='on';
    end

    % Call the class destructor when figure is closed. This ensures all
    % the hardware tasks are stopped.
    obj.hFig.CloseRequestFcn = @obj.delete;

    % Set the figure title to reflect the version number
    zv = zapit.version;
    obj.hFig.Name = ['Zapit v', zv.version.string];


    % Update elements from settings file
    % TODO: changing the settings spin boxes should change the settings file
    obj.CalibPowerSpinner.Value = obj.model.settings.calibrateScanners.calibration_power_mW;
    obj.LaserPowerScannerCalibSlider.Value = obj.CalibPowerSpinner.Value;
    obj.PointSpacingSpinner.Value = obj.model.settings.calibrateScanners.pointSpacingInPixels;
    obj.BorderBufferSpinner.Value = obj.model.settings.calibrateScanners.bufferPixels;
    obj.SizeThreshSpinner.Value = obj.model.settings.calibrateScanners.areaThreshold;
    obj.CalibExposureSpinner.Value = obj.model.settings.calibrateScanners.beam_calib_exposure;


    % Disable the reference AP dropdown
    obj.RefAPDropDown.Enable='off';
    obj.TestSiteDropDown.Items={}; % Nothing loaded yet...


    % Set up callback functions

    % Calibrate Scanners Tab
    obj.ResetROIButton.ButtonPushedFcn = @(~,~) obj.resetROI_Callback;
    obj.ROIButton.ButtonPushedFcn = @(~,~) obj.drawROI_Callback;
    obj.RunScannerCalibrationButton.ButtonPushedFcn = @(~,~) obj.calibrateScanners_Callback;
    obj.CheckCalibrationButton.ValueChangedFcn = @(~,~) obj.checkScannerCalib_Callback;
    obj.PointModeButton.ValueChangedFcn = @(~,~) obj.pointButton_Callback;
    obj.CatMouseButton.ValueChangedFcn = @(~,~) obj.catAndMouseButton_Callback;
    obj.LaserPowerScannerCalibSlider.ValueChangedFcn = @(src,evt) obj.setLaserPower_Callback(src,evt);
    obj.CalibLaserSwitch.ValueChangedFcn = @(~,~) obj.switchLaser_Callback;
    obj.CalibPowerSpinner.ValueChangedFcn = @(~,~) obj.calibPowerSpinner_CallBack;
    obj.CalibExposureSpinner.ValueChangedFcn = @(~,~) obj.calibExposureSpinner_CallBack;
    obj.PointSpacingSpinner.ValueChangedFcn = @(~,~) obj.pointSpacing_CallBack;
    obj.BorderBufferSpinner.ValueChangedFcn = @(~,~) obj.borderBuffer_CallBack;
    obj.SizeThreshSpinner.ValueChangedFcn = @(~,~) obj.sizeThreshSpinner_CallBack;

    % Calibrate Sample Tab
    obj.CalibrateSampleButton.ButtonPushedFcn = @(~,~) obj.calibrateSample_Callback;
    obj.PaintbrainborderButton.ValueChangedFcn = @(~,~) obj.paintBrainBorder_Callback;
    obj.OverlaystimsitesButton.ValueChangedFcn = @(~,~) obj.overlayStimSites_Callback;
    obj.ZapallcoordsButton.ValueChangedFcn = @(~,~) obj.zapAllCoords_Callback;
    obj.ZapSiteButton.ValueChangedFcn = @(~,~) obj.zapSite_Callback;
    obj.PaintareaButton.Enable = 'off'; % DISABLE UNTIL THIS WORKS
    %obj.PaintareaButton.ValueChangedFcn = @(~,~) obj.paintArea_Callback;

    obj.ExportwaveformsButton.ButtonPushedFcn = @(~,~) obj.exportWaveforms_Callback;
    obj.SetexperimentpathButton.ButtonPushedFcn = @(~,~) obj.setExperimentPath_Callback;
    obj.ClearpathButton.ButtonPushedFcn = @(~,~) obj.clearExperimentPath_Callback;



    % This callback runs when the tab is changed. This is to ensure that the GUI is
    % tidied in any relevant ways when switching to a new tab
    obj.TabGroup.SelectionChangedFcn = @(src,~) obj.tabChange_Callback(src);

    % Menus
    obj.NewstimconfigMenu.MenuSelectedFcn = @(~,~) obj.createNewStimConfig_Callback;
    obj.LoadstimconfigMenu.MenuSelectedFcn = @(src,~) obj.loadStimConfig_Callback(src);
    obj.FileMenu.MenuSelectedFcn = @(~,~) obj.removeMissingRecentConfigs; % So menu updates if files change
    obj.FileGitHubissueMenu.MenuSelectedFcn = @(~,~) web('https://github.com/BaselLaserMouse/zapit/issues');
    obj.GeneratesupportreportMenu.MenuSelectedFcn = @(~,~) zapit.utils.generateSupportReport;


    % Set GUI state based on calibration state (TODO -- these two aren't actually asigned as a callback anywhere)
    obj.scannersCalibrateCallback
    obj.sampleCalibrateCallback

    % If in simulated mode, disable UI elements that are not functional right now
    if obj.model.simulated
        obj.RunScannerCalibrationButton.Enable = 'off';
        obj.PointModeButton.Enable = 'off';
        obj.CatMouseButton.Enable = 'off';
        obj.PaintbrainborderButton.Enable = 'off';
        obj.ZapallcoordsButton.Enable = 'off';
        obj.ZapSiteButton.Enable = 'off';
    end

end
