function setExperimentPath_Callback(obj,~,~)
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

    % Stop preview to make things as smooth as possible
    obj.stopPreview

    selectedPath = uigetdir;

    obj.model.experimentPath = selectedPath;

    % re-start the camera
    obj.startPreview

end % setExperimentPath_Callback
