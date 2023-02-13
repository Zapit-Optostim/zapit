function details = getAddonDetails
    % If Zapit was installed as an add-on return the details
    %
    % function details = zapit.updater.getAddonDetails()
    %
    % Purpose
    % If zapit was installed as an add-on, return the details as a structure.
    % 
    % Inputs
    % none
    %
    % Outputs
    % details - structure with output details:
    %       details.isAddon = [bool]
    %       details.version = [string]
    %       details.enabled = [bool]
    %
    %
    % Rob Campbell - SWC 2023


    addons = matlab.addons.installedAddons;

    f = find(lower(addons.Name)=='zapit');

    if isempty(f)
        details.isAddon = false;
        details.version = [];
        details.enabled = [];
        return
    end

    details.isAddon = true;
    details.version = addons.Version(f);
    details.enabled = addons.Enabled(f);    

end %getAddonDetails