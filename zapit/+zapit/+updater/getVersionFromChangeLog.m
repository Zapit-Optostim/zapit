function [versionDetails,allVersions] = getVersionFromChangeLog(pathToChangelog)
% Get Zapit version and release date from the CHANGELOG
%
% function versionDetails = zapit.updater.getVersionFromChangeLog
%
% Purpose
% Get Zapit's version from the CHANGELOG.md file
%
% Inputs
% pathToChangeLog - [optional] by default this is found automatically.
%
% Outputs
% versionDetails - structure containing the version information for the latest version.
% allVersions - vector of structures listing all version numbers found in the file.
%
% Rob Campbell - SWC, 2023


if nargin<1
    pathToChangelog = fullfile(zapit.updater.getInstallPath,'CHANGELOG.md');
end

if exist(pathToChangelog) == 0
    error('Can not find CHANGELOG.md at: %s', pathToChangelog)
end


fid = fopen(pathToChangelog);

t_line = fgets(fid);

n=1;
while t_line > -1

    % Is this a line that contains a version?
    if regexp(t_line, ' +v *\d+\.\d+\.\d+')
        tmp.version = zapit.updater.versionStringToStructure(t_line);
        tmp.date = getDateFromLine(t_line);

        allVersions(n) = tmp;
        n=n+1;
    end

    t_line = fgets(fid);
end

fclose(fid);

versionDetails = allVersions(1);



function date = getDateFromLine(t_line)
    % Get date from the current line
    date.year = 0;
    date.month = 0;
    date.day = 0;

    tok = regexp(t_line,'(\d+/\d+/\d+)','tokens');
    if isempty(tok)
        return
    end

    t_date  = tok{1}{1};

    % Bail if the format seems wrong
    date_cell = strsplit(t_date,'/');
    if length(date_cell)<3
        return
    end

    if str2num(date_cell{1})<2023
        return
    end

    % Output
    date.year = str2num(date_cell{1});
    date.month = str2num(date_cell{2});
    date.day = str2num(date_cell{3});


