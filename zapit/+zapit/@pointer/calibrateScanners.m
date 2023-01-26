function varargout = calibrateScanners(obj)
    % Calibrate scanners with camera: conduct an affine transform to calibrate camera and beam
    %
    % function varargout = zapit.pointer.calibrateScanners(obj)
    %
    % Purpose
    % Moves beam sequentially across a series of locations and records the intended vs
    % actual beam position on the camera image. This allows us to calculate an affine
    % transform that converts a pixel location on the image to the scanner command voltages
    % required to point the beam at that location.
    %
    %
    % Inputs (optional):
    % none
    %
    %
    % Outputs
    % optional - target and actual pixel coordinates in a structure
    %
    %
    % Maja Skretowska - SWC 2021
    % Rob Campbell - SWC 2022

    obj.setLaserInMW(0)

    % lower camera illumination for increased precision in detecting beam location 

    obj.cam.exposure = obj.settings.calibrateScanners.beam_calib_exposure;


    % Wipe the previous transform
    obj.transform = [];
    obj.scannersCalibrated = false;


    [R,C] = obj.generateScannerCalibrationPoints;


    % change mm coords into voltage 
    [rVolts(:,1), rVolts(:,2)] = obj.mmToVolt(C,R);
    obj.DAQ.moveBeamXY(rVolts(1,:)); % Move to first position

    pause(0.05)

    obj.setLaserInMW(obj.settings.calibrateScanners.calibration_power_mW)

    % Get the current frame with laser off
    backgroundFrame = obj.returnCurrentFrame(10);
    backgroundFrame = cast(mean(backgroundFrame,3),class(backgroundFrame));

    ind=1;
    obj.breakScannerCalibLoop = false; % If an external entity (like the GUI) sets this to
                                       % true then we will break out of the loop.
    verbose=false;
    for ii=1:length(R)

        if obj.breakScannerCalibLoop
            break
        end
        % feed volts into scan mirrors, wait for precise image
        % without smudges and take position in pixels
        obj.DAQ.moveBeamXY(rVolts(ii,:));
        pause(0.1)

        % Attempt to get laser position and append to list if the position was found
        out = obj.getLaserPosAccuracy([C(ii), R(ii)], backgroundFrame, true);
        if ~isempty(out)
            if verbose
                fprintf('Target: %d/%d Actual: %d/%d\n',  ...
                    out.targetCoords, round(out.actualCoords))
            end
            if ind == 1
                obj.calibrateScannersPosData = out;
            else
                obj.calibrateScannersPosData(ind) = out;
            end
            ind = ind+1;
        end
    end


    if ind<4
        fprintf('Failed to record sufficient points to run the transform!\n')
        tidyUp()
        return
    end

    % Run transform
    obj.runAffineTransform
    tidyUp()
    obj.scannersCalibrated = true; % TODO -- Assumes that calibration was a success

    if nargout>0
        varargout{1} = OUT;
    end

    function tidyUp
        obj.cam.exposure = obj.settings.camera.default_exposure;
        obj.setLaserInMW(0)
        obj.zeroScanners;
    end % tidyUp

end % calibrateScanners
