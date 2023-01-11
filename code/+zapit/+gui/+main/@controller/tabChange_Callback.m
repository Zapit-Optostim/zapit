function tabChange_Callback(obj,src,~)
    % Runs when user selects a new tab

    currentTab = src.SelectedTab.Title;

    switch currentTab
    case 'Calibrate Scanners'
        toggleOverlay('brainOutlineCalibrated','off');
        toggleOverlay('stimConfigLocations','off');
    case 'Calibrate Sample'
        toggleOverlay('brainOutlineCalibrated','on');
        toggleOverlay('stimConfigLocations','on');
        obj.removeOverlays('hLastPoint')
    end


    function toggleOverlay(overlayName,state)
        if isfield(obj.plotOverlayHandles, overlayName)
            obj.plotOverlayHandles.(overlayName).Visible = state;
        end
    end

end



