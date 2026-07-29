classdef settings_tests < matlab.unittest.TestCase
    % Tests of the updater pipeline
    %
    % Purpose
    % We wish to ensure that settings values entered by the user into the YAML are valid. 
    % To make sure this is the case, all entered values are tested upon load. This testing
    % class ensures this is being correctly. 



    properties
        dataDir = 'settings_tests_data';
    end %properties


    methods(TestClassSetup)

    end


    methods (Test)

        %%
        % Unit tests of the methods used to test the validity and pre-process settings. 
        function test_isnumeric(obj)
            import zapit.settings.settingsValuesTests.*
            D.f0.f1 = 1; % "Default" value

            A.f0.f1 = 1; % Actual value
            [~,out] = check_isnumeric(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = 0;
            [~,out] = check_isnumeric(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = 1234;
            [~,out] = check_isnumeric(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = [1,2,4];
            [~,out] = check_isnumeric(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = '1';
            [~,out] = check_isnumeric(A,D,'f0','f1');
            obj.verifyFalse(out)
        end


        function test_ischar(obj)
            import zapit.settings.settingsValuesTests.*
            D.f0.f1 = 'mystr'; % "Default" value

            A.f0.f1 = 0;
            [~,out] = check_ischar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = 1234;
            [~,out] = check_ischar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = [1,2,4];
            [~,out] = check_ischar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = '1';
            [~,out] = check_ischar(A,D,'f0','f1');
            obj.verifyTrue(out)
        end

        function test_isscalar(obj)
            import zapit.settings.settingsValuesTests.*
            D.f0.f1 = 1; % "Default" value

            A.f0.f1 = -1;
            [~,out] = check_isscalar(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = 0;
            [~,out] = check_isscalar(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = 1234;
            [~,out] = check_isscalar(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = [1,2,4];
            [~,out] = check_isscalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            % For our purposes we treat a scalar as a number not a character
            A.f0.f1 = '1';
            [~,out] = check_isscalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = 'a';
            [~,out] = check_isscalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = 'Uma';
            [~,out] = check_isscalar(A,D,'f0','f1');
            obj.verifyFalse(out)
        end

        function test_isZeroOrGreaterScalar(obj)
            import zapit.settings.settingsValuesTests.*
            D.f0.f1 = 1; % "Default" value

            A.f0.f1 = -1;
            [~,out] = check_isZeroOrGreaterScalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = 0;
            [~,out] = check_isZeroOrGreaterScalar(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = 1234;
            [~,out] = check_isZeroOrGreaterScalar(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = [1,2,4];
            [~,out] = check_isZeroOrGreaterScalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            % For our purposes we treat a scalar as a number not a character
            A.f0.f1 = '1';
            [~,out] = check_isZeroOrGreaterScalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = 'a';
            [~,out] = check_isZeroOrGreaterScalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = 'Uma';
            [~,out] = check_isZeroOrGreaterScalar(A,D,'f0','f1');
            obj.verifyFalse(out)
        end

        function test_isLogicalScalar(obj)
            import zapit.settings.settingsValuesTests.*
            D.f0.f1 = 1; % "Default" value

            A.f0.f1 = 1;
            [~,out] = check_isLogicalScalar(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = 0;
            [~,out] = check_isLogicalScalar(A,D,'f0','f1');
            obj.verifyTrue(out)

            A.f0.f1 = -1;
            [~,out] = check_isLogicalScalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = 1234;
            [~,out] = check_isLogicalScalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = [1,2,4];
            [~,out] = check_isLogicalScalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            % For our purposes we treat a scalar as a number not a character
            A.f0.f1 = '1';
            [~,out] = check_isLogicalScalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = 'a';
            [~,out] = check_isLogicalScalar(A,D,'f0','f1');
            obj.verifyFalse(out)

            A.f0.f1 = 'Uma';
            [~,out] = check_isLogicalScalar(A,D,'f0','f1');
            obj.verifyFalse(out)
        end

        function test_convert_cell2mat(obj)
            import zapit.settings.settingsValuesTests.*
            A.f0.f1 = {1,2,3};
            OUT = convert_cell2mat(A,[],'f0','f1');
            obj.verifyEqual(OUT.f0.f1,[1,2,3])
        end


        %%
        % Test reading of settings files
        function possibleSettingsLocationsAreReturned(obj)
            % The settings file locations can be enumerated
            %
            % NOTE: we deliberately do NOT call zapit.settings.readSettings with no input
            % argument here. That reads the *real* settings file on this machine and, if
            % anything in it is out of date, backs it up and re-writes it. It also prunes
            % the user's backup settings files down to general.maxSettingsBackUpFiles. On
            % a machine with no settings file at all, zapit.settings.findSettingsFile
            % blocks on an interactive input() prompt and the test would hang. A test must
            % not do any of that, so we only check the (side-effect free) lookup of where
            % settings files may live.
            S = zapit.settings.possibleSettingsLocations;
            obj.verifyClass(S,'struct')
            obj.verifyNotEmpty(S)
            obj.verifyTrue(isfield(S,'settingsLocation'))
        end

        function basicTest(obj)
            % Can we read in a current, correct, settings file?
            expected = obj.loadSettingsExample('zapitSystemSettings_01.mat');
            actual = zapit.settings.readSettings(fullfile(obj.dataDir, ...
                        'zapitSystemSettings_01.yml'));
            obj.verifyEqual(actual,expected)
        end

        function fixWrongValues(obj)
            % Can we fix incorrect values?
            expected = zapit.settings.default_settings;
            [actual,allValid] = zapit.settings.readSettings(fullfile(obj.dataDir, ...
                        'zapitSystemSettings_wrong_values_01.yml'));

            obj.verifyFalse(allValid)
            obj.verifyEqual(actual.general, expected.general)
            obj.verifyEqual(actual.NI, expected.NI)

            % Name the specific corrections, so the test says what it is protecting rather
            % than relying on a whole-section comparison that happens to come out equal.
            obj.verifyEqual(actual.general.maxSettingsBackUpFiles, ...
                            expected.general.maxSettingsBackUpFiles)  % was -10
            obj.verifyEqual(actual.general.openPythonBridgeOnStartup, ...
                            expected.general.openPythonBridgeOnStartup) % was 290
            obj.verifyEqual(actual.NI.device_ID, expected.NI.device_ID) % was numeric 123
            obj.verifyEqual(actual.NI.samplesPerSecond, ...
                            expected.NI.samplesPerSecond) % was the string 'WRONG'
            obj.verifyEqual(actual.NI.triggerChannel, expected.NI.triggerChannel) % was -1
        end

        function validValuesSurviveAlongsideInvalidOnes(obj)
            % Fixing bad values must not blanket-reset the rest of the file
            %
            % This is the real risk in this code path: an implementation that simply
            % returned the defaults whenever anything was wrong would satisfy
            % fixWrongValues above but would silently throw away the whole of the user's
            % configuration. Each field checked here is valid in the fixture and differs
            % from the default, so it can only have the fixture's value if it was kept.
            defaults = zapit.settings.default_settings;
            actual = zapit.settings.readSettings(fullfile(obj.dataDir, ...
                        'zapitSystemSettings_wrong_values_01.yml'));

            obj.verifyEqual(actual.camera.default_exposure, 10)
            obj.verifyEqual(actual.calibrateScanners.beam_calib_exposure, 2)
            obj.verifyEqual(actual.experiment.blankingTime_ms, 1.5)
            obj.verifyEqual(actual.calibrateSample.refAP, -6)
            obj.verifyEqual(actual.laser.maxValueInGUI, 20)

            % Guard the premise of the test: if any of the above ever becomes equal to the
            % default then that assertion silently stops proving anything.
            obj.verifyNotEqual(actual.camera.default_exposure, defaults.camera.default_exposure)
            obj.verifyNotEqual(actual.experiment.blankingTime_ms, defaults.experiment.blankingTime_ms)
        end

        function checkRenameField(obj)
            % Can we fix a field that has an old name to a new name?
            %
            % The fixture holds experiment.defaultLaserFrequencyHz, which is the old name
            % for defaultLaserModulationFrequencyHz and the only entry in the namesToReplace
            % table in zapit.settings.readSettings. Its value (33) is deliberately not the
            % default (40), so the test fails if the value is lost and the default is used.
            [actual,allValid] = zapit.settings.readSettings(fullfile(obj.dataDir, ...
                        'zapitSystemSettings_fieldNameChanged_01.yml'));

            % The value moved across to the new name
            obj.verifyEqual(actual.experiment.defaultLaserModulationFrequencyHz, 33)

            % ...and the old name is gone from what we hand back
            obj.verifyFalse(isfield(actual.experiment,'defaultLaserFrequencyHz'))

            % An old settings file is, correctly, reported as needing to be re-written
            obj.verifyFalse(allValid)
        end

        function missingFieldIsFilledFromDefaults(obj)
            % A settings file written by an older Zapit lacks fields we have since added
            %
            % The fixture is identical to zapitSystemSettings_01.yml except that
            % experiment.blankOffsetShift_ms has been removed. Every value present is
            % valid, so this also isolates the "field set differs" route to allValid being
            % false from the "a value is invalid" route tested by fixWrongValues.
            defaults = zapit.settings.default_settings;
            [actual,allValid] = zapit.settings.readSettings(fullfile(obj.dataDir, ...
                        'zapitSystemSettings_missingField_01.yml'));

            obj.verifyTrue(isfield(actual.experiment,'blankOffsetShift_ms'))
            obj.verifyEqual(actual.experiment.blankOffsetShift_ms, ...
                            defaults.experiment.blankOffsetShift_ms)
            obj.verifyFalse(allValid)

            % The fields that were present are untouched
            obj.verifyEqual(actual.experiment.blankingTime_ms, 1.5)
        end

        function staleFieldIsDropped(obj)
            % A setting we no longer recognise must not be passed back to the caller
            actual = zapit.settings.readSettings(fullfile(obj.dataDir, ...
                        'zapitSystemSettings_wrong_values_01.yml'));

            obj.verifyFalse(isfield(actual.NI,'EXTRASETTING'))
        end

        function fieldOrderDoesNotAffectValidity(obj)
            % Re-ordering fields in the YAML must not make a valid file "invalid"
            %
            % zapitSystemSettings_01.yml deliberately lists the fields of its "laser" and
            % "camera" sections in a different order to default_settings.m. Every field is
            % present and every value is valid, so it must come back as valid. If this
            % fails, zapit.settings.readSettings has gone back to comparing field names
            % with isequal (which is order sensitive) rather than setxor -- which would
            % nag the user and needlessly re-write their settings file over nothing.
            %
            % Note: should this ever fail because a *value* in the fixture became invalid,
            % the offending setting is named on the CLI by the relevant check_ function.
            [~,allValid] = zapit.settings.readSettings(fullfile(obj.dataDir, ...
                        'zapitSystemSettings_01.yml'));

            obj.verifyTrue(allValid)
        end

        function suppliedSettingsFileIsNotModified(obj)
            % readSettings must never touch a settings file whose path was passed in
            %
            % This is a documented guarantee and the reason tests can safely point
            % readSettings at fixtures. We use the fixture with bad values so that
            % readSettings definitely *wants* to re-write it.
            tDir = tempname;
            mkdir(tDir)
            tidyUp = onCleanup(@() rmdir(tDir,'s')); %#ok<NASGU>

            tFile = fullfile(tDir,'zapitSystemSettings.yml');
            copyfile(fullfile(obj.dataDir,'zapitSystemSettings_wrong_values_01.yml'), tFile)

            before = dir(tFile);
            zapit.settings.readSettings(tFile);
            after = dir(tFile);

            obj.verifyEqual(after.bytes, before.bytes, ...
                'readSettings changed the size of a settings file that was passed in')
            obj.verifyEqual(after.datenum, before.datenum, ...
                'readSettings re-wrote a settings file that was passed in')

            % No backup copies should have appeared either
            obj.verifyNumElements(dir(fullfile(tDir,'*.yml')), 1)
        end

        %%
        % Tests that guard against the test fixtures drifting away from the schema in
        % default_settings.m. Without these the fixtures silently rot: a setting removed
        % from default_settings.m stays in the YAML files for years and every test run
        % prints the "YOU HAVE INVALID OR OLD SETTINGS" banner until someone hand-diffs
        % the files. (Compare shippedExampleConfigsHaveValidKeys in stimConfig_tests.)

        function fixtureFilesMatchCurrentSchema(obj)
            % Every settings fixture must use the current set of field names
            %
            % Deviations that a fixture needs in order to do its job are listed in
            % allowedDeviations below. Anything else is drift and fails here. If you add a
            % setting to default_settings.m, or rename or remove one, this test tells you
            % exactly which fixtures need updating.
            DEFAULTS = zapit.settings.default_settings;
            defaultSections = fields(DEFAULTS);

            % Columns: fixture name (no extension), section, field allowed to differ
            allowedDeviations = { ...
                'zapitSystemSettings_wrong_values_01',     'NI',         'EXTRASETTING'; ...
                'zapitSystemSettings_fieldNameChanged_01', 'experiment', 'defaultLaserFrequencyHz'; ...
                'zapitSystemSettings_fieldNameChanged_01', 'experiment', 'defaultLaserModulationFrequencyHz'; ...
                'zapitSystemSettings_missingField_01',     'experiment', 'blankOffsetShift_ms'; ...
                };

            d = dir(fullfile(obj.dataDir,'*.yml'));
            obj.assertNotEmpty(d, 'No settings fixtures were found')

            for ii = 1:length(d)
                [~,fixtureName] = fileparts(d(ii).name);
                S = zapit.yaml.ReadYaml(fullfile(d(ii).folder, d(ii).name));

                extraSections = setdiff(fields(S), defaultSections);
                obj.verifyEmpty(extraSections, sprintf('%s has unknown section(s): %s', ...
                    d(ii).name, strjoin(extraSections,', ')))

                for jj = 1:length(defaultSections)
                    thisSection = defaultSections{jj};
                    obj.assertTrue(isfield(S,thisSection), ...
                        sprintf('%s is missing the section "%s"', d(ii).name, thisSection))

                    differences = setxor(fields(DEFAULTS.(thisSection)), fields(S.(thisSection)));

                    % Remove the deviations this fixture is entitled to have
                    isAllowed = strcmp(allowedDeviations(:,1), fixtureName) & ...
                                strcmp(allowedDeviations(:,2), thisSection);
                    differences = setdiff(differences, allowedDeviations(isAllowed,3));

                    obj.verifyEmpty(differences, sprintf(...
                        ['%s section "%s" does not match default_settings.m. ', ...
                         'Offending field(s): %s'], ...
                        d(ii).name, thisSection, strjoin(differences,', ')))
                end
            end
        end

        function matBaselineMatchesCurrentSchema(obj)
            % The .mat that basicTest compares against must track default_settings.m
            %
            % This baseline is a saved copy of a previously read settings structure, so it
            % does not update itself when the schema changes. When it drifts, basicTest
            % fails with an unhelpful whole-struct inequality; this test names the fields.
            expected = obj.loadSettingsExample('zapitSystemSettings_01.mat');
            DEFAULTS = zapit.settings.default_settings;

            sectionDiff = setxor(fields(DEFAULTS), fields(expected));
            obj.verifyEmpty(sectionDiff, sprintf(...
                'zapitSystemSettings_01.mat section(s) out of date: %s', ...
                strjoin(sectionDiff,', ')))

            f0 = fields(DEFAULTS);
            for ii = 1:length(f0)
                if ~isfield(expected,f0{ii})
                    continue % already reported above
                end
                fieldDiff = setxor(fields(DEFAULTS.(f0{ii})), fields(expected.(f0{ii})));
                obj.verifyEmpty(fieldDiff, sprintf(...
                    'zapitSystemSettings_01.mat section "%s" is out of date. Field(s): %s', ...
                    f0{ii}, strjoin(fieldDiff,', ')))
            end
        end

        function settingsAndTestsAreInSync(obj)
            % Every setting must have a validation entry, and vice versa
            %
            % zapit.settings.checkSettingsAreValid indexes SETTINGS_TESTS with the field
            % names taken from DEFAULT_SETTINGS. A setting added to default_settings.m
            % without a matching setTests entry therefore breaks reading of the settings
            % file, which happens on startup. Catch it here instead.
            [DEFAULTS,TESTS] = zapit.settings.default_settings;

            sectionDiff = setxor(fields(DEFAULTS), fields(TESTS));
            obj.verifyEmpty(sectionDiff, sprintf(...
                'settings and setTests have different sections: %s', strjoin(sectionDiff,', ')))

            f0 = fields(DEFAULTS);
            for ii = 1:length(f0)
                if ~isfield(TESTS,f0{ii})
                    continue % already reported above
                end
                fieldDiff = setxor(fields(DEFAULTS.(f0{ii})), fields(TESTS.(f0{ii})));
                obj.verifyEmpty(fieldDiff, sprintf(...
                    ['settings.%s and setTests.%s do not have the same fields. ', ...
                     'Offending field(s): %s'], f0{ii}, f0{ii}, strjoin(fieldDiff,', ')))
            end
        end

        function checkIPtestWorks(obj)
            % Does the regular expression we have for checking for an IP address work?
            import zapit.settings.settingsValuesTests.*
            defaultStruct = struct('server',struct('IP','localhost'));
            actualStruct =  struct('server',struct('IP','localhost'));
            sectionName = 'server';
            fieldName = 'IP';

            % These are valid values for the IP
            [~,isValid] = check_isIPaddress(actualStruct,defaultStruct,sectionName,fieldName);
            obj.verifyTrue(isValid)

            actualStruct.server.IP = '127.0.0.1';
            [~,isValid] = check_isIPaddress(actualStruct,defaultStruct,sectionName,fieldName);
            obj.verifyTrue(isValid)

            actualStruct.server.IP = '0.0.0.0';
            [~,isValid] = check_isIPaddress(actualStruct,defaultStruct,sectionName,fieldName);
            obj.verifyTrue(isValid)

            actualStruct.server.IP = '255.255.255.255';
            [~,isValid] = check_isIPaddress(actualStruct,defaultStruct,sectionName,fieldName);
            obj.verifyTrue(isValid)


            % These are invalid values for the IP
            actualStruct.server.IP = '255.255.255.';
            [~,isValid] = check_isIPaddress(actualStruct,defaultStruct,sectionName,fieldName);
            obj.verifyFalse(isValid)

            actualStruct.server.IP = '255.255.255';
            [~,isValid] = check_isIPaddress(actualStruct,defaultStruct,sectionName,fieldName);
            obj.verifyFalse(isValid)

            actualStruct.server.IP = '255.255.255.sdf';
            [~,isValid] = check_isIPaddress(actualStruct,defaultStruct,sectionName,fieldName);
            obj.verifyFalse(isValid)

            actualStruct.server.IP = 'localh';
            [~,isValid] = check_isIPaddress(actualStruct,defaultStruct,sectionName,fieldName);
            obj.verifyFalse(isValid)

            actualStruct.server.IP = 'Localhost';
            [~,isValid] = check_isIPaddress(actualStruct,defaultStruct,sectionName,fieldName);
            obj.verifyFalse(isValid)
        end
    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests
        function settings  = loadSettingsExample(obj,fname)
            load(fullfile(obj.dataDir,fname),'settings');
        end
    end



end %classdef zapit_build_tests < matlab.unittest.TestCase
