function calibrateSample_Callback(obj,~,~)


    % Ask the user to identify reference point on skull surface. Typically this will be
    % bregma plus one more  point. The results are returned as two columns: first x then y coords
    obj.model.cam.stopVideo


    hold(obj.hImAx,'on')
    obj.plotOverlayHandles.brainOutline = plot(nan,nan,'c-','linewidth', 2, 'parent', obj.hImAx);
    obj.plotOverlayHandles.bregma = plot(nan,nan,'or','markerfacecolor','r','parent',obj.hImAx);
    hold(obj.hImAx,'off')

    obj.removeOverlays('brainOutlineCalibrated');
    obj.model.refPointsSample = zeros(2); % wipe any previous data

    obj.nInd = 1;

    obj.hFig.WindowButtonDownFcn = @obj.calibrateSampleClick_Callback;
    obj.hFig.WindowButtonMotionFcn = @obj.calibrateSampleRescaleOutline_Callback;

    while obj.nInd<3
        pause(0.05)

    end


    response = questdlg('Are you happy with the calibration?', ...
                        'All good?','Yes?','No','No');

    if isempty(response) || strcmp(response,'No')
        delete(obj.plotOverlayHandles.brainOutline)
        delete(obj.plotOverlayHandles.bregma)
        obj.model.refPointsSample(:) = 0;
        obj.hFig.WindowButtonDownFcn = [];
        obj.hFig.WindowButtonMotionFcn = [];
    else
        delete(obj.plotOverlayHandles.brainOutline)
        delete(obj.plotOverlayHandles.bregma)
        obj.hFig.WindowButtonDownFcn = [];
        obj.hFig.WindowButtonMotionFcn = [];
    end

    if sum(obj.model.refPointsSample(:))>0
        b = obj.atlasData.whole_brain.boundaries_stereotax{1};
        calib = zapit.utils.coordsRotation(fliplr(b)', ...
                 obj.model.refPointsStereotaxic, ...
                 obj.model.refPointsSample)';

        obj.model.calibratedBrainOutline = calib;
        hold(obj.hImAx,'on')

        obj.plotOverlayHandles.brainOutlineCalibrated = ...
           plot(calib(:,1), calib(:,2), '-g', 'linewidth', 2, 'parent', obj.hImAx);
        hold(obj.hImAx,'off')
    end

    obj.model.cam.startVideo
end % calibrateSample_Callback

