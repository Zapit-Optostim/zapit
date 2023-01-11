function loadStimConfig_Callback(obj,~,~)
    % Load stim config on button press
    %
    % zapit.gui.main.controller.loadStimConfig_Callback
    %
    % Purpose
    % Loads stim config on button press and add to the list of previously loaded files
    %
    %
    
    obj.model.cam.stopVideo; % Stop video first as the video running seems to really slow down loading
    [pointsFile,fpath] = uigetfile({'*.yml','*.yaml'},'Pick a config file');

    if pointsFile == 0
        % Likely user hit cancel so we just do nothing
        obj.model.cam.startVideo;
        return
    end

    pathToConfig = fullfile(fpath,pointsFile);

    fprintf('Loading %s\n', pathToConfig)
    obj.model.stimConfig = zapit.stimConfig(pathToConfig);
    obj.addStimConfigToRecents(pointsFile,fpath); % Add to the list of recently loaded files


    % Update text indicating which config file has been loaded
    [~,fname,ext] = fileparts(obj.model.stimConfig.configFileName);

    obj.ConfigLoadedTextLabel.Text = ['Config Loaded: ',fname,ext];
    obj.model.cam.startVideo;
end
