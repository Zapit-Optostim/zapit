function loadRecentConfig_Callback(obj)
    % Load stim config on button press
    %
    % zapit.gui.main.controller.loadRecentConfig_Callback
    %
    % Purpose
    % Loads stim config on button press and add to the list of previously loaded files
    %
    %
    

    isCamRunning = obj.model.cam.isrunning;
    if isCamRunning
        obj.model.cam.stopVideo;
    end

    % TODO -- wipe any plot details related to this config.


    pathToConfig = obj.LoadRecentDropDown.Value.fullPath{1};

    obj.model.stimConfig = zapit.stimConfig(pathToConfig);


    if isCamRunning
        obj.model.cam.startVideo;
    end

end % loadRecentConfig_Callback
