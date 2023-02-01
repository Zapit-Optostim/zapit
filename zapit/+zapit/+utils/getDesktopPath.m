function desktopPath = getDesktopPath
    % Return absolute path to user's Desktop folder
    %
    % function desktopPath = zapit.utils.getDesktopPath
    %
    % Purpose
    % Return the user's desktop path. Used for example and demo code.
    % Cross-platform. Returns home directory if for some reason it can
    % not find a desktop folder.
    %
    % Inputs
    % none
    %
    % Outputs
    % desktopPath - absolute path to desktop folder
    %
    % Rob Campbell - SWC 2023



    if ispc
        desktopPath = winqueryreg('HKEY_CURRENT_USER', ...
         'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', 'Desktop');
    elseif isunix
        desktopPath = '~/Desktop';
        if ~exist(desktopPath,'dir')
            desktopPath = '~/';
        end
    end

end % desktopPath
