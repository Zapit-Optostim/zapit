function zapSite_Callback(obj,~,~)
    % Stimulate the areas selected by the test site drop-down
    %
    % zapit.gui.main.controller.zapSite_Callback
    %
    % Purpose
    % This callback stimulates areas named in one condition.

    if obj.ZapSiteButton.Value == 1
        val = obj.TestSiteDropDown.Value;
        f = find(cellfun(@(x) strcmp(x,val), obj.TestSiteDropDown.Items));
        obj.model.sendSamples('conditionNumber',f, 'hardwareTriggered',false)
    else
        obj.model.stopOptoStim;
    end


end
