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

    BW = BWmean>(max(BWmean(:))*0.7);

    BWa = regionprops(BW,'Area');
    BWc = regionprops(BW,'Centroid');

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

    %% report to screen or return as a structure
    if nargout==0
        fprintf('Laser at x = %d y = %d\n', round(BWc.Centroid))
        fprintf('User point at x = %d y = %d\n', round(XYData))
        fprintf('Error: x = %0.2f um  y = %0.1f um\n', ...
            abs(XYData-BWc.Centroid) * obj.settings.camera.micronsPerPixel)

    elseif nargout>0
        % Return
        out.targetCoords = XYdata;
        out.actualCoords = BWc.Centroid;
        out.actualCoords = (out.actualCoords - obj.imSize/2) * ...
                    obj.settings.camera.micronsPerPixel * 1E-3;

        out.error = out.targetCoords-out.actualCoords;
        out.absErrorMicrons = abs(out.error) * 1e3;
        varargout{1} = out;
    end

end % getLaserPosAccuracy
