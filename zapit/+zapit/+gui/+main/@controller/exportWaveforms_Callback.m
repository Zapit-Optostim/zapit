function exportWaveforms_Callback(obj,~,~)
    % Export all the DAQ waveforms for this stim config file as a .mat file
    %
    % zapit.gui.main.controller..exportWaveforms_Callback
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

    isCamRunning = obj.model.cam.isrunning;

    if isCamRunning
        obj.model.cam.stopVideo;
    end

    selectedPath = uigetdir;

    obj.model.stimConfig.writeWaveformsToDisk(selectedPath);

    if isCamRunning
        obj.model.cam.startVideo;
    end

end