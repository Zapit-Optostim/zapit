function saveGUIcache(obj)
    % Save the GUI cache

    zapitGUIcache.previouslyLoadedStimConfigs = obj.previouslyLoadedStimConfigs;

    fname = obj.GUIcacheLocation;
    save(fname,'zapitGUIcache')

end
