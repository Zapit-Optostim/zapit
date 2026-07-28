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

    % Route through the model's loader so the parent is attached, the presentability and
    % laser-power checks run, and the GUI updates via the stimConfig listener. (Setting
    % obj.model.stimConfig directly here would skip all of that.)
    obj.model.loadStimConfig(pathToConfig);

end % loadRecentConfig_Callback
