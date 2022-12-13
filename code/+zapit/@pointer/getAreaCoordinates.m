function varargout = getAreaCoordinates(obj)
    % This method checks what actual pixel coordinates are of the
    % template coordinates kept in session_settings.template, and
    % it stores them in the object's property transformed into
    % volts
    
    % change illumination to get a clearer image of beam position
    obj.cam.src.Gain = 2;

    % Clear any old coords
    delete(obj.hAreaCoords)
    obj.hAreaCoords = [];

    delete(obj.hRefCoords)
    obj.hRefCoords = [];

    realPoints = obj.recordPoints; % output columns are x and y coords
    
    % calculate rotation and displacement in pixel coordinates
    [newpoint, rotMat] = zapit.utils.coordsRotation(obj.config.template, obj.config.refPoints, realPoints);
    
    % ask if you're using the option of an opaque area as additional control for inactivation
    opaqueArea = input('using an additional opaque area as control?\n[1 or 0] ');
    if opaqueArea
        figure(obj.hFig)
        title(obj.hImAx, 'find opaque area 1')
        waitforbuttonpress

        while obj.hFig.SelectionType ~= "alt"
            figure(obj.hFig)
            newpoint(:,end+1,1) =obj.hImAx.CurrentPoint([1 3])';
            waitforbuttonpress;
        end

        title(obj.hImAx, 'find opaque area 2')
        waitforbuttonpress

        while obj.hFig.SelectionType ~= "alt"
            figure(obj.hFig)
            newpoint(:,end,2) =obj.hImAx.CurrentPoint([1 3])';
            waitforbuttonpress;
        end
    end


    % translate obtained points into volts
    [xVolt, yVolt] = pixelToVolt(obj, newpoint(1,:,1), newpoint(2,:,1)); % newpoint should have an n-by-2 dimension
    [xVolt2, yVolt2] = pixelToVolt(obj, newpoint(1,:,2), newpoint(2,:,2));
    
    
    %% save coords into object and show in the camera image
    coordsLibrary = [xVolt' yVolt'];
    coordsLibrary(:,:,2) = [xVolt2' yVolt2'];

    obj.coordsLibrary = coordsLibrary;
    obj.newpoint = newpoint;
    
    
    hold(obj.hImAx, 'on');
    obj.hAreaCoords(1) = plot(obj.hImAx, newpoint(1,:,1), newpoint(2,:,1), 'o'); % left hemisphere coords
    obj.hAreaCoords(2) = plot(obj.hImAx, newpoint(1,:,2), newpoint(2,:,2), 'o'); % right hemisphere coords
    hold(obj.hImAx, 'off');


    % Move points through all locations to check visually that all is good
    obj.testCoordsLibrary;

    if nargout > 0
        varargout{1} = opaqueArea;
    end

end

