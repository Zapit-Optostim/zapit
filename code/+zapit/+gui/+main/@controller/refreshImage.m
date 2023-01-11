function refreshImage(obj)
    % Add an image to empty axes or re-plot an image with new XData and YData
    %
    % zapit.gui.main.controller.refreshImage
    %
    % Purpose
    % Insert and empty image into axes. Calling this method with no image in hImAx or an
    % image with empty CData will cause a new image to be produced. The image will be the
    % size specified by the camera ROI and will be plotted in mm using the XData and YData
    % input args to the plotting function. This is to ensure that all plotted images have
    % axes that remain in mm.


    imSize = obj.model.imSize;
    mixPix = obj.model.settings.camera.micronsPerPixel;

    % These variables are the X and Y axis data that allow us to
    % plot the image in units of mm rather pixels.
    xD = (1:imSize(1)) * mixPix * 1E-3;
    yD = (1:imSize(2)) * mixPix * 1E-3;

    xD = xD - mean(xD);
    yD = yD - mean(yD);

    obj.hImLive = image(zeros(imSize), 'XData',xD, 'YData', yD, 'Parent',obj.hImAx);

    % Set axis limits
    obj.hImAx.XLim = [xD(1), xD(end)];
    obj.hImAx.YLim = [yD(1), yD(end)];

    % TODO -- for now we leave the axes on as they help for debugging
    hideAxes = false;

    if hideAxes
        obj.hImAx.XTick = [];
        obj.hImAx.YTick = [];
    else
        obj.hImAx.XTick = round(xD(1):1:xD(end));
        obj.hImAx.YTick = round(yD(1):1:yD(end));
        grid(obj.hImAx,'on')
    end
    obj.hImAx.YDir = 'normal';
    obj.hImAx.DataAspectRatio = [1,1,1]; % Make axis aspect ratio square



    axis(obj.hImAx,'equal')
    axis(obj.hImAx,'tight')
    pan(obj.hImAx,'off')
    zoom(obj.hImAx,'off')
    obj.hImAx.XLimMode = 'manual';
    obj.hImAx.YLimMode = 'manual';

end
