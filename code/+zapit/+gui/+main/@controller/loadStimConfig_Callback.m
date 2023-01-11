function loadStimConfig_Callback(obj,src,~)
    % Load stim config on button press
    %
    % zapit.gui.main.controller.loadStimConfig_Callback
    %
    % Purpose
    % Loads stim config on button press and add to the list of previously loaded files
    %
    %
    
    obj.model.cam.stopVideo; % Stop video first as the video running seems to really slow down loading

    % We use this method to load from the recents menu or to interactively load or from the CLI
    if ischar(src)
        % User supplied a path (unlikely as is not documeneted)
        [fpath,pointsFile,ext] = fileparts(src);
        pointsFile = [pointsFile,ext];
    elseif ~isempty(src.UserData) % It came from the recents menu
        [fpath,pointsFile,ext] = fileparts(src.UserData);
        pointsFile = [pointsFile,ext];
        disp('LOADING')
    elseif isempty(src.UserData) % It's the load menu
        % UI file getter
        [pointsFile,fpath] = uigetfile({'*.yml','*.yaml'},'Pick a config file');

        if pointsFile == 0
            % Likely user hit cancel so we just do nothing
            obj.model.cam.startVideo;
            return
        end
    end

    pathToConfig = fullfile(fpath,pointsFile);
    if ~exist(pathToConfig,'file')
        return
    end

    fprintf('Loading %s\n', pathToConfig)
    obj.model.stimConfig = zapit.stimConfig(pathToConfig);
    obj.addStimConfigToRecents(pointsFile,fpath); % Add to the list of recently loaded files


    % Update text indicating which config file has been loaded
    [~,fname,ext] = fileparts(obj.model.stimConfig.configFileName);

    obj.ConfigLoadedTextLabel.Text = ['Config Loaded: ', fname,ext];

    % Update the drop-down that allows us to present the stimuli
    obj.updateTestSiteDropdown;

    obj.model.cam.startVideo;

end % loadStimConfig_Callback
