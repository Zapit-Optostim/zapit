function pointButton_Callback(obj,~,~)


    % Switch back and forth between click and point mode
    if obj.PointModeButton.Value == 1

        obj.CatMouseButton.Value = 0; % Both can not be activate at the the same time

        % Initially no last clicked position should be visible
        obj.hLastPoint.XData = nan;
        obj.hLastPoint.YData = nan;

        % Turn on laser
        obj.setCalibLaserSwitch('On');
        obj.hImLive.ButtonDownFcn = @obj.pointBeamToLocationInImage;
        obj.hLastPoint.Visible = 'on';

    elseif obj.PointModeButton.Value == 0

        % Turn off laser
        obj.setCalibLaserSwitch('Off');

        obj.hImLive.ButtonDownFcn = [];
        obj.hLastPoint.Visible = 'off';

    end


end
