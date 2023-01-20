function overlayStimSites_Callback(obj,~,~)
    % Plots the points to stimulate on the image
    %
    % zapit.gui.main.controller.overlayStimSites_Callback
    %
    % Purpose
    % This callback runs on a button press and overlays (or removes) the 
    % points to stimulate over the image. It obtains the points from
    % the stimConfig.calibratedPoints getter, which converts the original
    % stereotaxic coordinates into locations on the sample as imaged.
    %
    % 

    if isempty(obj.model.stimConfig)
        return
    end

    if obj.OverlaystimsitesButton.Value == 1
        % Add the points
        calPoints = obj.model.stimConfig.calibratedPoints;
        calPoints = [calPoints{:}]; % Convert the cell array into a matrix. [ML;AP]
        calPoints = reshape(calPoints,size(calPoints,1), prod(size(calPoints,2:3)))';

        hold(obj.hImAx,'on')
        obj.plotOverlayHandles.stimConfigLocations = ...
            plot(calPoints(:,1), calPoints(:,2), 'or', ...
                'LineWidth', 2, ...
                'Parent', obj.hImAx);
        hold(obj.hImAx,'off')
    else
        % Remove the points
        obj.removeOverlays('stimConfigLocations');
    end % if

end % overlayStimSites_Callback
