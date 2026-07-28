function stimConfigLoaded_Callback(obj,~,~)
    % Update the GUI when the model's stim config changes
    %
    % zapit.gui.main.controller.stimConfigLoaded_Callback
    %
    % Purpose
    % Runs whenever zapit.pointer.stimConfig is (re)assigned -- see buildListeners. This
    % makes the GUI react to a stim config being loaded regardless of whether the load came
    % from a GUI button or from the command line (issue #132). It updates the "Config
    % Loaded" text, refreshes the stimulus-site overlay, updates the test-site drop-down,
    % and, if the config asks for more laser power than the hardware can deliver, warns.
    %
    % Note: this fires only when the property is actually set. A refused load
    % (zapit.pointer.loadStimConfig returns false without assigning) does not trigger it, so
    % the previously displayed state is left untouched.


    % Clear any existing overlay first (button unchecked -> overlayStimSites_Callback removes)
    obj.OverlaystimsitesButton.Value = 0;
    obj.overlayStimSites_Callback;

    % Handle the config being cleared (e.g. hZP.stimConfig = [])
    if isempty(obj.model.stimConfig)
        obj.ConfigLoadedTextLabel.Text = 'No config loaded';
        obj.updateTestSiteDropdown;
        return
    end

    % Update the text indicating which config file has been loaded
    [~,fname,ext] = fileparts(obj.model.stimConfig.configFileName);
    obj.ConfigLoadedTextLabel.Text = ['Config Loaded: ', fname, ext];

    % Overlay the stim points if we are in a state where they can be drawn
    if obj.model.isReadyToStim
        obj.OverlaystimsitesButton.Value = 1;
        obj.overlayStimSites_Callback;
    end

    % Update the drop-down that allows us to present individual stimuli
    obj.updateTestSiteDropdown;

    % Warn (dialog) if any condition needs more laser power than the hardware can deliver.
    % The model already reported this to the CLI (zapit.stimConfig.checkLaserPower); this is
    % the GUI-facing surfacing of the same information.
    badConditions = obj.model.stimConfig.conditionsExceedingLaserPower;
    if ~isempty(badConditions)
        msg = sprintf(['%d stimulus condition(s) request more laser power than your laser ', ...
            'can deliver and so will be capped during presentation (delivered power lower ', ...
            'than requested).\n\nAffected conditions: %s\n\nSee the console for the ', ...
            'required power of each.'], ...
            length(badConditions), mat2str(badConditions));
        warndlg(msg, 'Laser power exceeded')
    end

end % stimConfigLoaded_Callback
