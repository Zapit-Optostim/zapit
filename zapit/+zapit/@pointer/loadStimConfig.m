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

    % Check whether any condition asks for more laser power than the hardware can deliver.
    % Unlike the presentability check this does not block loading (the stimulus still plays,
    % just capped) — it populates conditionsExceedingLaserPower and reports to the CLI. We run
    % it on the temporary object BEFORE committing, so that the property is already populated
    % when assigning to obj.stimConfig fires the GUI's PostSet listener (see
    % zapit.gui.main.controller.stimConfigLoaded_Callback).
    tmpConfig.checkLaserPower;

    % Passed validation: commit it. This assignment is what notifies the GUI (observable).
    obj.stimConfig = tmpConfig;

    success = true;

end % loadStimConfig
