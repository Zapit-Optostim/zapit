function settings = readSettings
    % Read Zapit settings YAML file and return as a structure
    %
    % function settings = zapit.settings.readSettings
    %
    % Purpose
    % This function parses SETTINGS/settings.yml and creates it if does not already exist.
    %
    % If no settings have been created then a default settings file is created. The user is 
    % prompted to edit it and nothing is returned. If a settings file is present and looks 
    % identical to the default one, the user is prompted to edit it and nothing is returned. 
    % Otherwise the settings file is read and returned as a structure. 
    %
    % Inputs
    % none
    % 
    % Outputs
    % settings - the zapit settings as a structure
    % 
    %
    % Rob Campbell - Basel 2017
    % Rob Campbell - SWC 2022

    settings=[];



    [settingsFile,backupSetingsDir] = zapit.settings.findSettingsFile;

    settings = zapit.yaml.ReadYaml(settingsFile);

    %Check if the loaded settings are the same as the default settings
    DEFAULT_SETTINGS = default_settings;

    if isequal(settings,DEFAULT_SETTINGS)
        fprintf(['\n\n *** The settings file at %s has never been edited\n ', ...
            '*** Press RETURN then edit the file for your system.\n'], settingsFile)
        fprintf(' *** For help editing the file see: https://github.com/BaselLaserMouse/zapit\n\n')

        pause

        edit(settingsFile)
        fprintf('\n\n *** Once you have finished editing the file, save it and press RETURN\n')

        pause
        settings = zapit.settings.readSettings;
        return
    end


    % Pull in values from the default settings that are missing in the user settings file.
    f0 = fields(DEFAULT_SETTINGS);
    addedDefaultValue = false;
    for ii = 1:length(f0);
        f1 = fields(DEFAULT_SETTINGS.(f0{ii}));

        % Create missing structure if necessary (unlikely to ever be the case)
        if ~isfield(settings,f0{ii});
            settings.(f0{ii}) = [];
        end

        for jj = 1:length(f1)
            if ~isfield(settings.(f0{ii}), f1{jj})
                addedDefaultValue = true;
                fprintf('\n\n Adding missing default setting "%s.%s" from default_Settings.m\n', ...
                    (f0{ii}), f1{jj})
                settings.(f0{ii}).(f1{jj}) = DEFAULT_SETTINGS.(f0{ii}).(f1{jj});
            end
        end
    end



    % Make sure all settings that are returned are valid
    % If they are not, we replace them with the original default value
    [settings,allValid] = checkSettingsAreValid(settings); % see private directory



    % If there are missing or invalid values we will replace these in the settings file as well as making
    % a backup copy of the original file.
    if ~allValid || addedDefaultValue
       % Copy file
       backupFname = fullfile(backupSetingsDir, ...
            [datestr(now, 'yyyy_mm_dd__HH_MM_SS_'),zapit.settings.returnZapitSettingsFileName]);
       fprintf('Making backup of settings file at %s\n', backupFname)
       copyfile(settingsFile,backupFname)

       % Write the new file to the settings location
       fprintf('Replacing settings file with updated version\n')
       zapit.yaml.WriteYaml(settingsFile,settings);
    end



    % Log current version info to the settings
    g=zapit.updater.getGitInfo;
    systemVersion = sprintf('branch=%s  commit=%s', g.branch, g.hash);
    settings.zapit.gitCommit=systemVersion;
    v = zapit.version;
    settings.zapit.version=v.version.string;

end % readSettings