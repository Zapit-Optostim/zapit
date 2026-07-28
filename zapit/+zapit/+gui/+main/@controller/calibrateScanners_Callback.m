function calibrateScanners_Callback(obj,~,~)
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

        obj.model.breakPointingAccuracyLoop=true;
        %obj.RunScannerCalibrationButton.Text = {'Run';'Calibration'};
        tidy
        return

    end

    % Remove any listener left over from a previous run before doing anything else.
    % Normally "tidy" has already done this, but if an earlier run threw before reaching it
    % the old listener would survive: it stays attached to calibrateScannersPosData for the
    % life of the model, holds a closure over obj, and fires on every subsequent calibration
    % against overlay handles that have since been deleted. This must happen before the
    % figure prep below, since that is the part most likely to throw.
    clearUpdatePlotListener

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



    function clearUpdatePlotListener
        % Delete the calibration plot-update listener, if there is one, and drop the handle
        if ~isempty(obj.updatePlotListener) && isvalid(obj.updatePlotListener)
            delete(obj.updatePlotListener)
        end
        obj.updatePlotListener = [];
    end

    function tidy
        obj.removeOverlays(mfilename)
        clearUpdatePlotListener
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



