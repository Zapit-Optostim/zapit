function pointButton_Callback(obj,~,~)
    % Run on press of the Point button
    %
    % zapit.gui.main.controller.pointButton_Callback

    if nargin>1
        % Only set GUI state if the *user* clicked the button
        % rather than than harmonizeGUIstate calling it.
        obj.GUIstate = mfilename;
    end

    % Switch back and forth between click and point mode
    if obj.PointModeButton.Value == 1
        % Entering point mode

        if  obj.CheckCalibrationButton.Value == 1
            obj.CheckCalibrationButton.Value = 0;
            obj.checkScannerCalib_Callback
        end

        % Pointer is a hand
        obj.hFig.Pointer = 'hand';
        obj.addLastPointLocationMarker

        % Turn on laser
        obj.setCalibLaserSwitch('On');
        obj.hImLive.ButtonDownFcn = @obj.pointBeamToLocationInImage;

    elseif obj.PointModeButton.Value == 0
        % Leaving point mode

        % Pointer is back to an arrow
        obj.hFig.Pointer = 'arrow';

        % Turn off laser
        obj.setCalibLaserSwitch('Off');

        obj.hImLive.ButtonDownFcn = [];
        obj.removeOverlays('hLastPoint')
        obj.removeOverlays('hLastDetectedLaserPos')
    end

end
