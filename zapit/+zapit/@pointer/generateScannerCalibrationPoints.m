function [R,C] = generateScannerCalibrationPoints(obj, varargin)
    % Generate the calibration points for the scanner calibration
    %
    % function [R,C] = zapit.pointer.generateScannerCalibrationPoints(param1,val1,...t)
    %
    % Purpose
    % Generate the scanner calibration point locations
    %
    % Inputs (param/val pairs)
    % 'pointSpacingInMM' - distance in mm between points. By default the value in the GUI is chosen
    % 'bufferMM' - distance in mm between image edge and points. By default the value in the GUI is chosen.
    % 'doPlot' - false by default. If true, spawn a new window an plot points.
    %
    % Outputs
    % R and C - the rows and columns where the laser will be sent
    %
    % See also:
    % zapit.pointer.calibrateScanners



    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    %Parse optional arguments
    params = inputParser;
    params.CaseSensitive = false;

    params.addParameter('pointSpacingInMM', obj.settings.calibrateScanners.pointSpacingInMM, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('bufferMM', obj.settings.calibrateScanners.bufferMM, @(x) isnumeric(x) && isscalar(x))
    params.addParameter('doPlot', false, @(x) islogical(x) || x==0 || x==1);

    params.parse(varargin{:});

    pointSpacingInMM=params.Results.pointSpacingInMM;
    bufferMM=params.Results.bufferMM;
    doPlot=params.Results.doPlot;


    % Get mm per pixel
    mixPix = obj.settings.camera.micronsPerPixel;
    mmPix = mixPix * 1E-3;

    imSizeRangeMM = (obj.imSize * mmPix)/2;

    pixel_colsMM = (-imSizeRangeMM(1)+bufferMM) : pointSpacingInMM : (imSizeRangeMM(1)-bufferMM);
    pixel_rowsMM = (-imSizeRangeMM(2)+bufferMM) : pointSpacingInMM : (imSizeRangeMM(2)-bufferMM);

    % The user has almost certainly applied a ROI and so we must add the offset assoicated with that.
    origImCentreInPixels = obj.cam.vid.VideoResolution/2;
    currentImCentre =  (obj.cam.ROI(3:4)/2) + obj.cam.ROI(1:2);

    delta = origImCentreInPixels - currentImCentre;
    delta = delta * mmPix;

    pixel_rowsMM = pixel_rowsMM + delta(2);
    pixel_colsMM = pixel_colsMM + delta(1);


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
