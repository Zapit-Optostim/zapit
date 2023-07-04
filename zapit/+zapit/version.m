function varargout = version
% Return version number of the zapit package as a whole
%
% out = zapit.version
%
% Purpose
% Return version number of the zapit package as a whole.
% Versions are semantic, meaning MAJOR.MINOR.PATCH
% and are incremented as follows:
% * MAJOR version when you make incompatible API changes
% * MINOR version when you add functionality in a backwards compatible manner
% * PATCH version when you make backwards compatible bug fixes
%
% Patch number will not always be updated. e.g. in the case of minor
% documentation commits and so forth.
%
% Inputs
% none
%
% Outputs
% out - optional structure containing the version number in numeric and string formats
%       plus the date of last update and information on the current Git commit.
%       If no output asked, version printed to screen.
%
%
% Rob Campbell - SWC 2022


%% EDIT THE FOLLOWING TO INCREMENT THE VERSION
out.version.MAJOR = 0;
out.version.MINOR = 11;
out.version.PATCH = 0;

%% Since v0.10.0 (2023/02/01) the preReleaseString will likely remain empty.
out.version.preReleaseString = '';

%%% UPDATE THE DATE
out.date.year = 2023;
out.date.month = 2;
out.date.day = 2;




out.version.string = sprintf('%d.%d.%d%s', ...
                out.version.MAJOR, ...
                out.version.MINOR, ...
                out.version.PATCH,...
                out.version.preReleaseString);


out.gitInfo = zapit.updater.getGitInfo;

out.message = sprintf('Zapit version %s  --  %d/%d/%d', ...
                out.version.string, ...
                out.date.year, ...
                out.date.month, ...
                out.date.day);


if nargout>0
    varargout{1} = out;
else
    fprintf('%s\n', out.message)
end

