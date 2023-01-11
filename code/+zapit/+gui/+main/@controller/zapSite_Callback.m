function zapSite_Callback(obj,~,~)
    % stim a site

    if obj.ZapSiteButton.Value == 1
        val = obj.TestSiteDropDown.Value;
        f = find(cellfun(@(x) strcmp(x,val), obj.TestSiteDropDown.Items));

        obj.model.makeChanSamples(10); % TOOD-- hard-coded LASER POWER!!

        % TODO -- this old structure! we must change it
        newTrial.area = f; % first brain area on the list
        newTrial.LaserOn = 1;
        newTrial.powerOption = 1; % if 1 send 2 mW, if 2 send 4 mW (mean)

        obj.model.sendSamples(newTrial)
    else
        obj.model.stopOptoStim;
    end


end
