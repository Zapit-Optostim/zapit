function zapSite_Callback(obj)
    % Stimulate the areas selected by the test site drop-down
    %
    % zapit.gui.main.controller.zapSite_Callback
    %
    % Purpose
    % This callback stimulates areas named in one condition.

    if isempty(obj.model.stimConfig)
        obj.ZapSiteButton.Value = 0;
        return
    end

    if nargin>1
        % Only set GUI state if the *user* clicked the button
        % rather than than harmonizeGUIstate calling it.
        obj.GUIstate = mfilename;
    end

    if obj.ZapSiteButton.Value == 1
        val = obj.TestSiteDropDown.Value;
        f = find(cellfun(@(x) strcmp(x,val), obj.TestSiteDropDown.Items));
        obj.model.sendSamples('conditionNumber',f, ...
                              'hardwareTriggered', false, ...
                              'logging', false)
    else
        obj.model.stopOptoStim;
    end


end
