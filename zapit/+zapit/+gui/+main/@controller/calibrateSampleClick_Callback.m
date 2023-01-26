function calibrateSampleClick_Callback(obj)
    % Responds to mouse clicks during sample calibration
    %
    % zapit.gui.main.controller.calibrateSampleClick_Callback
    %
    % Purpose
    % Responds to clicks for placing and translating/rotating the brain border
    % during sample calibration. 
    %
    % Rob Campbell - SWC 2023
    %
    % See also
    % zapit.gui.main.controller.calibrateSampleRescaleOutline_Callback
    % zapit.gui.main.controller.calibrateSampleClick_Callback


    if strcmp(obj.hFig.SelectionType,'alt')
        return
    end
    C = get (obj.hImAx, 'CurrentPoint');
    X = C(1,1);
    Y = C(1,2);

    xl = obj.hImAx.XLim;
    yl = obj.hImAx.YLim;
    if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
        return
    end

    % Paste
    if obj.nInd == 1
        % The boundaries of the brain in mm
        b = obj.atlasData.whole_brain.boundaries_stereotax{1};

        obj.plotOverlayHandles.brainOutline.XData = b(:,2)+X;
        obj.plotOverlayHandles.brainOutline.YData = b(:,1)+Y;

        obj.model.refPointsSample(obj.nInd,:) = [X,Y];
        obj.nInd = obj.nInd + 1;
        obj.plotOverlayHandles.bregma.XData=X;
        obj.plotOverlayHandles.bregma.YData=Y;
    elseif obj.nInd==2
        if zapit.utils.isShiftPressed
            obj.nInd = 1;
            obj.model.refPointsSample(:,2) = 0;
            obj.plotOverlayHandles.bregma.XData=nan;
            obj.plotOverlayHandles.bregma.YData=nan;
        else
            obj.nInd = obj.nInd + 1;
        end %if isShiftPressed
    end %if nInd


end % calibrateSampleClick_Callback
