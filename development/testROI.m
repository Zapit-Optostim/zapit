function testROI


    uF = uifigure;
    uA = uiaxes('Parent',uF);



    uA.DataAspectRatio = [1,1,1]; % Make axis aspect ratio square
    pan(uA,'off')
    zoom(uA,'off')

    roi = images.roi.Rectangle('Parent',uA,'Position',[0.1,0.1,0.8,0.8]);

    roi.Label='Adjust then double-click';

    % The only way I can find to move the label to the centre
    roi.RotationAngle=1E-10;

        % So control is returned if user double-clicks
    L=addlistener(roi,'ROIClicked',@clickCallback);

    uiwait(uF); % Must supply a parent or it spawns a new figure

    % Get the ROI position
    rect_pos = roi.Position;
    fprintf('Rectangle pos was %0.2f, %0.2f, %0.2f, %0.2f\n', rect_pos)
    delete(roi)

end % testROI



function clickCallback(src,evt)
    % Returns control to the user if they double-click on the ROI

    uF = src.Parent.Parent;
    if strcmp(evt.SelectionType,'double')
        uiresume(uF); % Must supply a parent or it spawns a new figure
    end
end
