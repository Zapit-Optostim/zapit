function [settings,allValid] = checkSettingsAreValid(settings)
    % Check that all settings that are read in are valid
    %
    % function [settings,allValid] = checkSettingsAreValid(settings)
    %
    % Purpose
    % Attempt to stop weird errors that could be caused by the user entering a weird setting.
    % This function *also* converts some values from cells to vectors, as this is happens
    % when they are read in from the YAML. Consequently, this function must be run after data 
    % are read in!
    %
    %
    % Rob Campbell - SWC 2023

    allValid=true;
    [DEFAULT_SETTINGS,SETTINGS_TESTS] = zapit.settings.default_settings;

    % Loop through everything
    f0 = fields(DEFAULT_SETTINGS);
    for ii = 1:length(f0);
        f1 = fields(DEFAULT_SETTINGS.(f0{ii}));
        for jj = 1:length(f1)
            tests = SETTINGS_TESTS.(f0{ii}).(f1{jj});
            if isempty(tests)
                continue
            end

            for kk = 1:length(tests)
                test = tests{kk};
                [settings,isValid]=test(settings,DEFAULT_SETTINGS,f0{ii},f1{jj});
                if isValid==false
                    allValid=false;
                end
            end

        end
    end
