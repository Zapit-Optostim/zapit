function varargout = getLaserPosAccuracy(obj, XYdata)
    % Quantify accuracy of beam pointing
    %
    % function out = getLaserPosAccuracy(obj, XYdata)
    %
    %
    % Find the coords of the beam location and compare to
    % the desired location. Returns results to screen if no
    % outputs. Otherwise returns a structure and does not
    % print to screen.
    
    %% find centre of laser field after averaging a few frames

    % Get images
    nFrames = 5;
    tFrames = obj.hImLive.CData;
    lastFrameAcquired = obj.cam.vid.FramesAcquired;

    while size(tFrames,3) < nFrames
        currentFramesAcquired = obj.cam.vid.FramesAcquired;
        if currentFramesAcquired > lastFrameAcquired
            tFrames(:,:,end+1) = obj.hImLive.CData;
            lastFrameAcquired = currentFramesAcquired;
        end
    end

    % Binarize
    for ii = 1:nFrames
        tFrame = tFrames(:,:,ii);
        tFrames(:,:,ii) = tFrames(:,:,ii) > (max(tFrame(:))*0.5) ;
    end

    BWmean = mean(tFrames,3);

    BW = BWmean>(max(BWmean(:))*0.7);
    BWc = regionprops(bwareaopen(BW,50),'Centroid');
    
    % Bail out if we find no or multiple points
    if length(BWc) ~= 1
        fprintf('Expected to find one point. Found %d points\n', length(BWc))
        return
    end
    
    %% report to screen or return as a structure
    if nargout==0
        fprintf('Laser at x = %d y = %d\n', round(BWc.Centroid))
        fprintf('User point at x = %d y = %d\n', ...
            round(obj.hLastPoint.XData), round(obj.hLastPoint.YData))
        
        fprintf('Error: x = %0.2f um  y = %0.1f um\n', ...
            abs(obj.hLastPoint.XData-BWc.Centroid(1)) * obj.micsPix, ...
            abs(obj.hLastPoint.YData-BWc.Centroid(2)) * obj.micsPix)
    elseif nargout>0
        if nargin<2
            out.targetPixelCoords = [obj.hLastPoint.XData, obj.hLastPoint.YData];
        else
            out.targetPixelCoords = XYdata;
        end

        % Return
        out.actualPixelCoords = BWc.Centroid;
        out.error = out.targetPixelCoords-out.actualPixelCoords;
        out.absErrorMicrons = abs(out.error) * obj.micsPix;

        varargout{1} = out;
    end
    
end

