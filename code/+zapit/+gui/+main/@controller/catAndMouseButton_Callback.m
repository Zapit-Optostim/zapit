function catAndMouseButton_Callback(obj,~,~)



    if obj.CatMouseButton.Value == 0
        obj.hFig.WindowButtonMotionFcn = [];
        obj.setCalibLaserSwitch('Off');

        % Pointer is back to an arrow
        obj.hFig.Pointer = 'arrow';
    end


    if obj.CatMouseButton.Value == 1
        % Pointer is a hand
        if  obj.CheckCalibrationButton.Value == 1
            obj.CheckCalibrationButton.Value = 0;
            obj.checkScannerCalib_Callback
        end

        if obj.PointModeButton.Value == 1
            obj.PointModeButton.Value = 0;
            obj.pointButton_Callback
        end

        obj.hFig.Pointer = 'hand';
        obj.setCalibLaserSwitch('On');
        obj.hFig.WindowButtonMotionFcn = @mouseMove;
    end



    function mouseMove (~, ~)
        C = get (obj.hImAx, 'CurrentPoint');
        X = round(C(1,1));
        Y = round(C(1,2));


        % Do not go go to locations outside of the axes
        if X<obj.hImAx.XLim(1) && X>obj.hImAx.XLim(2) || ...
            Y>obj.hImAx.YLim(1) && Y>obj.hImAx.YLim(2)
            return
        end

        [xVolts, yVolts] = obj.model.pixelToVolt(X,Y);

        % Update the last clicked position
        obj.hLastPoint.XData = X;
        obj.hLastPoint.YData = Y;
        obj.model.DAQ.moveBeamXY([xVolts, yVolts]);
    end
end


