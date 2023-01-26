function setExperimentPath_Callback(obj)
    % Set the experimentPath property in zapit.pointer
    %
    % zapit.gui.main.controller.setExperimentPath_Callback
    %
    % Purpose
    % Set the experimentPath property in zapit.pointer. Whilst this variable
    % is set, the zapit.pointer.sendSamples command will log stimulus presentation
    % information to that folder.
    %
    % Inputs
    % none
    %
    % Outputs
    % none
    %
    % Rob Campbell - SWC 2023

    isCamRunning = obj.model.cam.isrunning;

    if isCamRunning
        obj.model.cam.stopVideo;
    end

    selectedPath = uigetdir;

    obj.model.experimentPath = selectedPath;

    if isCamRunning
        obj.model.cam.startVideo;
    end

end % setExperimentPath_Callback
