function zPaths = findZapitPathsInMATLABpath
    % Find all paths associated with Zapit in the MATLAB path
    %
    % zapit.updater.findZapitPathsInMATLABpath
    %
    % Purpose
    % Search through the MATLAB and return all paths associated with zapit. This is
    % to look for multiple installs and also to look for directories that have been
    % added to the path and should not have been. e.g. the development directory. 
    %
    % Inputs
    % none
    %
    % Outputs
    % zPaths - Cell array of strings defining the absolute paths associated with
    %         zapit in the MATLAB path. 

    p = path;
    p = strsplit(p,':')';

    f = find( cellfun(@(x) ~isempty(strfind(x,'zapit')), p) );

    if isempty(f)
        zPaths = [];
    else
        zPaths = p(f);
    end

end % getInstallPath
