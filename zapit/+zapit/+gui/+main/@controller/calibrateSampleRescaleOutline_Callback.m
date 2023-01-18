function calibrateSampleRescaleOutline_Callback(obj,~,evt)
    % This callback scales and rotates the ARA outline as the mouse moves during sample calibration
    %
    % zapit.gui.main.controller.calibrateSampleRescaleOutline_Callback
    %
    % Purpose
    % Responds to motion of the mouse over the axes during sample calibration. Allows the
    % brain outline to be scaled and rotated around bregma.
    %
    % Rob Campbell - SWC 2023

    C = get(obj.hImAx, 'CurrentPoint');
    X = C(1,1);
    Y = C(1,2);

    xl = obj.hImAx.XLim;
    yl = obj.hImAx.YLim;
    if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
        return
    end
    
    % The boundaries of the brain in mm
    b = obj.atlasData.whole_brain.boundaries_stereotax{1};

    if obj.nInd==1
        % follow mouse
        obj.plotOverlayHandles.brainOutline.XData = b(:,2)+X;
        obj.plotOverlayHandles.brainOutline.YData = b(:,1)+Y;
    end

    if obj.nInd==2
        % Rotate and scale only if mouse cursor is over 1 mm from bregma
        err = obj.model.refPointsSample(1,:)-[X,Y];
        rms_err = sum(sqrt(err.^2));
        if rms_err<0.5
            return
        end
        obj.model.refPointsSample(obj.nInd,:) = [X,Y];
        newpoint = zapit.utils.rotateAndScaleCoords(fliplr(b)', obj.model.refPointsStereotaxic, obj.model.refPointsSample)';
        newpoint = fliplr(newpoint);
        obj.plotOverlayHandles.brainOutline.XData = newpoint(:,2);
        obj.plotOverlayHandles.brainOutline.YData = newpoint(:,1);
    end
end
