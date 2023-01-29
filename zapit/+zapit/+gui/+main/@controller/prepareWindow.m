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
    obj.LaserPowerScannerCalibSlider.Value = obj.model.settings.calibrateScanners.calibration_power_mW;
    obj.LaserPowerScannerCalibSlider.Limits = [0, obj.model.settings.laser.maxValueInGUI];
    obj.PointSpacingSpinner.Value = obj.model.settings.calibrateScanners.pointSpacingInMM;
    obj.BorderBufferSpinner.Value = obj.model.settings.calibrateScanners.bufferMM;
    obj.SizeThreshSpinner.Value = obj.model.settings.calibrateScanners.areaThreshold;
    obj.StandardExposure.Value = obj.model.settings.camera.default_exposure;
    obj.StandardExposure.Limits = [0,inf];
    obj.CalibExposureSpinner.Value = obj.model.settings.calibrateScanners.beam_calib_exposure;
    obj.CalibExposureSpinner.Limits = [0,inf];

    % Disable the reference AP dropdown
    AP = [5:-1:2, -2:-1:-8];
    obj.RefAPDropDown.Items = arrayfun(@(x) sprintf('%+d mm',x),AP,'UniformOutput',false);
    obj.RefAPDropDown.Value = sprintf('%+d mm',round(obj.model.settings.calibrateSample.refAP));
    obj.RefAPDropDown.ValueChangedFcn = @obj.refAPDropDown_Callback;

    obj.TestSiteDropDown.Items={}; % Nothing loaded yet...


    % Set up callback functions and other settings

    % Calibrate Scanners Tab
    % Note: see zapit.gui.main.controller.harmonizeGUIstate to understand how callbacks interact.
    obj.StandardExposure.ValueChangedFcn = @obj.setCamExposure_Callback;
    obj.ResetROIButton.ButtonPushedFcn = @obj.resetROI_Callback;
    obj.ROIButton.ButtonPushedFcn = @obj.drawROI_Callback;
    obj.RunScannerCalibrationButton.ValueChangedFcn = @obj.calibrateScanners_Callback;
    obj.CheckCalibrationButton.ValueChangedFcn = @obj.checkScannerCalib_Callback;
    obj.PointModeButton.ValueChangedFcn = @obj.pointButton_Callback;
    obj.CatMouseButton.ValueChangedFcn = @obj.catAndMouseButton_Callback;
    obj.LaserPowerScannerCalibSlider.ValueChangedFcn = @obj.setLaserPower_Callback;
    obj.CalibLaserSwitch.ValueChangedFcn = @obj.switchLaser_Callback;
    obj.CalibExposureSpinner.ValueChangedFcn = @obj.calibExposureSpinner_CallBack;
    obj.PointSpacingSpinner.ValueChangedFcn = @obj.pointSpacing_CallBack;
    obj.BorderBufferSpinner.ValueChangedFcn = @obj.borderBuffer_CallBack;
    obj.SizeThreshSpinner.ValueChangedFcn = @obj.sizeThreshSpinner_CallBack;

    % Calibrate Sample Tab
    obj.CalibrateSampleButton.ButtonPushedFcn = @obj.calibrateSample_Callback;
    obj.PaintbrainborderButton.ValueChangedFcn = @obj.paintBrainBorder_Callback;
    obj.OverlaystimsitesButton.ValueChangedFcn = @obj.overlayStimSites_Callback;
    obj.ZapallcoordsButton.ValueChangedFcn = @obj.zapAllCoords_Callback;
    obj.ZapSiteButton.ValueChangedFcn = @obj.zapSite_Callback;
    obj.PlotstimcoordsButton.ButtonPushedFcn = @(~,~) zapit.utils.plotStimuli(obj.model.stimConfig);
    obj.PaintareaButton.ValueChangedFcn = @obj.paintArea_Callback;

    obj.ExportwaveformsButton.ButtonPushedFcn = @obj.exportWaveforms_Callback;
    obj.SetexperimentpathButton.ButtonPushedFcn = @obj.setExperimentPath_Callback;
    obj.ClearpathButton.ButtonPushedFcn = @obj.clearExperimentPath_Callback;



    % This callback runs when the tab is changed. This is to ensure that the GUI is
    % tidied in any relevant ways when switching to a new tab
    obj.TabGroup.SelectionChangedFcn = @obj.tabChange_Callback;

    % Menus
    obj.NewstimconfigMenu.MenuSelectedFcn = @obj.createNewStimConfig_Callback;
    obj.LoadstimconfigMenu.MenuSelectedFcn = @obj.loadStimConfig_Callback;
    obj.FileMenu.MenuSelectedFcn = @obj.removeMissingRecentConfigs; % So menu updates if files change
    obj.FileGitHubissueMenu.MenuSelectedFcn = @(~,~) web('https://github.com/BaselLaserMouse/zapit/issues');
    obj.GeneratesupportreportMenu.MenuSelectedFcn = @zapit.utils.generateSupportReport;


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
