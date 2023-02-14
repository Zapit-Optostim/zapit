function settingsDirs = possibleSettingsLocations
    % Return all possible user settings locations of the Zapit optostim package
    %
    % function settingsDirs = zapit.settings.possibleSettingsLocations()
    %
    % Prurpose
    % Return all possible user settings directory locations for the Zapit optostim package.
    % This is used by zapit.settings.findSettingsFile to determine where the settings file
    % is located.
    % 
    % Outputs
    % settingsDirs - A structure containing the possible settings file locations
    %
    %
    % Rob Campbell - SWC 2022


    n = 0;

    % In C:\ (on Windows)
    if ispc
        n = n+1;
        settingsDirs(n).settingsLocation = fullfile('C:\', 'ZapitSettings');
        settingsDirs(n).backupSettingsLocation = fullfile(settingsDirs(n).settingsLocation,'BackupSettings');
            settingsDirs(n).locationType = 'C';
    end


    % User's home directory
    userFolder = zapit.settings.userFolder;
    if ~isempty(userFolder)
        n = n+1;
        settingsDirs(n).settingsLocation = fullfile(userFolder,'ZapitSettings');
        settingsDirs(n).backupSettingsLocation = fullfile(settingsDirs(n).settingsLocation,'BackupSettings');
        settingsDirs(n).locationType = 'homefolder';
    end


    % In Zapit folder

    installDir = zapit.updater.getInstallPath;
    if ~isempty(installDir)
        n = n+1;
        settingsDirs(n).settingsLocation = fullfile(installDir,'SETTINGS');
        settingsDirs(n).backupSettingsLocation = fullfile(installDir,'BACKUPSETTINGS');
        settingsDirs(n).locationType = 'zapit';
    end




    % Check what exists
    for ii=1:length(settingsDirs)
        settingsDirs(ii).settingsLocation_exists = ...
            exist(settingsDirs(ii).settingsLocation,'dir')>0;
        settingsDirs(ii).backupSettingsLocation_exists = ...
            exist(settingsDirs(ii).backupSettingsLocation,'dir')>0;
    end


    return
    %Make the settings directory if needed
    if ~exist(settingsDir,'dir')
        success=mkdir(settingsDir);
        if ~success
            fprintf('FAILED TO MAKE SETTINGS DIRECTORY: %s. Check the permissions and try again\n', settingsDir);
            return
        end
    end


    % Same for the backup settings dir
    settingsDirBackup = fullfile(installDir,'SETTINGS_BACKUP');

    %Make the settings directory if needed
    if ~exist(settingsDirBackup,'dir')
        success=mkdir(settingsDirBackup);
        if ~success
            fprintf('FAILED TO MAKE BACKUP SETTINGS DIRECTORY: %s. Check the permissions and try again\n', settingsDirBackup);
            return
        end
    end

end % possibleSettingsLocations