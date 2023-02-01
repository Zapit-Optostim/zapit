function addStimConfigToRecents(obj,fname,pathToFname)
    % Add file to the recntly loaded stim config structure
    %
    % zapit.gui.main.controller.addStimConfigToRecents
    %
    % Purpose
    % The property previouslyLoadedStimConfigs lists all the config files
    % that were loaded recently. This method adds a file name and path to 
    % that list. It also removes from the list any missing configuration 
    % files and trims the list if too long. 


    newEntry = struct(...
            'fname', fname, ...
            'pathToFname', pathToFname, ...
            'timeAdded', now);

    % Add to the top
    obj.previouslyLoadedStimConfigs = [newEntry, obj.previouslyLoadedStimConfigs];

    % Remove duplicate entries
    allNames = arrayfun( @(x) fullfile(x.pathToFname,x.fname), obj.previouslyLoadedStimConfigs, ...
            'UniformOutput',false);

    [~,uniqInd] = unique(allNames);
    obj.previouslyLoadedStimConfigs = obj.previouslyLoadedStimConfigs(uniqInd);

    obj.removeMissingRecentConfigs; %Remove from the list any files that no longer exist

    % Trim if needed
    if length(obj.previouslyLoadedStimConfigs) > obj.maxPreviouslyLoadedStimConfigs
        obj.previouslyLoadedStimConfigs = ...
            obj.previouslyLoadedStimConfigs(1:obj.maxPreviouslyLoadedStimConfigs);
    end

    % Save the cache when a file is loaded
    obj.saveFileListCache
end % addStimConfigToRecents
