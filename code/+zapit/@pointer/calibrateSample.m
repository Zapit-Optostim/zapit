function varargout = calibrateSample(obj)
    % Calibrate the stimulation locations for this animal
    %
    % function varargout = zapit.pointer.calibrateSample(obj)
    %
    % Purpose
    % The locations that we want to stimulate are stored in the template variable
    % of the stim configuration YAML file. These locations need to be converted into actual
    % pixel coordinates for the present animal and session. They will need to be 
    % rotated and scaled, etc. This function achives this by clicking two landmarks on the skull.
    %
    %
    % Maja Skretowska - 2021


    % change illumination to get a clearer image of beam position TODO: remove hard-coding
    obj.cam.src.Gain = 2;


    % Ask the user to identify reference point on skull surface. Typically this will be
    % bregma plus one more  point. The results are returned as two columns: first x then y coords.
    % First row is bregma
    % TODO: this must be an input from the controller
    realPoints = obj.recordPoints; 
    

    % Now we calculate the rotation and displacement in pixel coordinates
    [newpoint, rotMat] = zapit.utils.coordsRotation(obj.stimConfig.template, obj.stimConfig.refPoints, realPoints);
    
    % TODO -- this needs to be an extra button in the GUI.
    % ask if you're using the option of an opaque area as additional control for inactivation
    opaqueArea = input('Are you using an additional opaque area as control?\n[1 or 0] ');
    if opaqueArea
        figure(obj.hFig)
        title(obj.hImAx, 'Find opaque area 1')
        waitforbuttonpress

        while obj.hFig.SelectionType ~= "alt"
            figure(obj.hFig)
            newpoint(:,end+1,1) = obj.hImAx.CurrentPoint([1,3])';
            waitforbuttonpress;
        end

        title(obj.hImAx, 'Find opaque area 2')
        waitforbuttonpress

        while obj.hFig.SelectionType ~= "alt"
            figure(obj.hFig)
            newpoint(:,end,2) = obj.hImAx.CurrentPoint([1,3])';
            waitforbuttonpress;
        end
    end % if opaqueArea


    % Translate the obtained points into volts
    [xVolt, yVolt] = pixelToVolt(obj, newpoint(1,:,1), newpoint(2,:,1)); % newpoint should have an n-by-2 dimension
    [xVolt2, yVolt2] = pixelToVolt(obj, newpoint(1,:,2), newpoint(2,:,2));


    % Save coords into object and show in the camera image
    coordsLibrary = [xVolt' yVolt'];
    coordsLibrary(:,:,2) = [xVolt2' yVolt2'];

    obj.coordsLibrary = coordsLibrary;
    obj.newpoint = newpoint; % TODO: need a better name for this property
    
    % TODO:
    % should now run makeChanSamples and should also run this again if laser power changes.

    % Cycle the laser through all locations to check visually that all is good
    % TODO -- in future this will be triggered by a button press or can happen once automatically then button press?
    %         maybe we can have it cycle much faster than now but continuously?
    obj.testCoordsLibrary;

    if nargout > 0
        varargout{1} = opaqueArea;
    end

end % getAreaCoordinates

