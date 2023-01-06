function drawROI_Callback(obj,~,~)
    % Draw a ROI to image a sub-set of the full FOV
    %
    % Purpose
    % This callback allows for imaging a sub-set of the full FOV

    % Disable button until ROI has been drawn
    obj.ROIButton.Enable='off';
    obj.model.cam.stopVideo

    % Draw box and get coords
    imSize = obj.model.imSize;
    mixPix = obj.model.settings.camera.micronsPerPixel*1E-3;

    borderMM = 1;
    defaultPos = [borderMM/2, ...
                borderMM/2, ...
                (mixPix*imSize(1))-borderMM, ...
                (mixPix*imSize(2))-borderMM];

    roi = images.roi.Rectangle('Parent',obj.hImAx,'Position',defaultPos);
    %roi = images.roi.Rectangle('Parent',obj.hImAx);
    roi.Label='Adjust then double-click';

    % The only way I can find to move the label to the centre
    roi.RotationAngle=1E-10;

    % So control is returned if user double-clicks
    L=addlistener(roi,'ROIClicked',@clickCallback);

    uiwait(obj.hFig);

    % Get the ROI position and convert back to pixels
    rect_pos = roi.Position / mixPix;
    delete(L)
    delete(roi)


    %  We have obtained this in local image coords so if user is drawing a ROI on a zoomed-in image we need to 
    % add the existing offset.  
    originalROI = obj.model.cam.ROI;
    originalROI(3:4) = 0;
    newROI = originalROI + rect_pos;
    obj.model.cam.ROI = round(newROI);

    obj.refreshImage % Re-draw everything so axes display the correct units in mm

    obj.ROIButton.Enable='on';
    obj.model.cam.startVideo

end % drawROI



function clickCallback(src,evt)
    % Returns control to the user if they double-click on the ROI
    if strcmp(evt.SelectionType,'double')
        uiresume(src.Parent.Parent.Parent);
    end
end
