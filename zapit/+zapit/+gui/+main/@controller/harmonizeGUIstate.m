function harmonizeGUIstate(obj,~,~)
    % Ensure a new action requested by the user respects the current state of the GUI
    %
    % function zapit.pointer.harmonizeGUIstate
    %
    % Purpose
    % Ensure that the GUI transitions smoothly regardless of what buttons the user clicks. 
    % For example, if a check galvo calib operation is running and the user clicks the
    % Point Mode button, the system should transition from one operation to the other 
    % with the UI elements updating accordingly. Since there are many such combinations
    % of events, we wish to coordinate these in one place to avoid repeating code. 


    stateStructure = struct('GUIstate', 'idle', 'UIelement', []);
    stateStructure(end+1) = struct('GUIstate', 'pointButton_Callback', 'UIelement', 'PointModeButton');
    stateStructure(end+1) = struct('GUIstate', 'catAndMouseButton_Callback', 'UIelement', 'CatMouseButton');
    stateStructure(end+1) = struct('GUIstate', 'calibrateScanners_Callback', 'UIelement', 'RunScannerCalibrationButton');
    stateStructure(end+1) = struct('GUIstate', 'checkScannerCalib_Callback', 'UIelement', 'CheckCalibrationButton');

    stateStructure(end+1) = struct('GUIstate', 'paintBrainBorder_Callback', 'UIelement', 'PaintbrainborderButton');
    stateStructure(end+1) = struct('GUIstate', 'zapAllCoords_Callback', 'UIelement', 'ZapallcoordsButton');
    stateStructure(end+1) = struct('GUIstate', 'zapSite_Callback', 'UIelement', 'ZapSiteButton');
    stateStructure(end+1) = struct('GUIstate', 'paintArea_Callback', 'UIelement', 'PaintareaButton');
    stateStructure(end+1) = struct('GUIstate', 'calibrateSample_Callback', 'UIelement', 'CalibrateSampleButton');

    verbose = true;
    for ii=1:length(stateStructure)
        tS = stateStructure(ii);

        if strcmp(tS.GUIstate, obj.GUIstate) || strcmp('idle', tS.GUIstate)
            continue
        end

        if isa(obj.(tS.UIelement),'matlab.ui.control.StateButton') && ...
            obj.(tS.UIelement).Value == 1
            if verbose
                fprintf('Setting obj.%s.Value to zero\n', tS.UIelement)
            end
            obj.(tS.UIelement).Value = 0;
            obj.(tS.GUIstate); %Because callback name == GUI state
        end
    end % for

end % harmonizeGUIstate
