function zapAllCoords_Callback(obj,~,~)
    % Cycle the beam over all the stimulus locations in no particular order
    %
    % zapit.gui.main.controller.zapAllCoords_Callback
    %
    % Purpose
    % Cycle the beam over all the stimulus locations rapidly. This just indicates whether
    % the beam is going to the right locations. It does not simulate what happens during
    % an experiment, as it ignores the fact that points are stimulated in pairs (usually). 
    %

    % TODO: Low priority. checkScannerCalibClocked is located in zapit.pointer. So the presence of this function here is odd

    if isempty(obj.model.stimConfig)
        obj.ZapallcoordsButton.Value = 0;
        return
    end

    if nargin>1
        % Only set GUI state if the *user* clicked the button
        % rather than than harmonizeGUIstate calling it.
        obj.GUIstate = mfilename;
    end

    if obj.ZapallcoordsButton.Value == 1

        n=10; % this many steps between each location
        waveforms = cat(1,obj.model.stimConfig.calibratedPointsInVolts{:});
        waveforms(:,3) =  obj.model.laser_mW_to_control(obj.model.settings.calibrateScanners.calibration_power_mW);
        waveforms(:,4) = 0;

        W = [];
        for ii=1:length(waveforms)-1
            W = [W; waveforms(ii,:)];

            % Make the ramps
            x1 = waveforms(ii,1);
            x2 = waveforms(ii+1,1);
            y1 = waveforms(ii,2);
            y2 = waveforms(ii+1,2);

            galvoRamp = [linspace(x1,x2,n)',linspace(y1,y2,n)'];
            galvoRamp(:,3:4) = 0; % so beam is off

            W = [W; galvoRamp];
        end

        % Make the ramps
        x1 = waveforms(end,1);
        x2 = waveforms(1,1);
        y1 = waveforms(end,2);
        y2 = waveforms(1,2);

        galvoRamp = [linspace(x1,x2,n)',linspace(y1,y2,n)'];
        galvoRamp(:,3:4) = 0; % so beam is off

        W = [W; galvoRamp];

        waveforms = W;

        obj.model.moveBeamXYinVolts(waveforms(1,1:2)) % Go to first position

        obj.model.DAQ.connectClockedAO('numSamplesPerChannel',size(waveforms,1), ...
                                'samplesPerSecond',5000, ...
                                'taskName','samplecalib')

        obj.model.DAQ.writeAnalogData(waveforms)

        obj.model.DAQ.start;
    else
        obj.model.DAQ.stopAndDeleteAOTask
        obj.model.setLaserInMW(0)
    end

end % zapAllCoords_Callback
