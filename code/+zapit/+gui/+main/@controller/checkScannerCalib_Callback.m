function checkScannerCalib_Callback(obj,~,~)
% Sweep beam over calibration positions to visually check it worked
%
%    function checkScannerCalib(obj)

    % This is a callback from a state button so it will run the calibration
    % check continually when depressed and stop when un-pressed

    if obj.CheckCalibrationButton.Value == 1
        % We start to run through the points

        obj.PointModeButton.Value = 0;

        % TODO -- read exposure from spinbox and update settings
        obj.model.cam.exposure = obj.model.settings.calibrateScanners.beam_calib_exposure;

        actualPixelCoords = obj.model.returnScannerCalibTargetCoords;

        % Plot the locations of the grid
        hold(obj.hImAx,'on')

        obj.plotOverlayHandles.(mfilename) = ...
        plot(obj.hImAx,actualPixelCoords(:,1), actualPixelCoords(:,2), 'o', ...
            'MarkerSize', 12, ...
            'LineWidth', 2, ...
            'Color', [0,0.7,0]);

        hold(obj.hImAx,'off')


        % Cycle beam
        % TODO -- try setting up a task and having the beam scan through all points fast or maybe
        % line by line. I'm wondering whether, with the right params, all points will appear to
        % illuminate at once. That would nice!

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

end
