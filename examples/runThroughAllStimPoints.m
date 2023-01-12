function runThroughAllStimPoints(varargin)
    % Demo showing how to present stim at each location for a short time
    %
    % function runThroughAllStimPoints(varargin)
    %
    % Purpose
    % Demo showing how to present stim at each location for a short time
    %
    % Inputs (optional)
    % stimDuration - number of seconds for which to present the stimuli. 0.5 by default.
    %
    %
    % Rob Campbell - SWC 2023


    % Get the API object from the base workspace
    hZP = zapit.utils.getObject;
    if isempty(hZP)
        return
    end


    % Build the input parser for the optional args
    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('stimDuration', 0.5, @(x) isnumeric(x) && isscalar(x) && x>0)
    params.parse(varargin{:})
    stimDuration = params.Results.stimDuration;


    % TODO -- this structure will change or be replaced by something else
    newTrial = struct('area', 1, 'LaserOn', 1, 'powerOption', 1);

    for ii = 1:hZP.stimConfig.numStimLocations
        newTrial.area = ii;
        hZP.sendSamples(newTrial) % Starts right away

        pause(stimDuration)
        hZP.stopOptoStim
    end

end
