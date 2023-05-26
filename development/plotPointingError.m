function out = plotPointingError(data,im)
    % Testing code for plotting nicely the beam pointing error
    %
    % Example
    %
    % Run at the CLI:
    %  [R,C] = hZP.generateScannerCalibrationPoints;
    %  [out,im] = hZP.measurePointingAccuracy([C,R]);
    %  plotPointingError(out,im) % Second optional
    %
    %
    % To plot data from the last calibration in the API:
    % plotPointingError(hZP.calibrateScannersPosData)
    % That will, however, tell you how much it needed to shift
    % the points for the translation.
    %
    %
    % Rob Campbell



    if nargin<2
        im = [];
    end

    zapit.utils.focusNamedFig(mfilename);
    clf


    % Plot as circles the error size
    subplot(2,2,1)
    ax = cla;
    hold(ax,'on')

    if ~isempty(im)
        % The code for the axis is taken from zapit.pointer.refreshImage
        % It plots the image in mm not pixels
        s=zapit.settings.readSettings;
        mixPix = s.camera.micronsPerPixel;

        imSize = size(im);
        xD = (1:imSize(2)) * mixPix * 1E-3;
        yD = (1:imSize(1)) * mixPix * 1E-3;

        xD = xD - mean(xD);
        yD = yD - mean(yD);
        imagesc(im,'XData',xD, 'YData', yD, 'Parent',ax);
        colormap gray
    end


    pltData = reshape([data.targetCoords],2,length(data))';
    viscircles(pltData,[data.totalErrorMicrons]/1000);

    % Overlay index number of the presentation
    for ii=1:length(data)
        text(data(ii).targetCoords(1), ...
          data(ii).targetCoords(2), num2str(ii), ...
          'FontSize', 8)
    end

    hold(ax,'off')
    axis equal tight

    subplot(2,2,2)
    gca = cla;
    hold(gca,'on')

    for ii=1:length(data)

        plot(data(ii).actualCoords(1), ...
            data(ii).actualCoords(2), ...
            'r.', 'MarkerSize', 1);
        plot(data(ii).targetCoords(1), ...
            data(ii).targetCoords(2), ...
            'k.', 'MarkerSize', 1);

        plot([data(ii).targetCoords(1),data(ii).actualCoords(1)], ...
            [data(ii).targetCoords(2),data(ii).actualCoords(2)], ...
            '-', 'Color', [1,1,1]* 0.5);

    end

    hold(gca,'off')


    subplot(2,2,3)
    hist([data.totalErrorMicrons])
    xlabel('Total error in microns')

end %plotPointingError
