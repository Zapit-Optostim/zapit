function saveGUIcache(obj)
    % Save the GUI cache
    %
    % zapit.gui.main.controller.saveGUIcache

    zapitGUIcache.previouslyLoadedStimConfigs = obj.previouslyLoadedStimConfigs;

    fname = obj.GUIcacheLocation;
    save(fname,'zapitGUIcache')

end % saveGUIcache
