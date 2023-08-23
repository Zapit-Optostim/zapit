function cPointsVolts = calibratedPointsInVolts(obj)
    % Convert the calibrated points (sample space) into voltage values for the scanners
    %
    % zapit.stimConfig.calibratedPointsInVolts()
    %
    % Purpose
    % This method returns voltage values that can be sent to the scanners in order
    % to point the beam at the locations defined calibratedPoints.
    %
    % Inputs
    % none
    %
    % Outputs
    % A cell array of coordinates converted into voltages. The cells correspond in order
    % to the orginal data in the structure stimLocations. If the cells are concatenated
    % as [cPointsVolts{:}] then the first column is ML coords and second column is AP
    % coords. All in volts. NOTE this is transposed with respect to calibratedPoints
    %
    % Rob Campbell - SWC 2022

    cPointsVolts = {};

    calibratedPoints = obj.calibratedPoints;

    if isempty(calibratedPoints)
        return
    end

    for ii = 1:length(calibratedPoints)
        [xVolt, yVolt] = obj.parent.mmToVolt(calibratedPoints{ii}(1,:), ...
                                            calibratedPoints{ii}(2,:));
        cPointsVolts{ii} = [xVolt' yVolt'];
    end

end % calibratedPointsInVolts
