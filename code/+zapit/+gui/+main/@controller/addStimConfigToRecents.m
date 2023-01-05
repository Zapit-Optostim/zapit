function addStimConfigToRecents(obj,fname,pathToFname)
    % Add to recents structure
    newEntry = struct(...
            'fname', fname, ...
            'pathToFname', pathToFname, ...
            'timeAdded', now);

    % Add to the top
    obj.previouslyLoadedStimConfigs = [newEntry, obj.previouslyLoadedStimConfigs];

    % Remove duplicate entries
    allNames = arrayfun( @(x) [x.pathToFname,x.fname], obj.previouslyLoadedStimConfigs, ...
            'UniformOutput',false);

    [~,uniqInd] = unique(allNames);
    obj.previouslyLoadedStimConfigs = obj.previouslyLoadedStimConfigs(uniqInd);

    obj.removeMissingRecentConfigs; %Remove from the list any files that no longer exist

    % Trim if needed
    if length(obj.previouslyLoadedStimConfigs) > obj.maxPreviouslyLoadedStimConfigs
        obj.previouslyLoadedStimConfigs = ...
            obj.previouslyLoadedStimConfigs(1:obj.maxPreviouslyLoadedStimConfigs);
    end

end