function highlightSelectedStimCond(obj)
    % If stim points are being overlaid, the selected set in the dropdown are highlighted
    %
    % zapit.gui.main.controller.highlightSelectedStimCond
    %
    % Purpose
    % Highlights in a different color the points selected by the dropdown.
    %


    % Do not highlight points if are not plotting them
    obj.removeOverlays('highlightedStimConfigLocations')
    if obj.OverlaystimsitesButton.Value == 0
        return
    end

    % Get the highlighted index
    siteStr = regexprep(obj.TestSiteDropDown.Value,'Site ','');
    siteInd = str2double(siteStr);

    % Add the points
    calPoints = obj.model.stimConfig.calibratedPoints{siteInd};

    hold(obj.hImAx,'on')
    obj.plotOverlayHandles.highlightedStimConfigLocations = ...
        plot(calPoints(1,:), calPoints(2,:), 'or', ...
            'MarkerFaceColor', 'r', ...
            'LineWidth', 2, ...
            'Parent', obj.hImAx);
    hold(obj.hImAx,'off')


end % highlightSelectedStimCond
