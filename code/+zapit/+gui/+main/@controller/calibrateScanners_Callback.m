function calibrateScanners_Callback(obj,~,~)

    % Prep figure window
    obj.PointModeButton.Value = 0;
    hold(obj.hImAx,'on')

    obj.plotOverlayHandles.(mfilename).hPcurrent = ...
            plot(obj.hImAx,nan,nan, 'or','MarkerSize',14,'LineWidth',3);
    obj.plotOverlayHandles.(mfilename).hPall = ...
            plot(obj.hImAx,nan,nan, 'og','MarkerSize',12,'LineWidth',2);

    hold(obj.hImAx,'off')

    updatePlotListener = addlistener(obj.model, 'calibrateScannersPosData', 'PostSet', @myUpdatePlot);
    % Run calibration method in model


    % Turn on laser and set to the calibration laser power
    origLaserPower = obj.LaserPowerScannerCalibSlider.Value;
    obj.LaserPowerScannerCalibSlider.Value = obj.CalibPowerSpinner.Value;
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
        delete(updatePlotListener)
        % Return power to orginal value
        obj.setCalibLaserSwitch('Off');
        obj.LaserPowerScannerCalibSlider.Value = origLaserPower;
    end

    function myUpdatePlot(~,~)
        actualCoords = cat(1,obj.model.calibrateScannersPosData(:).actualCoords);

        obj.plotOverlayHandles.(mfilename).hPall.XData = actualCoords(:,1);
        obj.plotOverlayHandles.(mfilename).hPall.YData = actualCoords(:,2);

        obj.plotOverlayHandles.(mfilename).hPcurrent.XData = actualCoords(end,1);
        obj.plotOverlayHandles.(mfilename).hPcurrent.YData = actualCoords(end,2);
    end

end % calibrateScanners_Callback



