function [newpoint,rotMat] = coordsRotation(template, refPoints, points)
    % calculate rotation and displacement in pixel coordinates
    %
    % function [newpoint,rotMat] = coordsRotation(template, refPoints, points)
    %
    % Purpose
    % Called by zapit.pointer.getAreaCoords.
    %
    % TODO -- full help text needed


    % get displacement vector
    translationVector = points(1,:);
    pntZeroed = points - points(1,:);
    
    % get rotation angle
    [th, ro] = cart2pol([pntZeroed(2,1), refPoints(2,1)], [pntZeroed(2,2), refPoints(2,2)]);
    rotationAngle = th(1)-th(2);
    rotMat = zapit.utils.rotationMatrix(rotationAngle);
    
    % get rescaling factor
    reScale = ro(1)/ro(2);
    
    % map template onto new angle, scale, and displacement
    newpoint = rotMat*template(:,:,1)*reScale;
    newpoint = newpoint + translationVector';
    newpoint(:,:,2) = rotMat*template(:,:,2)*reScale;
    newpoint(:,:,2) = newpoint(:,:,2) + translationVector';
end
    
