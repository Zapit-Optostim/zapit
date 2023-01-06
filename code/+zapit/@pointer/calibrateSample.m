function varargout = calibrateSample(obj)
    % Calibrate the stimulation locations for this sample and session
    %
    % function varargout = zapit.pointer.calibrateSample(obj)
    %
    % Purpose
    % This method calibrates the sample with the camera. In other words, it establishes a transform 
    % that places points in stereotaxic coordinates. The locations that we want to stimulate are 
    % stored in the template variable of the YAML stimConfig.
    %
    % This method is run after the user has interacted with the GUI to define the coordinates that 
    % go in the zapit.pointer.refPointsSample property.
    %
    %
    % Rob Campbell - SWC 2023
    % Based on orginal code by Maja Skretowska (2021)


    % Calculate the rotation and displacement in pixel coordinates
    % TODO -- This is actually performing a transform of the stim points,
    %         which is not exactly how we are working now. 
    [calibratedPoints, rotMat] = zapit.utils.coordsRotation(obj.stimConfig.template, obj.stimConfig.refPoints, realPoints);

    
    % TODO -- this needs to be an extra button in the GUI.
    % ask if you're using the option of an opaque area as additional control for inactivation
    if 0
        opaqueArea = input('Are you using an additional opaque area as control?\n[1 or 0] ');
        if opaqueArea
            figure(obj.hFig)
            title(obj.hImAx, 'Find opaque area 1')
            waitforbuttonpress

            while obj.hFig.SelectionType ~= "alt"
                figure(obj.hFig)
                calibratedPoints(:,end+1,1) = obj.hImAx.CurrentPoint([1,3])';
                waitforbuttonpress;
            end

            title(obj.hImAx, 'Find opaque area 2')
            waitforbuttonpress

            while obj.hFig.SelectionType ~= "alt"
                figure(obj.hFig)
                calibratedPoints(:,end,2) = obj.hImAx.CurrentPoint([1,3])';
                waitforbuttonpress;
            end
        end % if opaqueArea
    end


    % Translate the obtained points into volts
    % TODO -- this is a conceptually different task so maybe should be in a different method. We could still
    % call it here but maybe the code itself should be elsewhere.
    [xVolt, yVolt] = pixelToVolt(obj, calibratedPoints(1,:,1), calibratedPoints(2,:,1)); % calibratedPoints should have an n-by-2 dimension
    [xVolt2, yVolt2] = pixelToVolt(obj, calibratedPoints(1,:,2), calibratedPoints(2,:,2));


    % Save coords into object and show in the camera image
    coordsLibrary = [xVolt' yVolt'];
    coordsLibrary(:,:,2) = [xVolt2' yVolt2'];

    obj.coordsLibrary = coordsLibrary; % TODO: need a better name for this property
    obj.calibratedPoints = calibratedPoints;
    
    % TODO:
    % should now run makeChanSamples and should also run this again if laser power changes.

    %% Cycle the laser through all locations to check visually that all is good
    %% TODO -- in future this will be triggered by a button press or can happen once automatically then button press?
    %%         maybe we can have it cycle much faster than now but continuously?
    % obj.testCoordsLibrary;

    if nargout > 0
        varargout{1} = opaqueArea;
    end

end % calibrateSample

