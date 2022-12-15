function [newpoint,rotMat] = coordsRotation(template, refPoints, points)
    % calculate rotation and displacement in pixel coordinates
    %
    % function [newpoint,rotMat] = coordsRotation(template, refPoints, points)
    %
    % Purpose
    % Called by zapit.pointer.getAreaCoords to map the template stimulation locations
    % onto pixel values for this particular animal and session
    %
    % Inputs (TODO: define inputs more clearly)
    % template - template stimulation coordinates 
    % refPoints - The reference points in the same space as the templates (TODO: correct?)
    % points - The observed reference points on this particular sample. TODO: maybe we can name this better?
    %
    % Maja Skretowska - SWC 2020


    % Get the displacement vector
    translationVector = points(1,:);
    pntZeroed = points - points(1,:);
    
    % Get the rotation angle
    [th, ro] = cart2pol([pntZeroed(2,1), refPoints(2,1)], [pntZeroed(2,2), refPoints(2,2)]);
    rotationAngle = th(1)-th(2);
    rotMat = zapit.utils.rotationMatrix(rotationAngle);
    
    % Get the rescaling factor
    reScale = ro(1)/ro(2);
    
    % Map template onto new angle, scale, and displacement
    newpoint = rotMat*template(:,:,1)*reScale;
    newpoint = newpoint + translationVector';
    newpoint(:,:,2) = rotMat*template(:,:,2)*reScale;
    newpoint(:,:,2) = newpoint(:,:,2) + translationVector';
end % coordsRotation
