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

    % TODO: Low priority. checkScannerCalibClocked is located in zapit.pointer. So the presence of this function here is odd

    if isempty(obj.model.stimConfig)
        return
    end

    if obj.CycleBeamOverCoordsButton.Value == 1


        waveforms = cat(1,obj.model.stimConfig.calibratedPointsInVolts{:});
        waveforms(:,3) = 2; % laser power -- HARDCODED

        obj.model.DAQ.moveBeamXY(waveforms(1,:)) % Go to first position

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
