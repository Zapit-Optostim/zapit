function drawBrainOutlineOnSample(obj)
    % Run the beam around around the brain outline
    %
    % Must run DAQ.stopAndDeleteAOTask manually to stop.
    %
    % Does no plotting.

    coords = obj.calibratedBrainOutline;

    % First place beam in the centre of the area we want to stimulate
    obj.DAQ.moveBeamXY(mean(coords));

    % TODO -- should not have duplicates!
    % TODO - the power and exposure settings need to be set here. Currently
    % they are set in checkScannerCalib_Callback of the controller

    coords(:,3:4)=2; % LASER POWER HERE TODO

    %Replace first two columns with voltage values
    [xVolt,yVolt] = obj.mmToVolt(coords(:,1), coords(:,2));

    coords(:,1) = xVolt;
    coords(:,2) = yVolt;

    % NOTE: changing the number of samples per second will speed up presentation of the spots.
    % At 1000 you will by eye see a grid of points. On the screen, though, this is not visible.
    % Would have to average many frames to see this.


    % Set sample rate so we are drawing at about 60 cycles per second.
    n = length(coords) * 60;
    sRate = 10^round(log10(n),1) ;
    obj.DAQ.connectClockedAO('numSamplesPerChannel',size(coords,1), ...
                            'samplesPerSecond',sRate, ...
                            'taskName','scannercalib')

    obj.DAQ.hAO.writeAnalogData(coords)

    obj.DAQ.start;

end
