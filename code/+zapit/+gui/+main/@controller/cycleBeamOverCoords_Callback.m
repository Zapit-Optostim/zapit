function cycleBeamOverCoords_Callback(obj,~,~)

    % TODO: checkScannerCalibClocked is in pointer. So this is odd. [TODO there too]
    if isempty(obj.model.stimConfig)
        return
    end

    if obj.CycleBeamOverCoordsButton.Value == 1
        % TODO - we will need to change this once we settle on a better format
        % for the stimuli
        c = obj.model.calibratedPoints;

        calPoints = zeros(size(c,1), prod(size(c,2:3)))';

        tmp = squeeze(c(:,:,1));
        calPoints(1:2:end,:) = tmp';
        tmp = squeeze(c(:,:,2));
        calPoints(2:2:end,:) = tmp';

        [xVolt,yVolt] = obj.model.mmToVolt(calPoints(:,1), calPoints(:,2));

        % Build voltages to present
        waveforms = [xVolt,yVolt];
        waveforms(:,3) = 2; % laser power

        obj.model.DAQ.connectClockedAO('numSamplesPerChannel',size(waveforms,1), ...
                                'samplesPerSecond',500, ...
                                'taskName','samplecalib')

        obj.model.DAQ.hAO.writeAnalogData(waveforms)

        obj.model.DAQ.start;
    else
        obj.model.DAQ.stopAndDeleteAOTask
    end
end
