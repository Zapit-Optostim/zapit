function exportWaveforms_Callback(obj,~,~)
    % Export all the DAQ waveforms for this stim config file as a .mat file
    %
    % zapit.gui.main.controller.exportWaveforms_Callback
    %
    % Purpose
    % Allows users to present stimuli in a piece of external softare and
    % not use the Zapit API at all for presentation.
    %
    % Inputs
    % none
    %
    % Outputs
    % none
    %
    % Rob Campbell - SWC 2023

    if isempty(obj.model.stimConfig)
        return
    end

    % Stop preview to make things as smooth as possible
    obj.stopPreview

    selectedPath = uigetdir;

    obj.model.stimConfig.writeWaveformsToDisk(selectedPath);

    % re-start the camera
    obj.startPreview

end % exportWaveforms_Callback
