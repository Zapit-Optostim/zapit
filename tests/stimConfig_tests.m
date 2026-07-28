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


        % - - - - Presentability (blanking vs points) checks - - - -

        function presentableConfigLoads(obj)
            % A config all of whose conditions can be presented loads successfully
            success = obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'power_ok.yml'));
            obj.verifyTrue(success);
            obj.verifyEmpty(obj.hZP.stimConfig.returnUnpresentableConditions);
        end

        function unpresentableConfigIsRefused(obj)
            % A config containing an un-presentable condition is refused, and the previously
            % loaded config is preserved untouched.
            obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'power_ok.yml'));
            priorNumConditions = obj.hZP.stimConfig.numConditions;

            success = obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'unpresentable.yml'));
            obj.verifyFalse(success);

            % Previous config must still be loaded and unchanged
            obj.verifyEqual(obj.hZP.stimConfig.numConditions, priorNumConditions);
            [~,fname] = fileparts(obj.hZP.stimConfig.configFileName);
            obj.verifyEqual(fname, 'power_ok');
        end

        function unpresentableConditionsIdentified(obj)
            % Pure check of the method: at 1000 Hz the 3-point condition (index 2) can not be
            % presented but the 2-point condition (index 1) can.
            sc = zapit.stimConfig(fullfile(obj.testDataDir,'unpresentable.yml'));
            sc.parent = obj.hZP;
            obj.verifyEqual(sc.returnUnpresentableConditions, 2);
            delete(sc)
        end

        function tooManyPointsRefusedAtRealisticFreq(obj)
            % Realistic 40 Hz config: condition 1 has an acceptable number of points (4),
            % condition 2 has too many (60; the limit is ~55 at these settings). The offending
            % condition is identified and the whole config is refused, preserving the prior one.
            obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'power_ok.yml'));

            sc = zapit.stimConfig(fullfile(obj.testDataDir,'too_many_points_40Hz.yml'));
            sc.parent = obj.hZP;
            obj.verifyEqual(sc.returnUnpresentableConditions, 2);
            delete(sc)

            success = obj.hZP.loadStimConfig(fullfile(obj.testDataDir,'too_many_points_40Hz.yml'));
            obj.verifyFalse(success);
            [~,fname] = fileparts(obj.hZP.stimConfig.configFileName);
            obj.verifyEqual(fname, 'power_ok'); % previous config preserved
        end

    end % methods (Test)

end % classdef stimConfig_tests
