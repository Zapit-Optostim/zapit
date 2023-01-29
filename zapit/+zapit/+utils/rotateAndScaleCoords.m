function [calibratedPoints,rotMat] = rotateAndScaleCoords(template, refPointsStereotaxic, refPointsSample)
    % Calculate rotation and displacement of sample with respect to stereotaxic coords and apply to data
    %
    % function [calibratedPoints,rotMat] = zapit.utils.rotateAndScaleCoords(template, refPointsStereotaxic, refPointsSample)
    %
    % Purpose
    % Calculates scale and rotation between the sample coords (refPointsSample) and standard
    % stereotaxic coords (refPointsStereotaxic). Applies the resulting transform to the data
    % in template. This allows us to map intended stimulation stereotaxic coords onto the 
    % sample as imaged by the camera.
    %
    % Inputs
    % template - template stimulation coordinates 
    % refPointsStereotaxic - The reference points in standard stereotaxic space. 
    % refPointsSample - The observed reference points on this particular sample.
    %
    %
    % Maja Skretowska - SWC 2020


    % Get the displacement vector
    translationVector = refPointsSample(1,:); %This is bregma
    pntZeroed = refPointsSample - refPointsSample(1,:);
    
    % Get the rotation angle
    [th, ro] = cart2pol([pntZeroed(2,1), refPointsStereotaxic(2,1)], [pntZeroed(2,2), refPointsStereotaxic(2,2)]);
    rotationAngle = th(1)-th(2);
    rotMat = zapit.utils.rotationMatrix(rotationAngle);
    
    % Get the rescaling factor
    reScale = ro(1)/ro(2);
    
    % Map template onto new angle, scale, and displacement
    for ii=1:size(template,3)
        calibratedPoints(:,:,ii) = rotMat*template(:,:,ii)*reScale;
        calibratedPoints(:,:,ii) = calibratedPoints + translationVector';
    end

end % rotateAndScaleCoords
