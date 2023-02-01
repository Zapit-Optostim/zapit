function saveFileListCache(obj)
    % Save the GUI recently loaded file list cache to the settings file
    %
    % zapit.gui.main.controller.saveFileListCache
    %
    % Purpose
    % The recently loaded file list is saved to settings YML file so it will
    % persist across sessions.

    % Updating is sufficient to save it because there is a listener on the settings
    % property in zapit.pointer that will save when it's modified. 
    obj.model.settings.cache.previouslyLoadedFiles = ...
            arrayfun(@(x) {fullfile(x.pathToFname, x.fname), x.timeAdded}, ...
                        obj.previouslyLoadedStimConfigs, 'UniformOutput', false);

end % saveFileListCache
