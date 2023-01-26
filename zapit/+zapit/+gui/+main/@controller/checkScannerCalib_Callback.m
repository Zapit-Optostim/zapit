    function checkScannerCalib_Callback(obj,~,~)
    % Sweep beam over calibration positions to visually check it worked
    %
    % function zapit.gui.main.controller.checkScannerCalib(obj)
    %
    % Purpose
    % This is a callback from a state button so it will run the calibration
    % check continually when depressed and stop when un-pressed

    if nargin>1
        % Only set GUI state if the *user* clicked the button
        % rather than than harmonizeGUIstate calling it.
        obj.GUIstate = mfilename;
    end

    if obj.CheckCalibrationButton.Value == 1

        actualCoords = obj.model.returnScannerCalibTargetCoords;

        % Plot the locations of the grid
        hold(obj.hImAx,'on')

        obj.plotOverlayHandles.(mfilename) = ...
        plot(obj.hImAx,actualCoords(:,1), actualCoords(:,2), 'o', ...
            'MarkerSize', 12, ...
            'LineWidth', 2, ...
            'Color', [0,0.7,0]);

        hold(obj.hImAx,'off')

        % Turn on laser and set to the calibration laser power. Ditto for camera exposure
        % TODO -- this should maybe be done in zapit.pointer.checkScannerCalibClocked (TODO there)
        obj.model.cam.exposure = obj.model.settings.calibrateScanners.beam_calib_exposure;
        obj.setCalibLaserSwitch('On');

        % Begin to run through the calibration coords
        obj.model.checkScannerCalibClocked

    elseif obj.CheckCalibrationButton.Value == 0

        obj.model.DAQ.stopAndDeleteAOTask; %Stop

        obj.setCalibLaserSwitch('Off');

        % Tidy up
        obj.removeOverlays(mfilename)

        % change the illumination of the camera image to high value again
        obj.model.cam.exposure = obj.model.settings.camera.default_exposure;
    end

end % checkScannerCalib_Callback
