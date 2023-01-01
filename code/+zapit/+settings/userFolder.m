function userDir = userFolder
    % Return path to user's Windows folder
    %
    % function userDir = userFolder
    %
    % Purpose
    % Return path to user's home folder
    %
    % Rob Campbell - 2022 SWC


    if ispc
        %From https://uk.mathworks.com/matlabcentral/fileexchange/15885-get-user-home-directory
        userDir = winqueryreg('HKEY_CURRENT_USER',...
                ['Software\Microsoft\Windows\CurrentVersion\' ...
                 'Explorer\Shell Folders'],'Personal');
    else
        userDir = '~';
    end


    % Just in case
    if ~exist(userDir)
        userDir = [];
    end
