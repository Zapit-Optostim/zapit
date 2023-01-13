function cycleBeamOverCoords_Callback(obj,~,~)
    % Cycle the beam over all the stimulus locations in no particular order
    %
    % zapit.gui.main.controller.cycleBeamOverCoords_Callback
    %
    % Purpose
    % Cycle the beam over all the stimulus locations rapidly. This just indicates whether
    % the beam is going to the right locations. It does not simulate what happens during
    % an experiment, as it ignores the fact that points are stimulated in pairs (usually). 
    %

    % TODO: checkScannerCalibClocked is located in zapit.pointer. So the presence of this function here is odd. [TODO there too]
    if isempty(obj.model.stimConfig)
        return
    end

    if obj.CycleBeamOverCoordsButton.Value == 1
        % TODO - we will need to change this once we settle on a better format
        % for the stimuli
        c = obj.model.stimConfig.calibratedPoints;

        calPoints = zeros(size(c,1), prod(size(c,2:3)))';

        tmp = squeeze(c(:,:,1));
        calPoints(1:2:end,:) = tmp';
        tmp = squeeze(c(:,:,2));
        calPoints(2:2:end,:) = tmp';

        [xVolt,yVolt] = obj.model.mmToVolt(calPoints(:,1), calPoints(:,2));

        % Build voltages to present
        waveforms = [xVolt,yVolt];
        waveforms(:,3) = 2; % laser power

        obj.model.DAQ.moveBeamXY(waveforms(1,:))
        obj.model.DAQ.connectClockedAO('numSamplesPerChannel',size(waveforms,1), ...
                                'samplesPerSecond',500, ...
                                'taskName','samplecalib')

        obj.model.DAQ.writeAnalogData(waveforms)

        obj.model.DAQ.start;
    else
        obj.model.DAQ.stopAndDeleteAOTask
        obj.model.setLaserInMW(0)
    end

end % cycleBeamOverCoords_Callback
