function refAPDropDown_Callback(obj, ~, ~)
    % Callback that runs when the value of RefAPDropDown is changed
    %
    % function zapit.gui.main.controller.refAPDropDown_Callback
    %
    % Purpose
    % This callback alters the value of the RefAPDropDown.refAP setting
    % when the user chooses from the drop-down.
    %

    tok = regexp(obj.RefAPDropDown.Value,'([+-]\d) mm','Tokens');

    refAP = str2num(tok{1}{1});
    obj.model.settings.calibrateSample.refAP = refAP;

end % refAPDropDown_Callback
