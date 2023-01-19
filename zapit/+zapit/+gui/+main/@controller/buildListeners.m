function buildListeners(obj)
    % Build listeners
    %
    % zapit.gui.main.controller.buildListeners
    %
    % Purpose
    % The listeners coordinate things like updating the displayed image from the camera,
    % and updating the list of recently loaded files.

    obj.listeners{end+1} = ...
        addlistener(obj.model, 'experimentPath', 'PostSet', @obj.updateExperimentPathTextArea);
    obj.listeners{end+1} = ...
        addlistener(obj.model, 'lastAcquiredFrame', 'PostSet', @obj.dispFrame);
    obj.listeners{end+1} = ...
        addlistener(obj.model, 'scannersCalibrated', 'PostSet', @obj.scannersCalibrateCallback);
    obj.listeners{end+1} = ...
        addlistener(obj.model, 'sampleCalibrated', 'PostSet', @obj.sampleCalibrateCallback);
    obj.listeners{end+1} = ...
        addlistener(obj, 'previouslyLoadedStimConfigs', 'PostSet', @obj.updatePreviouslyLoadedStimConfigList_Callback);
end % buildListeners
