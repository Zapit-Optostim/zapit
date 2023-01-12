function isReady = isReadyToStim(obj)
    % Return true if Zapit is ready to stimulate
    %
    % zapit.pointer.isReadyToStim
    %
    % Purpose
    % Returns true if the scanners are calibrated, and the the
    % sample is calibrated, and a stimConfig file has been loaded.
    %
    % Inputs
    % none
    %
    % Outputs
    % isReady - true if all is ready to go.
    %
    % Rob Campbel - SWC 2023


    if obj.scannersCalibrated && obj.sampleCalibrated && ~isempty(obj.stimConfig)
        isReady = true;
    else
        isReady = false;
    end

end % isReadyToStim
