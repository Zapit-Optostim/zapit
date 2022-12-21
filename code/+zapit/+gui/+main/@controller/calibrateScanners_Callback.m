function calibrateScanners_Callback(obj,~,~)

    % Prep figure window
    obj.hLastPoint.Visible = 'off';
    obj.PointModeButton.Value = 0;
    hold(obj.hImAx,'on')

    obj.plotOverlayHandles.(mfilename).hPcurrent = ...
            plot(obj.hImAx,nan,nan, 'or','MarkerSize',14,'LineWidth',3);
    obj.plotOverlayHandles.(mfilename).hPall = ...
            plot(obj.hImAx,nan,nan, 'og','MarkerSize',12,'LineWidth',2);

    hold(obj.hImAx,'off')

    updatePlotListener = addlistener(obj.model, 'calibrateScannersPosData', 'PostSet', @myUpdatePlot);
    % Run calibration method in model
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
    end

    function myUpdatePlot(~,~)
        actualPixelCoords = cat(1,obj.model.calibrateScannersPosData(:).actualPixelCoords);

        obj.plotOverlayHandles.(mfilename).hPall.XData = actualPixelCoords(:,1);
        obj.plotOverlayHandles.(mfilename).hPall.YData = actualPixelCoords(:,2);

        obj.plotOverlayHandles.(mfilename).hPcurrent.XData = actualPixelCoords(end,1);
        obj.plotOverlayHandles.(mfilename).hPcurrent.YData = actualPixelCoords(end,2);
    end

end % calibrateScanners_Callback



