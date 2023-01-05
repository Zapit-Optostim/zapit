function updatePreviouslyLoadedStimConfigList_Callback(obj,~,~)
    % Update drop-down of recently loaded files
    %
    % zapit.gui.main.controller.updatePreviouslyLoadedStimConfigList_Callback
    %
    % 

    t_items = {obj.previouslyLoadedStimConfigs.fname};

    % TODO-- looks like the ItemData is returned as the value! So we are good. BUT TEST!
    % The files will all be unique as the previouslyLoadedStimConfigs structure does not contain
    % duplicate full paths but it might contain duplicate file names. We want to avoid this, 
    % because the dropdown returns only item values and not their indexes. So we will go through
    % list and add increasing amounts of white space to duplicate item names.
    %[u_t_items, ~, u_inds] = unique(t_items);
    %if length(t_items) ~= length(u_t_items)
    %    for ii=1:length(u_t_items)
    %        f = find(u_inds == ii);
    %        for jj=2:length(f)
    %            t_items{f(jj)} = [t_items{f(jj)}, repmat(' ',1,jj-1)];
    %        end
    %    end
    %end


    obj.LoadRecentDropDown.Items = t_items;

    % Store full paths in the user data
    obj.LoadRecentDropDown.ItemsData.fullPath = ...
        arrayfun( @(x) fullfile(x.pathToFname,x.fname), obj.previouslyLoadedStimConfigs,'UniformOutput',false) ;

end