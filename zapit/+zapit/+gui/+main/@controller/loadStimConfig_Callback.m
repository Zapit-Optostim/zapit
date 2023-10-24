function loadStimConfig_Callback(obj,src,~)
    % Load stim config on button press
    %
    % zapit.gui.main.controller.loadStimConfig_Callback
    %
    % Purpose
    % Loads stim config on button press and add to the list of previously loaded files.
    % Note this callback is triggered by loading of recent files also.
    %

    % Stop video first as the video running seems to really slow down loading
    isCamRunning = obj.model.cam.isrunning;
    if isCamRunning
        obj.model.cam.stopVideo;
    end

    % Wipe any plot details related to this config.
    obj.OverlaystimsitesButton.Value=0; % Unchecks button if checked
    obj.overlayStimSites_Callback; % Will remove any overlays present


    % We use this method to load from the recents menu or to interactively load or from the CLI
    if ischar(src)
        % User supplied a path (unlikely as is not documeneted)
        [fpath,pointsFile,ext] = fileparts(src);
        pointsFile = [pointsFile,ext];
    elseif ~isempty(src.UserData) % It came from the recents menu
        [fpath,pointsFile,ext] = fileparts(src.UserData);
        pointsFile = [pointsFile,ext];
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
    obj.model.loadStimConfig(pathToConfig);
    obj.addStimConfigToRecents(pointsFile,fpath); % Add to the list of recently loaded files


    % Update text indicating which config file has been loaded
    [~,fname,ext] = fileparts(obj.model.stimConfig.configFileName);

    obj.ConfigLoadedTextLabel.Text = ['Config Loaded: ', fname,ext];

    % Overlay stim points
    if obj.model.isReadyToStim
        obj.OverlaystimsitesButton.Value=1; % Checks button
        obj.overlayStimSites_Callback; % Adds points
    end

    if isCamRunning
        obj.model.cam.startVideo;
    end

    % Update the drop-down that allows us to present the stimuli
    obj.updateTestSiteDropdown;

end % loadStimConfig_Callback
