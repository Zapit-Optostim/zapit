function catAndMouseButton_Callback(obj,~,~)
    % Causes the laser beam to follow the mouse cursor around the screen
    %
    % zapit.gui.main.controller.catAndMouseButton_Callback
    %
    % Purpose
    % None whatsoever
    %
    % Rob Campbell - SWC 2022

    if nargin>1
        % Only set GUI state if the *user* clicked the button
        % rather than than harmonizeGUIstate calling it.
        obj.GUIstate = mfilename;
    end

    if obj.CatMouseButton.Value == 0
        obj.hFig.WindowButtonMotionFcn = [];
        obj.setCalibLaserSwitch('Off');
        obj.removeOverlays('hLastPoint')
        % Pointer is back to an arrow
        obj.hFig.Pointer = 'arrow';
    end


    if obj.CatMouseButton.Value == 1
        obj.hFig.Pointer = 'hand';
        obj.setCalibLaserSwitch('On');
        obj.addLastPointLocationMarker % adds hLastPoint
        obj.hFig.WindowButtonMotionFcn = @mouseMove;
    end



    function mouseMove (~, ~)
        C = get (obj.hImAx, 'CurrentPoint');
        X = C(1,1);
        Y = C(1,2);

        % Do not go go to locations outside of the axes
        if X<obj.hImAx.XLim(1) && X>obj.hImAx.XLim(2) || ...
            Y>obj.hImAx.YLim(1) && Y>obj.hImAx.YLim(2)
            return
        end

        [xVolts, yVolts] = obj.model.mmToVolt(X,Y);

        % Update the last clicked position
        obj.plotOverlayHandles.hLastPoint.XData = X;
        obj.plotOverlayHandles.hLastPoint.YData = Y;
        obj.model.DAQ.moveBeamXY([xVolts, yVolts]);
    end % mouseMove

end % catAndMouseButton_Callback
