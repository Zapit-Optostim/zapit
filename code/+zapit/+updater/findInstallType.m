function installType = findInstallType
    % Return a string indicating how Zapit is installed
    %
    % zapit.updater.findInstallType
    %
    % Purpose
    % Zapit might have been installed via MATLAB, it could be a Git Repo, or it could be from a
    % zip archive. Knowing which it is will help provide instructions on how to update it.
    %
    % Inputs
    % none
    %
    % Outputs
    % installType - String indictaing how Zapit was installed. 
    %       'manual' - Meaning that Zapit was probably installed from a zip file.
    %       'addon' - Installed from the FEX via the AddOn manager.
    %       'repo' - Zapit is a git repo.



    gitInfo = zapit.updater.getGitInfo
    addons = zapit.updater.getAddonDetails
    v = zapit.version
    if strcmp(gitInfo.branch, 'UNKNOWN')
        installType = 'repo';
    else
        installType = 'manual' ;
    end
