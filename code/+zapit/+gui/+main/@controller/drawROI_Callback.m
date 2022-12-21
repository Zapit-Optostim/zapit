function drawROI_Callback(obj,~,~)
    % Draw a ROI to image a sub-set of the full FOV
    %
    % Purpose
    % This callback allows for imaging a sub-set of the full FOV

    % Disable button until ROI has been drawn
    obj.ROIButton.Enable='off';

    % Draw box and get coords
    imSize = obj.model.imSize;
    defaultPos = [1,1,imSize(2), imSize(1)];
    roi = images.roi.Rectangle(obj.hImAx,'Position',defaultPos);
    roi.Label='Adjust then double-click';

    % The only way I can find to move the label to the centre
    roi.RotationAngle=1E-10;

    % So control is returned if user double-clicks
    L=addlistener(roi,'ROIClicked',@clickCallback);

    uiwait;

    % Get the ROI position
    rect_pos = (roi.Position);
    delete(L)
    delete(roi)


    %  We have obtained this in local image coords so if user is drawing a ROI on a zoomed-in image we need to 
    % add the existing offset.  
    originalROI = obj.model.camera.ROI;
    originalROI(3:4) = 0;
    newROI = originalROI + rect_pos;
    obj.model.camera.ROI = newROI;

    obj.ROIButton.Enable='on';

end % drawROI



function clickCallback(~,evt)
    % Returns control to the user if they double-click on the ROI
    if strcmp(evt.SelectionType,'double')
        uiresume;
    end
end
