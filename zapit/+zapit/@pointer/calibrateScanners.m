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


    % TODO -- this works but I don't know exactly why. I don't follow what the dimensions mean
    % Generate points that will sample the imaged area.
    % User should have cropped the FOV so we shouldn't be stimulating silly large positions


    % Unique row and column values to sample
    pointSpacingInPixels = obj.settings.calibrateScanners.pointSpacingInPixels;
    bufferPixels = obj.settings.calibrateScanners.bufferPixels; % So we don't stimulate very close to the edges


    pixel_rows = bufferPixels:pointSpacingInPixels:obj.imSize(1)-bufferPixels;
    pixel_cols = bufferPixels:pointSpacingInPixels:obj.imSize(2)-bufferPixels;

    % Get mm per pixel
    mixPix = obj.settings.camera.micronsPerPixel;
    mmPix = mixPix * 1E-3;

    pixel_rowsMM = (pixel_rows * mmPix);
    pixel_rowsMM = pixel_rowsMM - mean(pixel_rowsMM);
    pixel_colsMM = pixel_cols * mmPix;
    pixel_colsMM = pixel_colsMM - mean(pixel_colsMM);

    % Calculate a set product to go to all combinations
    [R,C] = meshgrid(pixel_rowsMM,pixel_colsMM);

    %TODO -- are R and C correct?
    R = R(:);
    C = C(:);

    % change mm coords into voltage 
    [rVolts(:,1), rVolts(:,2)] = obj.mmToVolt(R,C);
    obj.DAQ.moveBeamXY(rVolts(1,:)); % Move to first position

    pause(0.05)

    obj.setLaserInMW(obj.settings.calibrateScanners.calibration_power_mW)

    % Get the current frame with laser off
    backgroundFrame = obj.returnCurrentFrame(10);
    backgroundFrame = cast(mean(backgroundFrame,3),class(backgroundFrame));

    ind=1;
    verbose=false;
    for ii=1:length(R)
        % feed volts into scan mirrors, wait for precise image
        % without smudges and take position in pixels
        obj.DAQ.moveBeamXY(rVolts(ii,:));
        pause(0.1)
        %obj.getLaserPosAccuracy([R(ii), C(ii)]);

        % Attempt to get laser position and append to list if the position was found
        out = obj.getLaserPosAccuracy([R(ii), C(ii)], backgroundFrame, true);
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


    if ind<3
        fprintf('Failed to record sufficient points!\n')
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
