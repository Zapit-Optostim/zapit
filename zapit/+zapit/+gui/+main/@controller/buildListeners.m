function buildListeners(obj)
    % Build listeners
    %
    % zapit.gui.main.controller.buildListeners
    %
    % Purpose
    % The listeners coordinate things like updating the displayed image from the camera,
    % and updating the list of recently loaded files.

    % So that reset zoom button is disabled if FOV is maxed
    obj.listeners{end+1} = ...
        addlistener(obj.model.cam,'ROI', 'PostSet', @obj.updateResetZoomButtonState);

    % So that the experiment path text area box reflects the contents of the experimentPath
    % property in zapit.pointer
    obj.listeners{end+1} = ...
        addlistener(obj.model, 'experimentPath', 'PostSet', @obj.updateExperimentPathTextArea);

    % Updates the GUI image with the last acquired frame from the camera
    obj.listeners{end+1} = ...
        addlistener(obj.model, 'lastAcquiredFrame', 'PostSet', @obj.dispFrame);

    % Update the GUI elements depending on whether or not the scanner calibration step has been done.
    obj.listeners{end+1} = ...
        addlistener(obj.model, 'scannersCalibrated', 'PostSet', @obj.scannersCalibrateCallback);

    % Update the GUI elements depending on whether or not the sample calibration step has been done.
    obj.listeners{end+1} = ...
        addlistener(obj.model, 'sampleCalibrated', 'PostSet', @obj.sampleCalibrateCallback);

    % Update the previously loaded stim configuration menu
    obj.listeners{end+1} = ...
        addlistener(obj, 'previouslyLoadedStimConfigs', 'PostSet', @obj.updatePreviouslyLoadedStimConfigList_Callback);

end % buildListeners
