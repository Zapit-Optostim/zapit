function addLastPointLocationMarker(obj)
    % Add marker for showing the last point location
    %
    % zapit.gui.main.controller.addLastPointLocationMarker
    %
    % Purpose
    % The last clicked location is shown in the image by a red circle. Since
    % multiple functions use this feature, creation of the plot element takes
    % place in its own method.

    hold(obj.hImAx,'on')

    obj.plotOverlayHandles.hLastDetectedLaserPos = plot(nan, nan,'g+','MarkerSize',14, ...
        'LineWidth', 2, 'Parent',obj.hImAx);
    obj.plotOverlayHandles.hLastPoint = plot(nan, nan,'or','MarkerSize',10, ...
        'LineWidth', 2, 'Parent',obj.hImAx);

    hold(obj.hImAx,'off')

    % Set GUI state based on calibration state
    obj.scannersCalibrateCallback
    obj.sampleCalibrateCallback
end % addLastPointLocationMarker
