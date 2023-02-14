function isNewer = isVersionNewer(referenceVersion, testVersion)
    % Return true if testVersion is more recent than referenceVersion
    %
    % isNewer = zapit.updater.isVersionNewer(referenceVersion, testVersion)
    %
    % Purpose
    % Accepts structures of the form produced by versionStringToStructure 
    % and returns true if testVersion is newer than referenceVersion.
    %
    % Inputs
    % referenceVersion and testVersion are both structures of the form:
    %              MAJOR: 0
    %              MINOR: 6
    %              PATCH: 0
    %   preReleaseString: '-alpha'
    %
    % Outputs
    % isNewer - true if testVersion is newer than refrenceVersion
    %
    %
    % Rob Campbell - SWC 2022


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
