function [xVolts, yVolts] = mmToVolt(obj, pixelColumnInMM, pixelRowInMM)
    % Converts position in the image in mm to scanner voltage value to send to scanners
    %
    % function [xVolts, yVolts] = zapit.pointer.mmToVolt(pixelColumnInMM, pixelRowInMM)
    %
    %
    % Purpose
    % Converts mm coordinates to volt values for scanner mirrors.
    %
    % This function is important and used every time the laser is
    % pointed to a location. Called in: pointBeamToLocationInImage,
    % getAreaCoordinates and calibrateScanners.
    %
    %
    % Inputs
    % pixelColumnInMM - the x coordinate in mm
    % pixelRowInMM - the y coordinate in mm
    %
    % Rob Campbell - SWC 2023



    if ~isempty(obj.transform)
        [pixelColumnInMM, pixelRowInMM] = ...
            transformPointsInverse(obj.transform, pixelColumnInMM, pixelRowInMM);
    end

    mixPix = obj.settings.camera.micronsPerPixel;
    mmPix = mixPix * 1E-3;

    scaling = obj.settings.scanners.voltsPerPixel / mmPix;

    % The values are in offset from image centre
    xVolts = pixelColumnInMM * scaling;
    yVolts = pixelRowInMM * scaling;


    if obj.settings.scanners.invertXscanner==1
        xVolts = xVolts*-1;
    end

    if obj.settings.scanners.invertYscanner==1
        yVolts= yVolts*-1;
    end

end % pixelToVolt
