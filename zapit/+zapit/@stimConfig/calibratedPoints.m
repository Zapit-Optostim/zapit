function cPoints = calibratedPoints(obj)
    % The stimulation locations after they have been calibrated to the sample
    %
    % zapit.stimConfig.calibratedPoints
    %
    % Purpose
    % Places the stereotaxic target coords in stimLocations into the sample
    % space being imaged by the camera. It does this using the estimate of
    % bregma plus one more stereotaxic point that are stored in refPointsSample.
    %
    % Inputs
    % none
    %
    % Outputs
    % A cell array of converted coordinates. The cells correspond in order to
    % the orginal data in the structure stimLocations. If the cells are
    % concatenated as [cPoints{:}] then the first row is ML coords and second
    % row is AP coords. All in mm.
    %
    % Rob Campbell - SWC 2022

    cPoints = {};

    if isempty(obj.parent.refPointsSample)
        fprintf('Sample has not been calibrated! Returning empty data! \n')
        return
    end

    for ii = 1:obj.numConditions
        tmpMat = [obj.stimLocations(ii).ML; obj.stimLocations(ii).AP];
        cPoints{ii} = zapit.utils.rotateAndScaleCoords(...
                    tmpMat, ...
                    obj.parent.refPointsStereotaxic, ...
                    obj.parent.refPointsSample);
    end

end % calibratedPoints
