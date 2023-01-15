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
    addons = zapit.updater.getAddonDetails;
    v = zapit.version;

    % If the addon is installed and the reported installed version of the package matches that
    % reported by the AddOn manager, then we probably are working from Zapit installed via MATLAB.
    if addons.isAddon
        if v.version.string == addons.version % TODO -- Have not verified this is correct
            installType = 'addon';
            return
        end 
        % If the above statement is false then that means likely the user has installed the addon
        % but the running code is from a different install. 
    end


    if strcmp(gitInfo.branch, 'UNKNOWN')
        installType = 'manual';
    else
        installType = 'repo' ;
    end
