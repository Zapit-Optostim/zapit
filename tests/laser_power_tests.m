classdef laser_power_tests < matlab.unittest.TestCase
    % These tests ensure that future changes to the code will not alter the laser power calcs
    %
    %


    properties
        hZP = [];  % Class instance will go here
        chanSamples % The pre-computed data
        configDir = './waveform_tests_data/'; %use settings file found here for these tests
    end %properties


    methods(TestClassSetup)
        function buildZapit(obj)
            % Does Zapit build with dummy parameters?
            fprintf('Building Zapit API object\n')

            % Load settings from the test data directory
            obj.hZP =  zapit.pointer('simulated',true, ...
                            'settingsFile',fullfile(obj.configDir,'zapitSystemSettings.yml'));
            obj.verifyClass(obj.hZP,'zapit.pointer');

            obj.hZP.listeners.saveSettings.Enabled=0; % To ensure the settings are not changed

        end
    end

    methods(TestClassTeardown)
        function closeBT(obj)
            fprintf('Closing down Zapit API object\n')
            delete(obj.hZP);
        end
    end





    methods (Test)
        function checkLinearPowers(obj)
            % the following were just derived by running laser_mW_to_control
            % at the CLI on 20th July 2026 with the above settings file. No
            % future change should ever cause these to differ
            mW = [3,30,50];
            vC = [0.2132, 2.5816, 4.3360];

            for ii=1:length(mW)
                test_vC = obj.hZP.laser_mW_to_control(mW(ii));
                obj.verifyEqual(round(vC(ii),3), round(test_vC,3))
            end
        end
    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests


    end

end %classdef zapit_build_tests < matlab.unittest.TestCase
