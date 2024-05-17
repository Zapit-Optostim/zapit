function drawROI_Callback(obj,~,~)
    % Draw a ROI to image a sub-set of the full FOV
    %
    % Purpose
    % This callback allows for imaging a sub-set of the full FOV

    % Disable button until ROI has been drawn
    obj.ROIButton.Enable='off';
    obj.ResetROIButton.Enable='off'; %There is a callback on ROI size that will cause this to re-enable automatically as needed

    % Stop preview to make things as smooth as possible
    obj.stopPreview

    % Draw box and get coords
    imSize = obj.model.imSize;
    mixPix = obj.model.settings.camera.micronsPerPixel*1E-3;

    xl = obj.hImAx.XLim;
    yl = obj.hImAx.YLim;

    borderMM = 1;

    defaultPos = [xl(1)+borderMM, ...
                  yl(1)+borderMM, ...
                    (mixPix*imSize(1))-borderMM*2, ...
                    (mixPix*imSize(2))-borderMM*2];

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

    % Then subtract the offset
    xl = xl / mixPix;
    xl = xl - min(xl) + 1;

    yl = yl / mixPix;
    yl = yl - min(yl) + 1;

    % Flip ROI if the image is flippes
    if  obj.model.settings.camera.flipImageLR == 1
        % Flip along x
        rect_pos(1) = (rect_pos(1) + rect_pos(3)) * -1;
    end

    if  obj.model.settings.camera.flipImageUD == 1
        % Flip along x
        rect_pos(2) = (rect_pos(2) + rect_pos(4)) * -1;
    end


    rect_pos(1) = rect_pos(1) + xl(2)/2;
    rect_pos(2) = rect_pos(2) + yl(2)/2;


    delete(L)
    delete(roi)



    %  We have obtained this in local image coords so if user is drawing a ROI on a zoomed-in image we need to
    % add the existing offset.
    try
    originalROI = obj.model.cam.ROI;
    originalROI(3:4) = 0;
    newROI = originalROI + rect_pos;


    obj.model.cam.ROI = round(newROI);
    catch ME
        fprintf('ROI drawing failed with error:\n"%s"\n', ME.message)
        fprintf("\nIf this keeps happening, please file a bug report\n")
    end
    obj.refreshImage % Re-draw everything so axes display the correct units in mm

    % Cache this value to the settings file
    obj.model.settings.cache.ROI = obj.model.cam.ROI;

    obj.ROIButton.Enable='on';
    obj.startPreview  % re-start the camera
    obj.model.wipeScannerCalib % Because any existing scanner calib will no longer hold

end % drawROI



function clickCallback(src,evt)
    % Returns control to the user if they double-click on the ROI
    if strcmp(evt.SelectionType,'double')
        uiresume(src.Parent.Parent.Parent);
    end
end
