function opaqueArea = getAreaCoordinates(obj)
    % This method checks what actual pixel coordinates are of the
    % template coordinates kept in session_settings.template, and
    % it stores them in the object's property transformed into
    % volts
    
    % change illumination to get a clearer image of beam position
    obj.cam.src.Gain = 25;
    
    % record points in the screen
    refPoints = obj.config.refPoints;                        % coordinate references on the mouse skull (bregma and 0,-2 marked with pen)
    template = obj.config.template;
    hold(obj.hImAx, 'on');
    %             plot(obj.hImAx, refPoints(:,1), refPoints(:,2));
    realPoints = recordPoints(obj.hImAx, obj.hFig); % output columns are x and y coords
    
    % calculate rotation and displacement in pixel coordinates
    [newpoint, rotMat] = coordsRotation(template, refPoints, realPoints);
    
    % ask if you're using the option of an opaque area as additional control for inactivation
    [newpoint, opaqueArea] = checkOpaqueArea(obj, newpoint);
    
    % translate obtained points into volts
    [xVolt, yVolt] = pixelToVolt(obj, newpoint(1,:,1), newpoint(2,:,1)); % newpoint should have an n-by-2 dimension
    [xVolt2, yVolt2] = pixelToVolt(obj, newpoint(1,:,2), newpoint(2,:,2));
    
    
    %% save coords into object and show in the camera image
    coordsLibrary = [xVolt' yVolt'];
    coordsLibrary(:,:,2) = [xVolt2' yVolt2'];

    coordsLibrary
    obj.coordsLibrary = coordsLibrary;
    obj.newpoint = newpoint;
    
    
    hold(obj.hImAx, 'on');
    plot(obj.hImAx, newpoint(1, :, 1), newpoint(2, :, 1), 'o'); % left hemisphere coords
    plot(obj.hImAx, newpoint(1, :, 2), newpoint(2, :, 2), 'o'); % right hemisphere coords
    
    % move laser into each position as a check
    for xx = 1:length(newpoint)
        for yy = 1:2
            obj.hTask.writeAnalogData([obj.coordsLibrary(xx, 1, yy), obj.coordsLibrary(xx, 2, yy)]);
            pause(1)
        end
    end
    
    
    
    %% functions
    function points = recordPoints(hImAx, hImFig)
        % TODO -- remove & refactor
        % choose a point by left-click in the figure, and report
        % the choice by right-click (then proceed to next step)
        
        % left-click automatically sends the beam to the location
        % by the callback pointBeamToLocationInImage function
        
        title(hImAx, 'click bregma');
        figure(hImFig)                                  % call figure to make sure matlab is waiting for clicks in the right window
        waitforbuttonpress;
        while hImFig.SelectionType ~= "alt"             % 'alt' is right-click in the figure
            points(1,:) = hImAx.CurrentPoint([1 3]);    % so until left-click choice is confirmed with right click, you can change location of the beam until precise enough
            figure(hImFig)
            waitforbuttonpress;
        end
        figureText = join(['bregma recorded, click ', string(refPoints(:,2)')]);
        title(hImAx,figureText);
        figure(hImFig)
        waitforbuttonpress;
        while hImFig.SelectionType ~= "alt"
            points(2,:) = hImAx.CurrentPoint([1 3]);
            figure(hImFig)
            waitforbuttonpress;
        end
        
        title(hImAx, 'both points recorded');
        plot(hImAx, points(:,1), points(:,2));
    end
    
    function [newpoint,rotMat] = coordsRotation(template, refPoints, points)
        % TODO -- remove & refactor
        % get displacement vector
        translationVector = points(1,:);
        pntZeroed = points-points(1,:);
        
        % get rotation angle
        [th, ro] = cart2pol([pntZeroed(2,1), refPoints(2,1)], [pntZeroed(2,2), refPoints(2,2)]);
        rotationAngle = th(1)-th(2);
        rotMat = rotationMatrix(rotationAngle);
        
        % get rescaling factor
        reScale = ro(1)/ro(2);
        
        % map template onto new angle, scale, and displacement
        newpoint = rotMat*template(:,:,1)*reScale;
        newpoint = newpoint + translationVector';
        newpoint(:,:,2) = rotMat*template(:,:,2)*reScale;
        newpoint(:,:,2) = newpoint(:,:,2) + translationVector';
    end
    
    function rotMat = rotationMatrix(theta)
        rotMat = [cos(theta) -sin(theta); sin(theta) cos(theta)];
    end
    
    function [newpoint, opaqueArea] = checkOpaqueArea(obj, newpoint)
        % TODO -- refactor to model/view
        opaqueArea = input('using an additional opaque area as control? 1 or 0');
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
    end
end

