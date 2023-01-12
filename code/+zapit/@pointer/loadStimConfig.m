function loadStimConfig(obj,pathToConfig)
    % Load a stim config and add as property
    %
    % zapit.pointer.loadStimConfig(pathToConfig)
    %
    % Purpose
    % Load a stim config file and attach it as a zapit.stimConfig
    % to zapit.pointer.stimConfig and set up the parent property.


    if ~exist(pathToConfig,'file')
        return
    end

    obj.stimConfig = zapit.stimConfig(pathToConfig);
    obj.stimConfig.parent = obj;

end % loadStimConfig
