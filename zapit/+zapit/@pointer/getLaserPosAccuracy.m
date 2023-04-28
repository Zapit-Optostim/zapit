function varargout = getLaserPosAccuracy(obj, XYdata, backgroundImage, verbose)
    % Quantify accuracy of beam pointing
    %
    % function out = getLaserPosAccuracy(XYdata, backgroundImage, verbose)
    %
    % Purpose
    % Find the coords of the beam location and compare to the desired location. Returns
    % results to screen if no outputs. Otherwise returns a structure and does not print
    % to screen.
    %
    % Inputs
    % XYdata - The target laser coordinates in mm. [columnMM, rowMM]
    % backgroundImage - [optional] if provided this image is subtracted before analysis.
    % verbose - [optional] False by default. If true print to console debug information.
    %
    % Outputs
    % Optional structure containing results.
    %
    %
    % Maja Skretowska - SWC 2021
    % Rob Campbell - SWC 2022


    if nargin<3
        backgroundImage = [];
    end

    if nargin<4
        verbose = false;
    end

    % Get images: average a few frames before looking for the laser
    nFrames = 1;
    tFrames = obj.returnCurrentFrame(nFrames);

    if isempty(backgroundImage)
        backgroundImage = zeros(size(tFrames,[1,2]), class(tFrames));
    end

    % Store for later
    meanInputImage = mean(tFrames,3);

    % Binarize
    for ii = 1:nFrames
        tFrame = tFrames(:,:,ii) - backgroundImage;
        if isempty(backgroundImage)
            tFrames(:,:,ii) = tFrames(:,:,ii) > (max(tFrame(:))*0.5) ;
        else
            tFrames(:,:,ii) = tFrames(:,:,ii) > (max(tFrame(:))*0.9) ;
        end
    end

    BWmean = mean(tFrames,3);

    BWa = regionprops(BWmean,'Area');
    BWc = regionprops(BWmean,'Centroid');

    % Bail out if we find no or multiple points
    bailOut = false;
    if length(BWc) ~= 1
        bailOut = true;
        if verbose
            fprintf('Expected to find one point. Found %d points\n', length(BWc))
        end
    end

    % Bail out if the area of the region is too large. Then it can't be the laser
    areaThreshold = obj.settings.calibrateScanners.areaThreshold;

    if ~bailOut && (BWa.Area > areaThreshold)
        bailOut = true;
        if verbose
            fprintf('Area of laser is %d pixels. This is larger than threshold of %d pixels\n', ...
             BWa.Area, areaThreshold)
        end
    end

    if bailOut
        if nargout>0
            varargout{1} = [];
        end
        return
    end

    % Store a small image centered around the detected laser spot position.
    imSizeMicrons=750;
    imSizePixels = round(imSizeMicrons/obj.settings.camera.micronsPerPixel);
    imSizePixels_half = round(imSizePixels/2);
    c = round(BWc.Centroid); % location of the laser spot centre
    out.laserSpotIm = meanInputImage(c(2)-imSizePixels_half : c(2)+imSizePixels_half, ...
                     c(1)-imSizePixels_half : c(1)+imSizePixels_half );

    % Get the intensity profile of the laser
    %% report to screen or return as a structure
    out.targetCoords = XYdata;
    out.actualCoords = (BWc.Centroid - obj.imSize/2) * ...
                obj.settings.camera.micronsPerPixel * 1E-3;

    out.error = out.targetCoords-out.actualCoords; % in mm
    out.totalErrorMicrons = round(sqrt(sum(out.error.^2)) * 1E3);

    % Calculate where in the cropped beam image the target position is located.
    errorInMicrons = out.error * 1E3;
    errorInPixels = errorInMicrons / obj.settings.camera.micronsPerPixel;
    out.targetCoordsOnImage = errorInPixels + imSizePixels_half; % TODO: needs validation! I worry I could be out by perhaps half a pixel

    if nargout==0
        fprintf('Laser at x = %0.3f mm y = %0.3f mm\n', out.actualCoords)
        fprintf('User point at x = %0.3f mm y = %0.3f mm\n', out.targetCoords)
        fprintf('Error: x = %0.2f um  y = %0.1f um\n', ...
            out.error)

    elseif nargout>0
        % Return
        varargout{1} = out;
    end

end % getLaserPosAccuracy
