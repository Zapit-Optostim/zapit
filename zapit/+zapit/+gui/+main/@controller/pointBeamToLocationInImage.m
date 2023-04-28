function pointBeamToLocationInImage(obj,~,~)
    % Obtain mouse cursor position and point beam here
    %
    % function zapit.gui.main.controller.pointBeamToLocationInImage(obj,~,~)
    %
    % Purpose
    % This callback function obtains the mouse position in the
    % image and uses this to point the scanners to this location.s
    %
    % Maja Skretowska - SWC 2021

    if ~isfield(obj.plotOverlayHandles,'hLastPoint')
        % If the point is not present we bail out
        return
    end

    % Get the current mouse position (at the clicked location) and use it
    % to place a point there and display coords to the axes title.
    pos = obj.hImAx.CurrentPoint;
    xPos = pos(1,1);
    yPos = pos(1,2);


    obj.plotOverlayHandles.hLastPoint.XData = xPos;
    obj.plotOverlayHandles.hLastPoint.YData = yPos;


    % Build title text
    % convert to voltage values for title textto send to scanners
    [xVolts, yVolts] = obj.model.mmToVolt(xPos, yPos);
    msg = sprintf('X=%0.2f mm (%0.1f V) Y=%0.2f mm (%0.1f V)',...
        xPos, xVolts, yPos, yVolts);

    %obj.model.moveBeamXYinVolts([xVolts, yVolts]); % send beam to this location
    obj.model.moveBeamXYinMM([xPos, yPos]); % send beam to this location

    pause(0.15)
    OUT = obj.model.getLaserPosAccuracy([xPos,yPos],[],false);
    if ~isempty(OUT)
        obj.plotOverlayHandles.hLastDetectedLaserPos.XData = OUT.actualCoords(1);
        obj.plotOverlayHandles.hLastDetectedLaserPos.YData = OUT.actualCoords(2);
        msg = sprintf('%s error: %d microns', msg, OUT.totalErrorMicrons);
    else
        obj.plotOverlayHandles.hLastDetectedLaserPos.XData = nan;
        obj.plotOverlayHandles.hLastDetectedLaserPos.YData = nan;
    end


    % Update figure title
    showPosInTitle = true;

    if showPosInTitle
        set(get( obj.hImAx,'Title'),'String',msg)
    else
        set(get( obj.hImAx,'Title'),'String','')
    end

end % pointBeamToLocationInImage
