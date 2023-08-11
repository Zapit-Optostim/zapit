function details = checkForNewVersion
    % Check whether there is a GitHub release with a new version of the software
    %
    % details = zapit.updater.checkForNewVersion()
    %
    % Purpose
    % Use GitHub's releases and the local reported version number to decide
    % whether there is a new version up on GitHub.
    %
    % Inputs
    % none
    %
    % Outputs
    % details - A structure that reports whether or not there is a new version, what is
    %          the current local version, how many releases old it is, and what is the
    %          latest version on GitHub.
    %
    % Rob Campbell - SWC 2023

    % Get version details
    releases = zapit.updater.getGitHubReleaseHistory;

    if isempty(releases)
        details = [];
        return
    end

    localVersion = zapit.version;

    % Make two structures that are directly comparable.
    lVer = localVersion.version;
    releaseVersions = arrayfun(@(x) zapit.updater.versionStringToStructure(x.tag_name), releases);


    % Assemble data for what will be the output structure
    isNewer = arrayfun(@(x) zapit.updater.isVersionNewer(lVer,x), releaseVersions)';


    details.installedVersion = lVer.string;
    details.latestRelease = releaseVersions(1).string;
    releaseTime = strsplit(releases(1).published_at,'T');
    details.latestReleasePublicationDate = releaseTime{1};

    if sum(isNewer)>0
        if sum(isNewer)>1
            plural = 's';
        else
            plural = '';
        end
        details.msg = sprintf([' ** Your Zapit install is %d release%s behind the latest version! ** \n',...
                                'Your version: %s\nLatest version: %s\nLatest version released on %s\n'], ...
                                sum(isNewer), plural, ...
                                details.installedVersion, ...
                                details.latestRelease, ...
                                details.latestReleasePublicationDate);
        details.isUpToDate = false;
    else
        details.msg = 'Zapit is up to date.\n';
        details.isUpToDate = true;
    end

end % checkForNewVersion

