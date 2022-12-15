function varargout = logPoints(obj)
    % Log precision of beam pointing: conduct an affine transform to calibrate camera and beam
    %
    % TODO -- I think we need a better name for this method
    %
    % Purpose
    % Moves beam sequentially across a series of locations and records the intended vs
    % actual beam position on the camera image. This allows us to calculate an affine
    % transform that converts a pixel location on the image to the scanner command voltages
    % required to point the beam at that location.
    %
    % Inputs (optional):
    % none
    %
    % Outputs
    % optional - target and actual pixel coordinates in a structure
    %
    % Maja Skretowska - SWC 2021
    % Rob Campbell - SWC 2022

    obj.DAQ.setLaserPowerControlVoltage(0) %TODO -- will replace with call to a laser class

    % lower camera illumination for increased precision in detecting beam location 
    obj.cam.src.Gain = 4; % TODO - hard-coded
    obj.cam.exposure = 3000; % TODO - hard-coded


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

    obj.DAQ.setLaserPowerControlVoltage(1.7) %TODO -- will replace with call to a laser class

    obj.hLastPoint.Visible = 'off';

    hold on
    hPcurrent = plot(obj.hImAx,nan,nan, 'or','MarkerSize',14,'LineWidth',3);
    hPall = plot(obj.hImAx,nan,nan, 'og','MarkerSize',12,'LineWidth',2);
    hold off

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
            hPall.XData(end+1) = out.actualPixelCoords(1);
            hPall.YData(end+1) = out.actualPixelCoords(2);

            set(hPcurrent, 'XData', out.actualPixelCoords(1), 'YData', out.actualPixelCoords(2))
            pause(0.025)
            set(hPcurrent, 'XData', nan, 'YData', nan)
            nPointsRecorded = nPointsRecorded + 1;
        end
        fprintf('.')
    end
    fprintf('\n')
    delete(hPcurrent)

    if nPointsRecorded<3
        fprintf('Failed to record sufficient points!\n')
        tidyUp()
        return
    end
    % Save the recorded output (intended) and incoming (calculated) pixel coordinates 
    % in order to calculate the offset and transformation.
    OUT.targetPixelCoords = cat(1,positionData(:).targetPixelCoords);
    OUT.actualPixelCoords = cat(1,positionData(:).actualPixelCoords);


    % change the illumination of the camera image to high value again
    obj.cam.exposure = 3000; %TODO: likely we should be returning this to the original value

    obj.runAffineTransform(OUT);

    % Now demonstrate that it worked
    % TODO -- have it loop until we stop it.
    hPall.Color=[0,0.7,0];
    for ii=1:size(OUT.actualPixelCoords,1)
        [xVolt,yVolt] = obj.pixelToVolt(OUT.actualPixelCoords(ii,1),...
                 OUT.actualPixelCoords(ii,2));
        obj.DAQ.moveBeamXY([xVolt,yVolt])
        pause(0.05)
    end

    tidyUp()

    if nargout>0
        varargout{1} = OUT;
    end

    function tidyUp
        obj.DAQ.setLaserPowerControlVoltage(0) %TODO -- will replace with call to a laser class
        obj.zeroScanners;
        obj.hLastPoint.Visible = 'on';
        delete(hPall)
    end

end % logPoints
