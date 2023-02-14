function checkScannerCalibClocked(obj)
    % Run through the scanner calib locations using a clocked AO task.
    %
    % zapit.pointer.checkScannerCalibClocked()
    %
    % Purpose
    % Run the beam rapidly over all of the coordinates in the scanner calibration
    % grid. This method starts the scanners but does not stop them. In order to
    % stop you must execute DAQ.stopAndDeleteAOTask manually. This method is 
    % called by zapit.gui.main.controller.checkScannerCalib and this takes care of
    % these operations. Plotting is also taken care of by the GUI. This method
    % does no plotting. 
    %
    % Rob Campbell - SWC 2023

    actualCoords = obj.returnScannerCalibTargetCoords;


    % TODO - the power and exposure settings need to be set here. Currently
    % they are set in checkScannerCalib_Callback of the controller

    actualCoords(:,3) = obj.laser_mW_to_control(obj.settings.calibrateScanners.calibration_power_mW);
    actualCoords(:,4) = 0;
    
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

    obj.DAQ.writeAnalogData(actualCoords)

    obj.DAQ.start;

end % checkScannerCalibClocked
