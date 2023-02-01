function [areaName,areaIndex] = getAreaNameFromCoords(obj,ML,AP)
    % Return brain area name from stereotaxic ML/AP coordinates
    %
    % zapit.stimConfig.getAreaNameFromCoords
    %
    % Purpose
    % Get the name of a brain area associated with ML/AP coords.
    %
    % Inputs
    % ML - mediolateral stereotaxic coord in mm
    % AP - anterioposterio stereotaxic coord in mm
    %
    % If the above are vectors of the same length, the function
    % will loop through and return a cell array of names associated
    % with all coords.
    %
    % Outputs
    % areaName - names of brain areas that are related to the coords. If one
    %           set of coords only then this is a string. If multiple, it's a cell
    %           array.
    % areaIndex - index values of area or areas. Scalar or vector accordingly

    if length(ML) ~= length(AP)
        areaIndex = [];
        areaName = [];
        return
    end

    brain_areas = obj.atlasData.dorsal_brain_areas;
    [~,indX] = arrayfun(@(x) min(abs(obj.atlasData.top_down_annotation.xData-x)), ML);
    [~,indY] = arrayfun(@(x) min(abs(obj.atlasData.top_down_annotation.yData-x)), AP);
    t_ind = arrayfun(@(x,y) obj.atlasData.top_down_annotation.data(x,y), indY, indX);
    areaIndex = arrayfun(@(x) find([brain_areas.area_index]==x), t_ind);
    areaName = arrayfun(@(x) brain_areas(x).names{1}, areaIndex, 'UniformOutput', false);

    if length(areaName)==1
        areaName = areaName{1};
    end

end % getAreaNameFromCoords
