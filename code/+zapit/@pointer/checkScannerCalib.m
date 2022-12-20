function checkScannerCalib(obj,actualPixelCoords)
% Sweep beam over calibration positions to visually check it worked
%
%    function checkScannerCalib(obj,actualPixelCoords)


    obj.cam.exposure = obj.settings.calibrateScanners.beam_calib_exposure;

    hold on
    hPall = plot(actualPixelCoords(:,1), actualPixelCoords(:,2), 'o', ...
        'MarkerSize', 12, ...
        'LineWidth', 2, ...
        'Color', [0,0.7,0]);
    hold off


    for ii=1:size(actualPixelCoords,1)
        [xVolt,yVolt] = obj.pixelToVolt(actualPixelCoords(ii,1),...
                 actualPixelCoords(ii,2));
        obj.DAQ.moveBeamXY([xVolt,yVolt])
        pause(0.05)
    end


    % change the illumination of the camera image to high value again
    obj.cam.exposure = obj.settings.camera.default_exposure;

