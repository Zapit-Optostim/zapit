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

    % TODO--looks like we will be removing this method?

    % Calculate the rotation and displacement in pixel coordinates
    % TODO -- This is actually performing a transform of the stim points,
    %         which is not exactly how we are working now. 
    [calibratedPoints, rotMat] = zapit.utils.rotateAndScaleCoords(obj.stimConfig.template, obj.stimConfig.refPoints, realPoints);

    


    if nargout > 0
        varargout{1} = opaqueArea;
    end

end % calibrateSample

