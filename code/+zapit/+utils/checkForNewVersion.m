function details = checkForNewVersion
    % Check whether there is a GitHub release with a new version of the software
    %
    % details = zapit.utils.checkForNewVersion
    %
    % Purpose
    % Use GitHub's releases and the local reported version number to decide 
    % whether there is a new version up on GitHub.
    %
    % Inputs
    % none
    %
    % Outputs
    % details - A structure that reports whether or not there is a new version, what is the 
    %          current local version, how many releases old it is, and what is the latest
    %          version on GitHub.
    %
    % Rob Campbell - SWC 2023

    % Get version details
    releases = zapit.utils.getGitHubReleaseHistory;
    if isempty(releases)
        details = [];
    end

    localVersion = zapit.version;

    % Make two structures that are directly comparable.
    lVer = localVersion.version;
    releaseVersions = arrayfun(@(x) versionStringToStructure(x.tag_name), releases);


    % Assemble data for what will be the output structure
    isNewer = arrayfun(@(x) isVersionNewer(lVer,x), releaseVersions)';


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


% Internal functions follow
function vStruct = versionStringToStructure(vString)
    % Convert a version string into a structure for easier parsing
    %
    % 
    % For example, if vString is "0.6.0-alpha" then vStruct will be:
    %
    %            MAJOR: 0
    %            MINOR: 6
    %            PATCH: 0
    % preReleaseString: '-alpha'
    %

    if strcmp(vString(1),'v')
        vString(1) = [];
    end

    tmp = strsplit(vString,'-');

    if length(tmp)>1
        preReleaseString = ['-',tmp{2}];
    else
        preReleaseString = '';
    end

    tmp = strsplit(tmp{1},'.');

    vStruct.MAJOR = str2num(tmp{1});
    vStruct.MINOR = str2num(tmp{2});
    vStruct.PATCH = str2num(tmp{3});
    vStruct.preReleaseString = preReleaseString;
    vStruct.string = sprintf('%d.%d.%d%s', vStruct.MAJOR, vStruct.MINOR, ...
                            vStruct.PATCH, vStruct.preReleaseString);
end % versionStringToStructure


function isNewer = isVersionNewer(referenceVersion, testVersion)
    % Return true if testVersion is more recent than referenceVersion
    %
    % Accepts structures of the form produced by versionStringToStructure.

    % If all are the same then we return false
    if testVersion.MAJOR == referenceVersion.MAJOR && ...
            testVersion.MINOR == referenceVersion.MINOR && ...
            testVersion.PATCH == referenceVersion.PATCH
        isNewer = false;
        return
    end

    if testVersion.MAJOR < referenceVersion.MAJOR
        isNewer = false;
        return
    elseif testVersion.MAJOR > referenceVersion.MAJOR
        isNewer = true;
        return
    end

    % If we are here they are the same and we move on to testing the next

    if testVersion.MINOR < referenceVersion.MINOR
        isNewer = false;
        return
    elseif testVersion.MINOR > referenceVersion.MINOR
        isNewer = true;
        return
    end

    % If we are here they are the same and we move on to testing the next

    if testVersion.PATCH < referenceVersion.PATCH
        isNewer = false;
    elseif testVersion.PATCH > referenceVersion.PATCH
        isNewer = true;
    end

    % No more possibilities
   
end % isVersionNewer
