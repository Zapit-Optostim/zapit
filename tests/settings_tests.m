classdef settings_tests < matlab.unittest.TestCase
    % Tests of the updater pipeline

    properties
        dataDir = 'settings_tests_data';
    end %properties


    methods(TestClassSetup)

    end


    methods (Test)

        function basicTest(obj)
            % Can we read in a current, correct, settings file?
            expected = obj.loadSettingsExample('zapitSystemSettings_01.mat');
            actual = zapit.settings.readSettings(fullfile(obj.dataDir,'zapitSystemSettings_01.yml'));
            obj.verifyEqual(actual,expected)
        end

    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests
        function settings  = loadSettingsExample(obj,fname);
            load(fullfile(obj.dataDir,fname));
            settings
        end
    end



end %classdef zapit_build_tests < matlab.unittest.TestCase
