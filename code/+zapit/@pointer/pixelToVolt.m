function [xVolts, yVolts] = pixelToVolt(obj, pixelColumn, pixelRow)
    % Converts pixel position to voltage value to send to scanners
    %
    % function [xVolts, yVolts] = zapit.pointer.pixelToVolt(obj, pixelColumn, pixelRow)
    %
    %
    % Purpose
    % Converts pixel coordinates to volt values for scanner mirrors
    % taking into account created transformation matrices (infinite
    % number of those allowed).
    %
    % This function is important and used every time the laser is
    % pointed to a location. Called in: pointBeamToLocationInImage,
    % getAreaCoordinates and calibrateScanners.
    %
    %
    % Inputs
    % Pixel row and column


    if ~isempty(obj.transform)
        [pixelColumn, pixelRow] = transformPointsInverse(obj.transform, pixelColumn, pixelRow);
    end
    
    
    xVolts = (pixelColumn - (obj.imSize(1)/2)) * obj.voltsPerPixel;
    yVolts = (pixelRow    - (obj.imSize(2)/2)) * obj.voltsPerPixel;
    
    if obj.invertX
        xVolts = xVolts*-1;
    end

    if obj.invertY
        yVolts= yVolts*-1;
    end
end % pixelToVolt
