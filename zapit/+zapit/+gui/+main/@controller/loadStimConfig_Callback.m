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

    % NOTE: the "Config Loaded" text, the stim-site overlay, the test-site drop-down and the
    % laser-power warning are all handled by stimConfigLoaded_Callback, which fires from a
    % listener on the model's stimConfig property. That means they update for CLI loads too
    % (issue #132), so we do not do them here.

    % We use this method to load from the recents menu or to interactively load or from the CLI
    if ischar(src)
        % User supplied a path (unlikely as is not documented)
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
        obj.model.cam.startVideo;
        return
    end

    fprintf('Loading %s\n', pathToConfig)
    success = obj.model.loadStimConfig(pathToConfig);

    % The model refuses configs that contain a condition which can not be presented. In that
    % case any previously loaded config is left in place; we tell the user and stop here
    % without touching the recents list or the "Config Loaded" label.
    if ~success
        if isCamRunning
            obj.model.cam.startVideo;
        end
        errordlg(sprintf(['Config "%s" was not loaded: one or more conditions can not be ', ...
            'presented with the current blanking and modulation settings. See the console ', ...
            'for which conditions and how to fix them.'], pointsFile), 'Config not loaded')
        return
    end

    obj.addStimConfigToRecents(pointsFile,fpath); % Add to the list of recently loaded files

    % The GUI (text label, overlay, drop-down, laser-power dialog) has already updated via
    % the stimConfig listener (stimConfigLoaded_Callback), which fired inside
    % obj.model.loadStimConfig above.

    if isCamRunning
        obj.model.cam.startVideo;
    end

end % loadStimConfig_Callback
