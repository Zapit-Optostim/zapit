function runThroughAllStimPoints(varargin)
    % Demo showing how to present stim at each location for a short time
    %
    % function runThroughAllStimPoints(varargin)
    %
    % Purpose
    % Demo showing how to present stim at each location for a short time. Does not make
    % any log files. Absolute minimal example.
    %
    % Inputs (optional)
    % stimDuration - number of seconds for which to present the stimuli. 0.5 by default.
    %
    % Outputs
    % none
    %
    % Rob Campbell - SWC 2023


    % Get the API object from the base workspace
    hZP = zapit.utils.getObject;
    if isempty(hZP)
        return
    end


    if hZP.isReadyToStim == false
        fprintf('Zapit is not ready to stimulate.\n')
        return
    end

    % Build the input parser for the optional args
    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('stimDuration', 0.5, @(x) isnumeric(x) && isscalar(x) && x>0)
    params.parse(varargin{:})
    stimDuration = params.Results.stimDuration;


    for ii = 1:length(hZP.stimConfig.stimLocations)
        hZP.sendSamples('conditionNum',ii, 'hardwareTriggered', false) % Starts right away
        pause(stimDuration)
        hZP.stopOptoStim
        pause(0.3) % Because of https://github.com/Zapit-Optostim/zapit/issues/102
    end

end % runThroughAllStimPoints
