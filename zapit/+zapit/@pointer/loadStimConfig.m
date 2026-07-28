function success = loadStimConfig(obj,pathToConfig)
    % Load a stim config and add as property
    %
    % success = zapit.pointer.loadStimConfig(pathToConfig)
    %
    % Purpose
    % Load a stim config file and attach it as a zapit.stimConfig
    % to zapit.pointer.stimConfig and set up the parent property.
    %
    % A config that contains a condition which can not be physically presented (the beam
    % blanking leaves no time to illuminate a point; see returnUnpresentableConditions) is
    % refused entirely: we do not load it and we leave any previously-loaded config in
    % place. This is deliberate — silently dropping or truncating the offending condition
    % would change the experiment without the user realising.
    %
    % Outputs
    % success - true if the config was loaded, false if it was refused or not found. The
    %           return value is optional; CLI callers may ignore it.


    success = false;

    if ~exist(pathToConfig,'file')
        fprintf('Can not load stim config %s\n', pathToConfig)
        return
    end

    % Build into a temporary object so that refusing an invalid config does not clobber an
    % already-loaded (good) config.
    tmpConfig = zapit.stimConfig(pathToConfig);
    tmpConfig.parent = obj;

    % Refuse to load if any condition can not be presented
    unpresentable = tmpConfig.returnUnpresentableConditions;
    if ~isempty(unpresentable)
        fprintf(['\n ** Can not load %s\n', ...
            ' ** Condition(s) %s can not be presented: with the current blanking settings ', ...
            'and modulation frequency there is no time to illuminate each point.\n', ...
            ' ** Reduce the number of points per condition, shorten the blanking time, or ', ...
            'lower the stim modulation frequency, then try again.\n', ...
            ' ** The stim config has NOT been loaded.\n\n'], ...
            pathToConfig, mat2str(unpresentable))
        delete(tmpConfig)
        return
    end

    % Passed validation: commit it
    obj.stimConfig = tmpConfig;

    % Check whether any condition asks for more laser power than the hardware can deliver.
    % Unlike the presentability check this does not block loading (the stimulus still plays,
    % just capped) — it populates stimConfig.conditionsExceedingLaserPower and reports to the
    % CLI. It must run after the parent is attached, since it needs the settings.
    obj.stimConfig.checkLaserPower;

    success = true;

end % loadStimConfig
