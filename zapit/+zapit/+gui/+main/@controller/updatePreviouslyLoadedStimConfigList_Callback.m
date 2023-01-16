function updatePreviouslyLoadedStimConfigList_Callback(obj,~,~)
    % Update drop-down of recently loaded files
    %
    % zapit.gui.main.controller.updatePreviouslyLoadedStimConfigList_Callback
    %
    % Purpose
    % The paths to the previously loaded stim config files are stored in the
    % property previouslyLoadedStimConfigs and this is used to build the menu
    % items in recentLoadedConfigsMenu. This callback wipes and rebuilds the menu.

    % Delete all existing menu items
    cellfun(@(x) delete(x),obj.recentLoadedConfigsMenu);
    obj.recentLoadedConfigsMenu={};

    % Create new ones
    for ii=1:length(obj.previouslyLoadedStimConfigs)
        obj.recentLoadedConfigsMenu{end+1} = uimenu(obj.LoadrecentMenu);
        obj.recentLoadedConfigsMenu{end}.Text = obj.previouslyLoadedStimConfigs(ii).fname;
        obj.recentLoadedConfigsMenu{end}.UserData = ...
            fullfile(obj.previouslyLoadedStimConfigs(ii).pathToFname, obj.previouslyLoadedStimConfigs(ii).fname);

       obj.recentLoadedConfigsMenu{end}.MenuSelectedFcn = @(src,~) obj.loadStimConfig_Callback(src);
    end

end
