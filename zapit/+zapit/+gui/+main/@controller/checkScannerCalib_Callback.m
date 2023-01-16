    function checkScannerCalib_Callback(obj,~,~)
    % Sweep beam over calibration positions to visually check it worked
    %
    % function zapit.gui.main.controller.checkScannerCalib(obj)
    %
    % Purpose
    % This is a callback from a state button so it will run the calibration
    % check continually when depressed and stop when un-pressed


    if obj.CheckCalibrationButton.Value == 1

        if obj.CatMouseButton.Value == 1
            obj.CatMouseButton.Value = 0; % Both can not be activate at the the same time
            obj.catAndMouseButton_Callback;
        end

        if obj.PointModeButton.Value == 1
            obj.PointModeButton.Value = 0;
            obj.pointButton_Callback
        end

        % TODO -- read exposure from spinbox and update settings
        obj.model.cam.exposure = obj.model.settings.calibrateScanners.beam_calib_exposure;

        actualCoords = obj.model.returnScannerCalibTargetCoords;

        % Plot the locations of the grid
        hold(obj.hImAx,'on')

        obj.plotOverlayHandles.(mfilename) = ...
        plot(obj.hImAx,actualCoords(:,1), actualCoords(:,2), 'o', ...
            'MarkerSize', 12, ...
            'LineWidth', 2, ...
            'Color', [0,0.7,0]);

        hold(obj.hImAx,'off')

        % Turn on laser and set to the calibration laser power
        % TODO -- read power from spinbox and update settings
        obj.laserPowerBeforeCalib = obj.LaserPowerScannerCalibSlider.Value;
        obj.LaserPowerScannerCalibSlider.Value = obj.CalibPowerSpinner.Value;
        obj.setCalibLaserSwitch('On');

        % Begin to run through the calibration coords
        obj.model.checkScannerCalibClocked

    elseif obj.CheckCalibrationButton.Value == 0

        obj.model.DAQ.stopAndDeleteAOTask; %Stop

        obj.setCalibLaserSwitch('Off');
        obj.LaserPowerScannerCalibSlider.Value = obj.laserPowerBeforeCalib;

        % Tidy up
        obj.removeOverlays(mfilename)

        % change the illumination of the camera image to high value again
        % TODO -- read exposure from spinbox and update settings
        obj.model.cam.exposure = obj.model.settings.camera.default_exposure;
    end

end % checkScannerCalib_Callback
