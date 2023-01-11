function updateTestSiteDropdown(obj)
    % Updates drop-down menu showing stim locations so we can test-zap

    if isempty(obj.model.stimConfig)
        obj.TestSiteDropDown.Items = {};
        return
    end

    for ii=1:size(obj.model.stimConfig.template,2);
        stimSite{ii} = sprintf('Site %d', ii);
    end

    obj.TestSiteDropDown.Items = stimSite;

end % updateTestSiteDropDown

