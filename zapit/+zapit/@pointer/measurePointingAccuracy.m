function [out,im] = measurePointingAccuracy(obj,pointsToTest)
    % Run through a series of points and measure beam pointing accuracy
    %
    % [out,im] = zapit.pointer.measurePointingAccuracy(pointsToTest)
    %
    % Purpose
    % Run the beam rapidly over a set of points and report pointing accuracy
    %
    % Inputs
    % pointsToTest - n by 2 matrix of positions in mm TODO -- what is each column?
    %
    % Outputs
    % out - structure with results
    % im - the baseline image
    %
    % Example
    %  [R,C] = hZP.generateScannerCalibrationPoints;
    %  out = hZP.measurePointingAccuracy([C,R])
    %
    % Rob Campbell - SWC 2023
    %
    % See also
    % zapit.pointer.calibrateScanners
    % zapit.pointer.getLaserPosAccuracy




    obj.moveBeamXYinVolts(pointsToTest(1,:)); % Move to first position

    pause(0.05)

    obj.setLaserInMW(obj.settings.calibrateScanners.calibration_power_mW)

    % Get the current frame with laser off (optional but not a user setting so hard-code here)
    doBackgroundFrame = true;
    if doBackgroundFrame
        backgroundFrame = obj.returnCurrentFrame(5);
        backgroundFrame = cast(mean(backgroundFrame,3),class(backgroundFrame));
    else
        backgroundFrame = [];
    end

    ind=1;
    obj.breakPointingAccuracyLoop = false; % If an external entity (like the GUI) sets this to
                                           % true then we will break out of the loop.
    verbose=false;

    n = 1;
    for ii = 1:size(pointsToTest,1)

        if obj.breakPointingAccuracyLoop
            break
        end

        % feed volts into scan mirrors, wait for precise image
        % without smudges and take position in pixels
        obj.moveBeamXYinMM(pointsToTest(ii,:));
        pause(0.1)

        % Attempt to get laser position and append to list if the position was found
        tmp = obj.getLaserPosAccuracy(pointsToTest(ii,:), backgroundFrame, true);
        if ~isempty(tmp)
            if verbose
                fprintf('Target: %d/%d Actual: %d/%d\n',  ...
                    out(ii).targetCoords, round(out(ii).actualCoords))
            end
            out(n) = tmp;
            n = n + 1;
        end
    end

    obj.setLaserInMW(0)


    % Data for image so it can be plotted along with the data
    im = obj.lastAcquiredFrame;

end % measurePointingAccuracy
