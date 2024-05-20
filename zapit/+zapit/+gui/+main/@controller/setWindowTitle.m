function setWindowTitle(obj)
    % Set Zapit window title text and report here if a new version is available
    %
    % function zapit.gui.main.setWindowTitle
    %
    % Purpose
    % This function can be run not only at startup but also regularly 
    % to report to the user when a new version is available. 
    %
    % Rob Campbell - SWC 2023


    d = zapit.updater.checkForNewVersion;
    if isempty(d)
        return
    end
    if d.isUpToDate
        obj.hFig.Name = sprintf('Zapit v%s', d.installedVersion);
    else
        obj.hFig.Name = sprintf('Zapit v%s  **New Version v%s Available**', ...
                d.installedVersion, d.latestRelease);
    end

end % setWindowTitle
