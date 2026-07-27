classdef stimConfig_tests < matlab.unittest.TestCase
    % Tests for load-time checks performed by zapit.stimConfig
    %
    % Currently focuses on checkLaserPower, which populates the observable property
    % conditionsExceedingLaserPower when a config is loaded.
    %
    % The fixtures assume the test settings file (waveform_tests_data/zapitSystemSettings.yml)
    % has laser.laserMinMax_mW(2) == 57 mW. Peak power for a single-point condition is exactly
    % 2x its requested power (duty cycle 0.5), so:
    %   power_ok.yml      : requested 20/25/28 mW -> peaks 40/50/56 -> none exceed 57
    %   power_exceeds.yml : requested 20/30/25/40 -> peaks 40/60/50/80 -> conditions 2 & 4 exceed
    %
    % Run these tests from the "tests" directory.

    properties
        hZP = [];
        testDataDir = './waveform_tests_data/';
    end % properties


    methods(TestClassSetup)
        function buildZapit(obj)
            fprintf('Building Zapit API object in simulated mode\n')
            obj.hZP = zapit.pointer('simulated', true, ...
                            'settingsFile', fullfile(obj.testDataDir,'zapitSystemSettings.yml'));
            obj.verifyClass(obj.hZP,'zapit.pointer');
            obj.hZP.listeners.saveSettings.Enabled = 0; % ensure the settings file is not modified
        end
    end


    methods(TestClassTeardown)
        function closeZapit(obj)
            delete(obj.hZP);
        end
    end


    methods (Test)

        function noConditionsExceedWhenWithinBudget(obj)
            % A config where every condition is within the laser budget flags nothing
            obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'power_ok.yml'));
            obj.verifyEmpty(obj.hZP.stimConfig.conditionsExceedingLaserPower);
        end

        function correctConditionsFlaggedWhenOverBudget(obj)
            % The exact offending condition indices are reported (not just "some breach")
            obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'power_exceeds.yml'));
            obj.verifyEqual(obj.hZP.stimConfig.conditionsExceedingLaserPower, [2 4]);
        end

        function returnValueMatchesStoredProperty(obj)
            % checkLaserPower returns the same vector it stores in the property
            obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'power_exceeds.yml'));
            out = obj.hZP.stimConfig.checkLaserPower;
            obj.verifyEqual(out, obj.hZP.stimConfig.conditionsExceedingLaserPower);
            obj.verifyEqual(out, [2 4]);
        end

        function loadingGoodConfigClearsPreviousBreach(obj)
            % Loading an over-budget config then a good one leaves the property empty
            obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'power_exceeds.yml'));
            obj.verifyNotEmpty(obj.hZP.stimConfig.conditionsExceedingLaserPower);
            obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'power_ok.yml'));
            obj.verifyEmpty(obj.hZP.stimConfig.conditionsExceedingLaserPower);
        end

        function emptyWhenNoParent(obj)
            % Without a parent (so no hardware settings) the check can not run: returns empty
            sc = zapit.stimConfig(fullfile(obj.testDataDir,'power_exceeds.yml'));
            obj.verifyEmpty(sc.checkLaserPower);
            delete(sc)
        end

    end % methods (Test)

end % classdef stimConfig_tests
