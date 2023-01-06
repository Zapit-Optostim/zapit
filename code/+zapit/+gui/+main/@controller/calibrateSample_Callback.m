function calibrateSample_Callback(obj,~,~)


    % Ask the user to identify reference point on skull surface. Typically this will be
    % bregma plus one more  point. The results are returned as two columns: first x then y coords
    obj.model.cam.stopVideo


    hold(obj.hImAx,'on')
    obj.plotOverlayHandles.brainOutline = plot(nan,nan,'-','linewidth', 2, 'parent', obj.hImAx);
    obj.plotOverlayHandles.bregma = plot(nan,nan,'or','markerfacecolor','r','parent',obj.hImAx);
    hold(obj.hImAx,'off')


    obj.model.refPointsSample = zeros(2); % wipe any previous data
    atlasRef = obj.model.refPointsStereotaxic;


    obj.nInd = 1;

    obj.hFig.WindowButtonDownFcn = @obj.down_callback;
    obj.hFig.WindowButtonMotionFcn = @obj.line_extender;




    obj.model.cam.startVideo
end % calibrateSample_Callback






function isPressed = isShiftPressed
    mod = get(gcbo,'currentModifier');
    isPressed = false;
    if length(mod)==1
        isPressed = strcmp(mod{1},'shift');
    end
end



