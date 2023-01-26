function calibrateScanners_Callback(obj)
    % Initiate the proces of calibrating the scanners with the camera
    %
    % zapit.gui.main.controller.calibrateScanners_Callback
    %
    % Purpose
    % The scanners and camera must be calibrated with respect to each other. This
    % method does this. 

    if nargin>1
        % Only set GUI state if the *user* clicked the button
        % rather than than harmonizeGUIstate calling it.
        obj.GUIstate = mfilename;
    end

    if obj.RunScannerCalibrationButton.Value == 1
        obj.RunScannerCalibrationButton.Text = 'CANCEL';
    elseif obj.RunScannerCalibrationButton.Value == 0

        obj.model.breakScannerCalibLoop=true;
        %obj.RunScannerCalibrationButton.Text = {'Run';'Calibration'};
        tidy
        return

    end

    % Prep figure window
    obj.removeOverlays % removes all overlays
    hold(obj.hImAx,'on')

    obj.plotOverlayHandles.(mfilename).hPcurrent = ...
            plot(obj.hImAx,nan,nan, 'or','MarkerSize',14,'LineWidth',3);
    obj.plotOverlayHandles.(mfilename).hPall = ...
            plot(obj.hImAx,nan,nan, 'og','MarkerSize',12,'LineWidth',2);

    hold(obj.hImAx,'off')

    obj.updatePlotListener = addlistener(obj.model, 'calibrateScannersPosData', 'PostSet', @myUpdatePlot);
    % Run calibration method in model


    % Turn on laser and set to the calibration laser power
    obj.LaserPowerScannerCalibSlider.Value = obj.LaserPowerScannerCalibSlider.Value;
    obj.setCalibLaserSwitch('On');

    try
        obj.model.calibrateScanners
    catch ME
        tidy
        rethrow(ME)
    end


    %Finish off and tidy
    tidy



    function tidy
        obj.removeOverlays(mfilename)
        delete(obj.updatePlotListener)
        % Return power to orginal value
        obj.setCalibLaserSwitch('Off');
        obj.RunScannerCalibrationButton.Value = 0;
        obj.RunScannerCalibrationButton.Text = {'Run';'Calibration'};
    end

    function myUpdatePlot(~,~)
        actualCoords = cat(1,obj.model.calibrateScannersPosData(:).actualCoords);

        obj.plotOverlayHandles.(mfilename).hPall.XData = actualCoords(:,1);
        obj.plotOverlayHandles.(mfilename).hPall.YData = actualCoords(:,2);

        obj.plotOverlayHandles.(mfilename).hPcurrent.XData = actualCoords(end,1);
        obj.plotOverlayHandles.(mfilename).hPcurrent.YData = actualCoords(end,2);
    end

end % calibrateScanners_Callback



