function catAndMouseButton_Callback(obj,~,~)


    % Both can not be activate at the the same time
    if obj.CatMouseButton.Value == 0
        obj.hFig.WindowButtonMotionFcn = [];
        obj.setCalibLaserSwitch('Off');
    end

    if obj.CatMouseButton.Value == 1
        obj.setCalibLaserSwitch('On');
        obj.PointModeButton.Value = 0;
        obj.hFig.WindowButtonMotionFcn = @mouseMove;
    end



    function mouseMove (object, eventdata)
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


