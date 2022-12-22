function checkScannerCalib_Callback(obj,~,~)
% Sweep beam over calibration positions to visually check it worked
%
%    function checkScannerCalib(obj)

   obj.PointModeButton.Value = 0;
   % TODO -- read exposure from spinbox and update settings
    obj.model.cam.exposure = obj.model.settings.calibrateScanners.beam_calib_exposure;

    actualPixelCoords = cat(1,obj.model.calibrateScannersPosData(:).actualPixelCoords);

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
    origLaserPower = obj.LaserPowerScannerCalibSlider.Value;
    obj.LaserPowerScannerCalibSlider.Value = obj.CalibPowerSpinner.Value;
    obj.setCalibLaserSwitch('On');

    for ii=1:size(actualPixelCoords,1)
        [xVolt,yVolt] = obj.model.pixelToVolt(actualPixelCoords(ii,1),...
                 actualPixelCoords(ii,2));
        obj.model.DAQ.moveBeamXY([xVolt,yVolt])
        pause(0.05)
    end

    obj.setCalibLaserSwitch('Off');
    obj.LaserPowerScannerCalibSlider.Value = origLaserPower;

    % Tidy up
    obj.removeOverlays(mfilename)

    % change the illumination of the camera image to high value again
    % TODO -- read exposure from spinbox and update settings
    obj.model.cam.exposure = obj.model.settings.camera.default_exposure;

