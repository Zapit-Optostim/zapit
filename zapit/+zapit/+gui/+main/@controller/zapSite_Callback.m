function zapSite_Callback(obj,~,~)
    % Stimulate the areas selected by the test site drop-down
    %
    % zapit.gui.main.controller.zapSite_Callback
    %
    

    if obj.ZapSiteButton.Value == 1
        val = obj.TestSiteDropDown.Value;
        f = find(cellfun(@(x) strcmp(x,val), obj.TestSiteDropDown.Items));

        newTrial.ConditionNum = f; % first brain area on the list
        newTrial.LaserOn = 1;

        obj.model.sendSamples(newTrial)
    else
        obj.model.stopOptoStim;
    end


end
