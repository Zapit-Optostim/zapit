function pointBeamToLocationInImage(obj,~,~)
    % Obtain mouse cursor position and point beam here
    % 
    % function pointBeamToLocationInImage(obj,~,~)
    % 
    % Purpose
    % This callback function obtains the mouse position in the
    % image and uses this to point the scanners to this location.
    %
    % Maja Skretowska - SWC 2021
    
    % Get the current mouse position (at the clicked location) and use it
    % to place a point there and display coords to the axes title.
    pos = obj.hImAx.CurrentPoint;
    xPos = pos(1,1);
    yPos = pos(1,2);
    
    % convert to voltage values to send to scanners
    [xVolts, yVolts] = pixelToVolt(obj, xPos, yPos);
    
    obj.hLastPoint.XData = xPos;
    obj.hLastPoint.YData = yPos;
    
    %SEND TO SCANNERS: (TODO: use new API)

    obj.DAQ.moveBeamXY([xVolts, yVolts]); % send beam to this location


    % Update figure title    
    msg = sprintf('X=%0.2f (%0.1f V) Y=%0.2f (%0.1f V)',...
        xPos, xVolts, yPos, yVolts);
    set(get( obj.hImAx,'Title'),'String',msg)
    
end % pointBeamToLocationInImage
