function vStruct = versionStringToStructure(vString)
    % Convert a version string into a structure for easier parsing
    %
    % function vStruct = zapit.updater.versionStringToStructure(vString)
    %
    % Purpose
    % Converts a version string to a structure so it can be handled more easily.
    %
    % Inputs
    % vString - A string i the form 'v0.11.23-beta'. The pre-release string
    %           ('-.*') is optional.
    %
    % Outputs
    % vStuct - The string converted in to a structure. For example, if vString
    %          is "0.6.0-alpha" then vStruct will be:
    %
    %            MAJOR: 0
    %            MINOR: 6
    %            PATCH: 0
    % preReleaseString: '-alpha'
    %
    %
    % Rob Campbell - SWC 2022

    % strip any leading text up the 'v' for 'version'
    vString = regexprep(vString,'.*v','');

    % strip any trailing newlines
    vString = regexprep(vString,'\n$','');

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
