function tabChange_Callback(obj,src,~)
    % Runs when user selects a new tab

    currentTab = src.SelectedTab.Title;

    switch currentTab
    case 'Calibrate Scanners'
        if isfield(obj.plotOverlayHandles,'brainOutlineCalibrated')
            obj.plotOverlayHandles.brainOutlineCalibrated.Visible='off';
        end
    case 'Calibrate Sample'
        if isfield(obj.plotOverlayHandles,'brainOutlineCalibrated')
            obj.plotOverlayHandles.brainOutlineCalibrated.Visible='on';
        end
        obj.removeOverlays('hLastPoint')
    end
end
