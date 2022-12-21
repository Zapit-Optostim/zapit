function checkScannerCalib(obj,actualPixelCoords)
% Sweep beam over calibration positions to visually check it worked
%
%    function checkScannerCalib(obj,actualPixelCoords)


    obj.cam.exposure = obj.settings.calibrateScanners.beam_calib_exposure;


    % Plot the locations of the grid
    hold(obj.hImAx,'on')

    obj.plotOverlayHandles.(mfilename) = ...
    plot(actualPixelCoords(:,1), actualPixelCoords(:,2), 'o', ...
        'MarkerSize', 12, ...
        'LineWidth', 2, ...
        'Color', [0,0.7,0]);

    hold(obj.hImAx,'off')


    % Cycle beam
    % TODO -- try setting up a task and having the beam scan through all points fast or maybe
    % line by line. I'm wondering whether, with the right params, all points will appear to 
    % illuminate at once. That would nice!
    for ii=1:size(actualPixelCoords,1)
        [xVolt,yVolt] = obj.pixelToVolt(actualPixelCoords(ii,1),...
                 actualPixelCoords(ii,2));
        obj.DAQ.moveBeamXY([xVolt,yVolt])
        pause(0.05)
    end


    % Tidy up
    obj.removeOverlays(mfilename)

    % change the illumination of the camera image to high value again
    obj.cam.exposure = obj.settings.camera.default_exposure;

