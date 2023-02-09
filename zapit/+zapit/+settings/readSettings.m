function outputSettings = readSettings(fname)
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
    % fname - [optional] If not provided, the default settings file is found and loaded. If
    %       fname is provided, this is loaded instead. A non-standard settings file is only
    %       used for running certain tests. The settings file is never modified if this
    %       this arg is defined.
    % 
    % Outputs
    % settings - the zapit settings as a structure
    % 
    %
    % Rob Campbell - Basel 2017
    % Rob Campbell - SWC 2022

    outputSettings = [];

    if nargin<1
        fname = [];
    end

    if nargin<2
        doNotReplaceOriginal = false;
    end



    if isempty(fname)
        [settingsFile,backupSettingsDir] = zapit.settings.findSettingsFile;
    else
        settingsFile = fname;
        backupSettingsDir = []; % Do not write to backup settings at all
    end

    settingsFromYML = zapit.yaml.ReadYaml(settingsFile);

    %Check if the loaded settings are the same as the default settings
    DEFAULT_SETTINGS = default_settings;

    if isequal(settingsFromYML,DEFAULT_SETTINGS)
        fprintf(['\n\n *** The settings file at %s has never been edited\n ', ...
            '*** Press RETURN then edit the file for your system.\n'], settingsFile)
        fprintf(' *** For help editing the file see: https://github.com/BaselLaserMouse/zapit\n\n')

        pause

        edit(settingsFile)
        fprintf('\n\n *** Once you have finished editing the file, save it and press RETURN\n')

        pause
        outputSettings = zapit.settings.readSettings;
        [outputSettings,allValid] = checkSettingsAreValid(outputSettings);
        return
    end


    % Report which missing values were added
    f0 = fields(DEFAULT_SETTINGS);
    addedDefaultValue = false;
    outputSettings = DEFAULT_SETTINGS;

    for ii = 1:length(f0);
        f1 = fields(DEFAULT_SETTINGS.(f0{ii}));

        % There is a whole section missing
        if ~isfield(settingsFromYML,f0{ii});
            fprintf('\n\n Added missing section "%s" from default_Settings.m\n', f0{ii})
            addedDefaultValue = true;
            continue
        end

        for jj = 1:length(f1)
            if ~isfield(settingsFromYML.(f0{ii}), f1{jj})
                addedDefaultValue = true;
                fprintf('\n\n Adding missing default setting "%s.%s" from default_Settings.m\n', ...
                    f0{ii}, f1{jj})
            end
        end
    end


    % Now go through the user's settings file and replace all fields in the default with those.
    % This ensures that any values the user file has the should not be there will be removed. 
    f0 = fields(DEFAULT_SETTINGS);
    for ii = 1:length(f0);
        f1 = fields(DEFAULT_SETTINGS.(f0{ii}));

        for jj = 1:length(f1)
            outputSettings.(f0{ii}).(f1{jj}) = settingsFromYML.(f0{ii}).(f1{jj});
        end
    end



    % Make sure all settings that are returned are valid
    % If they are not, we replace them with the original default value
    [outputSettings,allValid] = checkSettingsAreValid(outputSettings); % see private directory



    if ~allValid
        fprintf('\n ********************************************************************\n')
        fprintf(' * YOU HAVE INVALID VALUES IN %s (see above). \n', settingsFile)
        fprintf(' * They have been replaced with valid defaults. \n')
        fprintf(' **********************************************************************\n')
    end


    % If there are missing or invalid values we will replace these in the settings file as well as making
    % a backup copy of the original file.
    if isempty(backupSettingsDir)
        return
    end

    if ~allValid || addedDefaultValue
       % Copy file
       backupFname = fullfile(backupSettingsDir, ...
            [datestr(now, 'yyyy_mm_dd__HH_MM_SS_'),zapit.settings.returnZapitSettingsFileName]);
       fprintf('Making backup of settings file at %s\n', backupFname)
       copyfile(settingsFile,backupFname)

       % Write the new file to the settings location
       fprintf('Replacing settings file with updated version\n')
       zapit.yaml.WriteYaml(settingsFile,outputSettings);
    end

    % Ensure we don't have too many backup files
    backupFiles = dir(fullfile(backupSettingsDir,'*.yml'));
    if length(backupFiles) > outputSettings.general.maxSettingsBackUpFiles
        [~,ind]=sort([backupFiles.datenum],'descend');
        backupFiles = backupFiles(ind); % make certain they are in date order
        backupFiles = backupFiles(outputSettings.general.maxSettingsBackUpFiles+1:end);
        % Delete only these
        for ii = length(backupFiles):-1:1
            delete(fullfile(backupFiles(ii).folder,backupFiles(ii).name))
        end
    end

end % readSettings
