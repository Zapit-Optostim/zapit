function showStimulusCoords_Callback(obj,~,~)

    if isempty(obj.model.stimConfig)
        return
    end

    if obj.ShowstimcoordsButton.Value == 1

        % TODO - we will need to change this once we settle on a better format
        % for the stimuli
        calPoints = obj.model.stimConfig.calibratedPoints;
        calPoints = reshape(calPoints,size(calPoints,1), prod(size(calPoints,2:3)))';

        hold(obj.hImAx,'on')
        obj.plotOverlayHandles.stimConfigLocations = ...
            plot(calPoints(:,1), calPoints(:,2), 'or', ...
                'LineWidth', 2, ...
                'Parent', obj.hImAx);
        hold(obj.hImAx,'off')
    else
        obj.removeOverlays('stimConfigLocations');
    end

end
