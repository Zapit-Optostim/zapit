function drawBrainOutlineOnSample(obj)
    % Run the beam around around the brain outline
    %
    % zapit.pointer.drawBrainOutlineOnSample()
    %
    % Purpose
    % Draw the brain outline onto the sample using the laser and scanners. 
    % Once started you can stop it with zapit.DAQ.stopAndDeleteAOTask.
    % This method is generally called via the GUI, which handles stopping 
    % in a neat way using a toggle button.
    %
    % Rob Campbell - SWC 2023

    coords = obj.calibratedBrainOutline;

    % Sub-sample it a bit
    coords = coords(1:3:end,:);
  
    % First place beam in the centre of the area we want to stimulate
    obj.moveBeamXYinVolts(mean(coords));
    coords(:,3) = obj.laser_mW_to_control(obj.settings.calibrateScanners.calibration_power_mW);
    coords(:,4) = 0;
    %Replace first two columns with voltage values
    [xVolt,yVolt] = obj.mmToVolt(coords(:,1), coords(:,2));

    coords(:,1) = xVolt;
    coords(:,2) = yVolt;

    % NOTE: changing the number of samples per second will speed up presentation of the spots.
    % At 1000 you will by eye see a grid of points. On the screen, though, this is not visible.
    % Would have to average many frames to see this.


    % Set sample rate so we are drawing at about 60 cycles per second.
    n = length(coords) * 100;
    sRate = round(10^round(log10(n),1)) ;
    
    verbose=false;
    if verbose
        fprintf('Setting sample rate to %d\n', sRate);
    end

    obj.DAQ.connectClockedAO('numSamplesPerChannel',size(coords,1), ...
                            'samplesPerSecond',sRate, ...
                            'taskName','scannercalib')

    obj.DAQ.writeAnalogData(coords)

    obj.DAQ.start;

end % drawBrainOutlineOnSample
