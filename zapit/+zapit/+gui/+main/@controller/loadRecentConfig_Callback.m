function loadRecentConfig_Callback(obj)
    % Load stim config on button press
    %
    % zapit.gui.main.controller.loadRecentConfig_Callback
    %
    % Purpose
    % Loads stim config from list of previously loaded files.
    % Will run loadStimConfig_Callback, so there are not issues with redundant code.
    %

    pathToConfig = obj.LoadRecentDropDown.Value.fullPath{1};
    obj.model.stimConfig = zapit.stimConfig(pathToConfig);

end % loadRecentConfig_Callback
