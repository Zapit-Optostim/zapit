function pointBeamToLocationInImage(obj,~,~)
    % This callback function obtains the mouse position in the
    % image and uses this to point the scanners to this location.
    
    
    % Get the current mouse position (at the clicked location) and use it
    % to place a point there and display coords to the axes title.
    pos = obj.hImAx.CurrentPoint;
    xPos = pos(1,1);
    yPos = pos(1,2);
    
    % convert to voltage values to send to scanners
    [xVolts, yVolts] = pixelToVolt(obj, xPos, yPos);
    
    obj.hLastPoint.XData = xPos;
    obj.hLastPoint.YData = yPos;
    
    %SEND TO SCANNERS:
    obj.hTask.writeAnalogData([xVolts, yVolts, 3]); % send beam to this location
    
    msg = sprintf('X=%0.2f (%0.1f V) Y=%0.2f (%0.1f V)',...
        xPos, xVolts, yPos, yVolts);
    set(get( obj.hImAx,'Title'),'String',msg)
    
end % pointBeamToLocationInImage
