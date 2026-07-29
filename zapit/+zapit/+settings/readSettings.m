function [outputSettings,allValid] = readSettings(fname)
    % Read Zapit settings YAML file and return as a structure
    %
    % function settings = zapit.settings.readSettings()
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
    %       this argument is defined.
    %
    % Outputs
    % settings - the zapit settings as a structure
    % allValid - [optional] true if the settings file was already fully up to date and
    %       valid. False if anything had to be corrected: an unknown (old) field was
    %       dropped, a missing field was filled from the defaults, or a value failed
    %       validation and was replaced. When allValid is false and we are reading the
    %       user's real settings file, that file is backed up and re-written. Note that
    %       the *order* fields appear in does not affect this: only which fields exist.
    %
    %
    % Rob Campbell - Basel 2017
    % Rob Campbell - SWC 2022

    outputSettings = [];
    allValid = true; % By default all settings are valid
    if nargin<1
        fname = [];
    end


    if isempty(fname)
        [settingsFile,backupSettingsDir] = zapit.settings.findSettingsFile;
    else
        settingsFile = fname;
        backupSettingsDir = []; % Do not write to backup settings at all
    end

    if ~exist(settingsFile,'file')
        fprintf('Can not find settings file %s\n', settingsFile)
        allValid = false; % Nothing was read, so we can not call the settings valid
        return
    end

    settingsFromYML = zapit.yaml.ReadYaml(settingsFile);

    %Check if the loaded settings are the same as the default settings
    DEFAULT_SETTINGS = zapit.settings.default_settings;

    % TODO -- does this ever run? Can we delete it?
    if isequal(settingsFromYML,DEFAULT_SETTINGS)
        fprintf(['\n\n *** The settings file at %s has never been edited\n ', ...
            '*** Press RETURN then edit the file for your system.\n'], settingsFile)
        fprintf(' *** For help editing the file see: https://github.com/BaselLaserMouse/zapit\n\n')

        pause

        edit(settingsFile)
        fprintf('\n\n *** Once you have finished editing the file, save it and press RETURN\n')

        pause
        outputSettings = zapit.settings.readSettings;
        [outputSettings,allValid] = zapit.settings.checkSettingsAreValid(outputSettings);
        return
    end



    % The following steps to ensure that the values in the user settings file are correct.


    %%
    % One
    % Report missing values to user settings file.
    % These will be added implicitly in the third step.

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


    %%
    % Two
    % Some fields have changed names over time. Should the user have an old value we want to
    % rename it to the new field name. If we do this here, then the redundant field will just
    % vanish in the next step. First column is OLD field name and second is the NEW name.
    namesToReplace = {...
                {'experiment','defaultLaserFrequencyHz'}, {'experiment','defaultLaserModulationFrequencyHz'}; ...
    };

    for ii=1:size(namesToReplace,1)
        oldName = namesToReplace{ii,1};
        newName = namesToReplace{ii,2};

        % Skip if this field name does not exist in the user settings file
        if ~isfield(settingsFromYML, oldName{1}) || ...
            ~isfield(settingsFromYML.(oldName{1}),(oldName{2}))
            continue
        end

        % If it's there we add the new value also (the old get's removed in the next step)
        settingsFromYML.(newName{1}).(newName{2}) = settingsFromYML.(oldName{1}).(oldName{2});
    end



    %%
    % Three
    % Go through the user's settings file and replace all fields in the default file with those.
    % This ensures that: 1) Any fields not in the user's file will appear and 2) any values only
    % in the user file will just vanish
    f0 = fields(DEFAULT_SETTINGS);
    for ii = 1:length(f0);
        f1 = fields(DEFAULT_SETTINGS.(f0{ii}));



        if ~isfield(settingsFromYML, f0{ii})
            % The section is missing from the user settings file so we will use the defaults
            allValid = false;
            continue
        end

        if ~isempty( setxor(fields(DEFAULT_SETTINGS.(f0{ii})), fields(settingsFromYML.(f0{ii}))) )
            % If the two have different fields then we need to replace the user settings
            % file on disk. This catches the case where the user has an old setting in
            % their user settings file and we want to remove it by re-saving the file.
            % It also catches a field that is missing from the user's file.
            %
            % setxor (the symmetric difference) is used rather than isequal because we care
            % only about *which* fields are present, not the order they appear in. fields()
            % returns names in the order they were created, which for the user's settings is
            % the order they happen to sit in the YAML. Comparing with isequal would then
            % flag a perfectly valid file as invalid purely because its fields are in a
            % different order to default_settings.m.
            allValid = false;
        end
        for jj = 1:length(f1)
            if isfield(settingsFromYML.(f0{ii}), f1{jj})
                outputSettings.(f0{ii}).(f1{jj}) = settingsFromYML.(f0{ii}).(f1{jj});
            end
        end
    end



    %%
    % Four
    % Make sure all settings that are returned are valid
    % If they are not, we replace them with the original default value
    [outputSettings,allValidCheck] = zapit.settings.checkSettingsAreValid(outputSettings); % see private directory

    % Because settings will return as valid even if an old setting exists.
    % Use && rather than * so that allValid stays a logical: it is returned to the caller
    % and a double 0/1 would not satisfy verifyTrue/verifyFalse in the tests.
    allValid = allValid && allValidCheck;

    if ~allValid
        fprintf('\n ********************************************************************\n')
        fprintf(' * YOU HAVE INVALID OR OLD SETTINGS IN %s. \n', settingsFile)
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
            [char(datetime('now','Format','yyyy_MM_dd__HH_mm_ss_')),zapit.settings.returnZapitSettingsFileName]);
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
