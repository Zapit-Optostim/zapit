function checkScannerCalibClocked(obj)
    % Run through the scanner calib locations using a clocked AO task.
    %
    % Must run DAQ.stopAndDeleteAOTask manually to stop.
    %
    % Does no plotting. This method is called by checkScannerCalib_Callback
    % in zapit.gui.main.controller
    actualCoords = obj.returnScannerCalibTargetCoords;

    % TODO -- should not have duplicates!
    % TODO - the power and exposure settings need to be set here. Currently
    % they are set in checkScannerCalib_Callback of the controller

    actualCoords(:,3:4)=2; % LASER POWER HERE TODO

    %Replace first two columns with voltage values
    [xVolt,yVolt] = obj.mmToVolt(actualCoords(:,1), actualCoords(:,2));

    actualCoords(:,1) = xVolt;
    actualCoords(:,2) = yVolt;

    % NOTE: changing the number of samples per second will speed up presentation of the spots.
    % At 1000 you will by eye see a grid of points. On the screen, though, this is not visible.
    % Would have to average many frames to see this.

    obj.DAQ.connectClockedAO('numSamplesPerChannel',size(actualCoords,1), ...
                            'samplesPerSecond',10, ...
                            'taskName','scannercalib')

    obj.DAQ.hAO.writeAnalogData(actualCoords)

    obj.DAQ.start;

end
