function loadGUIcache(obj)
    % Load the Zapit GUI cache file and apply it

    fname = obj.GUIcacheLocation;
    if ~exist(fname,'file')
        return
    end

    load(fname)
    obj.previouslyLoadedStimConfigs = zapitGUIcache.previouslyLoadedStimConfigs;

end
