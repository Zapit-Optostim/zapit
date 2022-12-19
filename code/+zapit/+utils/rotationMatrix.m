function rotMat = rotationMatrix(theta)
    % Return the affine rotation matrix corresponding to the angle theta
    %
    % function rotMat = rotationMatrix(theta)
    %
    % Purpose
    % Return the affine rotation matrix corresponding to the angle theta
    %
    % Inputs
    % Theta - (in radians)
    %
    % Outputs
    % rotMat the rotation matrix
    % cos(theta), -sin(theta)
    % sin(theta), cos(theta)
    %
    % Notes
    % Called by zapit.utils.coordsRotation
    %
    % Maja Skretowska - SWC 2020

    rotMat = [cos(theta) -sin(theta); sin(theta) cos(theta)];

end % rotationMatrix
