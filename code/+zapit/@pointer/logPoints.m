function varargout = logPoints(obj, nPoints, doPointGrid)
    % Log precision of beam pointing: conduct an affine transform to calibrate camera and beam
    %
    % Purpose
    % Moves beam sequentially across a series of locations and records the intended vs
    % actual beam position on the camera image. This allows us to calculate an affine
    % transform that converts a pixel location on the image to the scanner command voltages
    % required to point the beam at that location.
    %
    % Inputs (optional):
    % nPoints - how many points to record. If empty or less than three, a set of hard-coded
    % coordinates are scanned.
    %
    % Outputs
    % optional - target and actual pixel coordinates in a structure
    %
    % Maja Skretowska - SWC 2021
    % Rob Campbell - SWC 2022

    % lower camera illumination for increased precision in detecting beam location 
    obj.cam.src.Gain = 1; % TODO - hard-coded
    obj.cam.exposure = 3000; % TODO - hard-coded

    if nargin<2
        nPoints = [];
    end


    % Wipe the previous transform
    obj.transform = [];

    if isempty(nPoints) || nPoints<3
        doPointGrid = true;
    else
        doPointGrid = false;
    end

    if doPointGrid

        % TODO -- this works but I don't know why and I don't know
        % why the clicky version fails.
        % if no varargin given, use standard coordinates
        % TODO -- what are these hardcoded numbers??

        % Unique row and column values to sample
        pixel_rows = [550:200:1300]+300; % TODO -- why do we nee dto add the constant?
                                         % Beam is not going to the requested location
        pixel_cols = [250:125:750];

        % Calculate a set product to go to all combinations
        [R,C] = meshgrid(pixel_rows,pixel_cols);

        R = R(:);
        C = C(:);

        % change pixel coords into voltage %TODO -- R and C correct?
        [rVolts(:,1), rVolts(:,2)] = obj.pixelToVolt(R,C);

        fprintf('Running calibration')
        for ii=1:length(R)
            % feed volts into scan mirrors, wait for precise image
            % without smudges and take position in pixels
            obj.hTask.writeAnalogData([rVolts(ii,:), 3.3]);
            pause(0.125)
            v(ii)=obj.getLaserPosAccuracy([R(ii), C(ii)]);
            drawnow
            fprintf('.')
        end
        fprintf('\n')

    else
        % TODO -- DOES NOT WORK RIGHT NOW FOR SOME REASON

        % same procedure as above, but using points clicked by user
        fprintf('Click on %d points whilst pressing ALT\n', nPoints)
        ind = 1;
        while ind <= nPoints

            obj.hTask.writeAnalogData([0 0 0])
            title(obj.hImAx, string(ind));
            figure(obj.hFig)

            points = obj.hImAx.CurrentPoint([1 3]);
            waitforbuttonpress;
            pause(0.125)
            tmp = obj.getLaserPosAccuracy(points);
            if ~isempty(tmp)
                v(ind) = tmp;
                fprintf('%d points clicked\n', ind)
                ind = ind +1;
            end
        end

    end % if doPointGrid


    % save recorded output (intended) and incoming (calculated)
    % pixel coordinates to calculate the offset and transformation
    OUT.targetPixelCoords = cat(1,v(:).targetPixelCoords);
    OUT.actualPixelCoords = cat(1,v(:).actualPixelCoords);


    % change the illumination of the camera image to high value again
    obj.cam.exposure = 3000; %TODO: likely we should be returning this to the original value

    obj.runAffineTransform(OUT);
    obj.hTask.writeAnalogData([0 0 0]); % Zero beam and turn off laser. TODO -- we have nicer system for this in the new DAQ class

    % TODO: now demonstrate that it worked


    if nargout>0
        varargout{1} = OUT;
    end
end % logPoints
