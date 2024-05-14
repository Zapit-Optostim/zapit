function buildListeners(obj)
    % Build listeners
    %
    % zapit.gui.main.controller.buildListeners
    %
    % Purpose
    % The listeners coordinate things like updating the displayed image from the camera,
    % and updating the list of recently loaded files.
    %
    % Inputs
    % none
    %
    % Outputs
    % none
    %
    %
    % Rob Campbell - SWC 2022


    % To ensure button clicks respect the current state of the GUI
    obj.listeners.harmonizeGUIstate = addlistener(obj, 'GUIstate', 'PostSet', @obj.harmonizeGUIstate);

    % Disables select GUI elements during a clocked acquisition
    obj.listeners.updateClockedAcquisition = ...
        addlistener(obj.model.DAQ, 'doingClockedAcquisition', 'PostSet', @obj.updateClockedAcquisition);

    % So that reset zoom button is disabled if FOV is maxed
    obj.listeners.updateResetZoomButtonState = ...
        addlistener(obj.model.cam,'ROI', 'PostSet', @obj.updateResetZoomButtonState);

    % So that the experiment path text area box reflects the contents of the experimentPath
    % property in zapit.pointer
    obj.listeners.updateExperimentPathTextArea = ...
        addlistener(obj.model, 'experimentPath', 'PostSet', @obj.updateExperimentPathTextArea);

    %% RAAC -- COMMENT OUT TODO 14th MAY
    % Updates the GUI image with the last acquired frame from the camera
    %obj.listeners.dispFrame = ...
    %    addlistener(obj.model, 'lastAcquiredFrame', 'PostSet', @obj.dispFrame);

    % Update the GUI elements depending on whether or not the scanner calibration step has been done.
    obj.listeners.scannersCalibrateCallback = ...
        addlistener(obj.model, 'scannersCalibrated', 'PostSet', @obj.scannersCalibrateCallback);

    % Update the GUI elements depending on whether or not the sample calibration step has been done.
    obj.listeners.sampleCalibrateCallback = ...
        addlistener(obj.model, 'sampleCalibrated', 'PostSet', @obj.sampleCalibrateCallback);

    % Update the previously loaded stim configuration menu
    obj.listeners.updatePreviouslyLoadedStimConfigList = ...
        addlistener(obj, 'previouslyLoadedStimConfigs', 'PostSet', @obj.updatePreviouslyLoadedStimConfigList_Callback);

end % buildListeners
