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
        function readSettingsFile(obj)
            % Check we can read the regular settings file
            S = zapit.settings.readSettings;
            obj.verifyClass(S,'struct')
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
            actual = zapit.settings.readSettings(fullfile(obj.dataDir, ...
                        'zapitSystemSettings_wrong_values_01.yml'));

            obj.verifyEqual(actual.general, expected.general)
            obj.verifyEqual(actual.NI, expected.NI)
        end

        function checkRenameField(obj)
            % Can we fix a field that has an old name to a new name?
            expected = obj.loadSettingsExample('zapitSystemSettings_01.mat');
            actual = zapit.settings.readSettings(fullfile(obj.dataDir, ...
                        'zapitSystemSettings_fieldNameCHanged_01.yml'));

            obj.verifyEqual(actual.experiment, expected.experiment)
        end
    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests
        function settings  = loadSettingsExample(obj,fname);
            load(fullfile(obj.dataDir,fname));
        end
    end



end %classdef zapit_build_tests < matlab.unittest.TestCase
