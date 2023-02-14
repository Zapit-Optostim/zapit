function [R,C] = generateScannerCalibrationPoints(obj, doPlot)
    % Generate the calibration points for the scanner calibration
    %
    % function [R,C] = zapit.pointer.generateScannerCalibrationPoints(doPlot)
    %
    % Purpose
    % Generate the scanner calibration point locations
    %
    % Inputs
    % doPlot - false by default. If true, spawn a new window an plot points.
    %
    % Outputs
    % R and C - the rows and columns where the laser will be sent
    %
    % See also:
    % zapit.pointer.calibrateScanners

    if nargin<2
        doPlot = false;
    end

    % Unique row and column values to sample
    pointSpacingInMM = obj.settings.calibrateScanners.pointSpacingInMM;
    bufferMM = obj.settings.calibrateScanners.bufferMM; % So we don't stimulate very close to the edges

    % Get mm per pixel
    mixPix = obj.settings.camera.micronsPerPixel;
    mmPix = mixPix * 1E-3;

    imSizeRangeMM = (obj.imSize * mmPix)/2;

    pixel_colsMM = (-imSizeRangeMM(1)+bufferMM) : pointSpacingInMM : (imSizeRangeMM(1)-bufferMM);
    pixel_rowsMM = (-imSizeRangeMM(2)+bufferMM) : pointSpacingInMM : (imSizeRangeMM(2)-bufferMM);


    % Calculate a set product to go to all combinations
    [R,C] = meshgrid(pixel_rowsMM,pixel_colsMM);

    R = R(:);
    C = C(:);

    if ~doPlot
        return
    end

    zapit.utils.focusNamedFig(mfilename)

    plot(C, R, 'ok', 'MarkerFaceColor', [1,1,1]*0.5)

    xlim([-imSizeRangeMM(1),imSizeRangeMM(1)])
    ylim([-imSizeRangeMM(2),imSizeRangeMM(2)])

    xlabel('Row (mm)')
    ylabel('Column (mm)')


end % generateScannerCalibrationPoints
