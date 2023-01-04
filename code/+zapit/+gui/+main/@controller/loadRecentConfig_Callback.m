function loadRecentConfig_Callback(obj)
    % Load stim config on button press
    %
    % zapit.gui.main.controller.loadRecentConfig_Callback
    %
    % Purpose
    % Loads stim config on button press and add to the list of previously loaded files
    %
    %
    

    % TODO -- wipe any plot details related to this config.
    obj.model.cam.stopVideo;


    pathToConfig = obj.LoadRecentDropDown.Value.fullPath{1};

    obj.model.stimConfig = zapit.stimConfig(pathToConfig);
    obj.model.cam.startVideo;

end
