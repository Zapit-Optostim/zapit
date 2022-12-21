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
    %obj.cam.src.Gain = 4; % TODO - hard-coded
    obj.cam.exposure = obj.settings.calibrateScanners.beam_calib_exposure;


    % Wipe the previous transform
    obj.transform = [];


    % TODO -- this works but I don't know exactly why. I don't follow what the dimensions mean
    % Generate points that will sample the imaged area.
    % User should have cropped the FOV so we shouldn't be stimulating silly large positions

    % Unique row and column values to sample
    pointSpacingInPixels = 200;
    bufferPixels = 200; % So we don't stimulate very close to the edges
    pixel_rows = bufferPixels:pointSpacingInPixels:obj.imSize(1)-bufferPixels;
    pixel_cols = bufferPixels:pointSpacingInPixels:obj.imSize(2)-bufferPixels;


    % Calculate a set product to go to all combinations
    [R,C] = meshgrid(pixel_rows,pixel_cols);

    R = R(:);
    C = C(:);

    % change pixel coords into voltage %TODO -- R and C correct?
    [rVolts(:,1), rVolts(:,2)] = obj.pixelToVolt(R,C);
    obj.DAQ.moveBeamXY(rVolts(1,:)); % Move to first position
    pause(0.05)
    fprintf('Running calibration')

    obj.setLaserInMW(obj.settings.calibrateScanners.calibration_power_mW)
    obj.hLastPoint.Visible = 'off';


    % Set up

    hold(obj.hImAx,'on')
    obj.plotOverlayHandles.(mfilename).hPcurrent = plot(obj.hImAx,nan,nan, 'or','MarkerSize',14,'LineWidth',3);
    obj.plotOverlayHandles.(mfilename).hPall = plot(obj.hImAx,nan,nan, 'og','MarkerSize',12,'LineWidth',2);
    hold(obj.hImAx,'off')

    % Get the current frame with laser off
    backgroundFrame = obj.returnCurrentFrame(10);
    backgroundFrame = cast(mean(backgroundFrame,3),class(backgroundFrame));

    nPointsRecorded = 0;
    for ii=1:length(R)
        % feed volts into scan mirrors, wait for precise image
        % without smudges and take position in pixels
        obj.DAQ.moveBeamXY(rVolts(ii,:));
        pause(0.05)
        %obj.getLaserPosAccuracy([R(ii), C(ii)]);

        % Attempt to get laser position and append to list if the position was found
        out = obj.getLaserPosAccuracy([R(ii), C(ii)], backgroundFrame, true);
        if ~isempty(out)
            positionData(ii) = out;
            obj.plotOverlayHandles.(mfilename).hPall.XData(end+1) = out.actualPixelCoords(1);
            obj.plotOverlayHandles.(mfilename).hPall.YData(end+1) = out.actualPixelCoords(2);

            set(obj.plotOverlayHandles.(mfilename).hPcurrent, ...
                'XData', out.actualPixelCoords(1), ...
                'YData', out.actualPixelCoords(2))
            pause(0.025)
            % Make current point invisible
            set(obj.plotOverlayHandles.(mfilename).hPcurrent, 'XData', nan, 'YData', nan)
            nPointsRecorded = nPointsRecorded + 1;
        end
        fprintf('.')
    end
    fprintf('\n')

    obj.removeOverlays(mfilename)


    if nPointsRecorded<3
        fprintf('Failed to record sufficient points!\n')
        tidyUp()
        return
    end
    % Save the recorded output (intended) and incoming (calculated) pixel coordinates 
    % in order to calculate the offset and transformation.
    OUT.targetPixelCoords = cat(1,positionData(:).targetPixelCoords);
    OUT.actualPixelCoords = cat(1,positionData(:).actualPixelCoords);



    obj.runAffineTransform(OUT);

    % Now demonstrate that it worked
    obj.checkScannerCalib(OUT.actualPixelCoords)

    tidyUp()

    if nargout>0
        varargout{1} = OUT;
    end

    function tidyUp
        obj.cam.exposure = obj.settings.camera.default_exposure;
        obj.setLaserInMW(0)
        obj.zeroScanners;
        obj.hLastPoint.Visible = 'on';
        obj.removeOverlays(mfilename)
    end

end % calibrateScanners