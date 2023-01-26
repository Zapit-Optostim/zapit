function calibrateSample_Callback(obj,~,~)
    % Initiates the process of calibrating the sample
    %
    % zapit.gui.main.controller.calibrateSample_Callback
    %
    % Purpose
    % We need a transform that takes us from the camera view to stereotaxic coordinates. 
    % This method initiates an interactive process that achives this. It asks the user to
    % to identify two reference points on skull surface. Typically this will be
    % bregma plus one more  point. The results are returned as two columns: first x then y coords
    %


    if nargin>1
        % Only set GUI state if the *user* clicked the button
        % rather than than harmonizeGUIstate calling it.
        obj.GUIstate = mfilename;
    end

    isCamRunning = obj.model.cam.isrunning;
    if isCamRunning
        obj.model.cam.stopVideo;
    end

    obj.model.sampleCalibrated = false;
    obj.model.refPointsSample(:) = 0;
    obj.model.calibratedBrainOutline = [];

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
        obj.removeOverlays('brainOutline')
        obj.removeOverlays('bregma')
        obj.model.refPointsSample(:) = 0;
        obj.hFig.WindowButtonDownFcn = [];
        obj.hFig.WindowButtonMotionFcn = [];
        obj.model.sampleCalibrated = false;
    else
        obj.removeOverlays('brainOutline')
        obj.removeOverlays('bregma')
        obj.hFig.WindowButtonDownFcn = [];
        obj.hFig.WindowButtonMotionFcn = [];
        obj.model.sampleCalibrated = true;
    end


    if sum(abs(obj.model.refPointsSample(:)))>0
        b = obj.atlasData.whole_brain.boundaries_stereotax{1};
        calib = zapit.utils.rotateAndScaleCoords(fliplr(b)', ...
                 obj.model.refPointsStereotaxic, ...
                 obj.model.refPointsSample)';

        obj.model.calibratedBrainOutline = calib;
        hold(obj.hImAx,'on')

        obj.plotOverlayHandles.brainOutlineCalibrated = ...
           plot(calib(:,1), calib(:,2), '-g', 'linewidth', 2, 'parent', obj.hImAx);
        hold(obj.hImAx,'off')
    end


    if isCamRunning
        obj.model.cam.startVideo;
    end

end % calibrateSample_Callback

