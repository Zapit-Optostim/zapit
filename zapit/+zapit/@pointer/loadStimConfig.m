function loadStimConfig(obj,pathToConfig)
    % Load a stim config and add as property
    %
    % zapit.pointer.loadStimConfig(pathToConfig)
    %
    % Purpose
    % Load a stim config file and attach it as a zapit.stimConfig
    % to zapit.pointer.stimConfig and set up the parent property.


    if ~exist(pathToConfig,'file')
        fprintf('Can not load stim config %s\n', pathToConfig)
        return
    end

    obj.stimConfig = zapit.stimConfig(pathToConfig);
    obj.stimConfig.parent = obj;

    % Check whether any condition asks for more laser power than the hardware can deliver.
    % This populates stimConfig.conditionsExceedingLaserPower and reports to the CLI. It must
    % run after the parent is attached, since the peak-power calculation needs the settings.
    obj.stimConfig.checkLaserPower;

end % loadStimConfig
