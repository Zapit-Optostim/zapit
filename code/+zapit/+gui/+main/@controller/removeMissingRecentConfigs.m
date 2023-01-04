function removeMissingRecentConfigs(obj)
    % Remove from previously loaded stim config list any files that no longer exist
    %
    % zapit.gui.main.controller.removeMissingRecentConfigs
    %
    % 

    for ii = length(obj.previouslyLoadedStimConfigs):-1:1
        t_config = obj.previouslyLoadedStimConfigs(ii);
        fname = fullfile(t_config.pathToFname,t_config.fname);
        if ~exist(fname)
            obj.previouslyLoadedStimConfigs(ii) = [];
        end
    end

end