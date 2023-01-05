function test_full_view

    z = view;

    image(rand(1200,1600),'Parent',z.hImAx);

    z.hImAx.XLim = [1,1600];
    z.hImAx.YLim = [1,1200];

    pan(z.hImAx,'off')
    zoom(z.hImAx,'off')

    roi =v'Parent',z.hImAx,'Position',[100,100,900,900]);

    roi.Label='Adjust then double-click';

    % The only way I can find to move the label to the centre
    roi.RotationAngle=1E-10;

        % So control is returned if user double-clicks
    L=addlistener(roi,'ROIClicked',@clickCallback);

    uiwait(uF); %needs parent to avoid new figure

    % Get the ROI position
    rect_pos = roi.Position;
    fprintf('Rectangle pos was %0.2f, %0.2f, %0.2f, %0.2f\n', rect_pos)
    delete(roi)

end % testROI



function clickCallback(src,evt)
    % Returns control to the user if they double-click on the ROI
    if strcmp(evt.SelectionType,'double')
        uiresume(src.Parent.Parent); %needs parent to avoid full figure
    end
end
