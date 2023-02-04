classdef waveform_tests < matlab.unittest.TestCase
    % These tests ensure that future changes to the code will not alter the waveforms

    properties
        hZP = [];  % Class instance will go here
        chanSamples % The pre-computed data
        testDataDir = './waveform_tests_data/';
        configFname = 'uniAndBilateral_5_conditions.yml';


    end %properties


    methods(TestClassSetup)
        function buildZapit(obj)
            % Does Zapit build with dummy parameters?
            obj.hZP =  zapit.pointer('simulated',true);
            obj.verifyClass(obj.hZP,'zapit.pointer');
            fname = fullfile(obj.testDataDir,obj.configFname);
            obj.hZP.stimConfig = zapit.stimConfig(fname);
            obj.hZP.stimConfig.parent = obj.hZP;

            % "calibrate" it
            obj.hZP.refPointsSample = obj.hZP.refPointsStereotaxic;

            % Load data that we previously generated with these conditions
            obj.chanSamples = obj.loadChanSamples;
        end
    end
 
    methods(TestClassTeardown)
        function closeBT(obj)
            delete(obj.hZP);
        end
    end





    methods (Test)

        function checkWaveformsMatch(obj)
            %Check that the waveforms were generated correctly
            obj.verifyEqual(obj.hZP.stimConfig.chanSamples,obj.chanSamples);
        end

        function checkWaveformsDoNotMatch(obj)
            %Check that the waveforms differ if the "calibration" changes
            obj.hZP.refPointsSample(1,1) = obj.hZP.refPointsSample(1,1)+1;
            obj.verifyNotEqual(obj.hZP.stimConfig.chanSamples,obj.chanSamples);
            obj.hZP.refPointsSample = obj.hZP.refPointsStereotaxic; %return it
        end

    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests
        function chanSamples  = loadChanSamples(obj);
            load(fullfile(obj.testDataDir,'chanSamples.mat'));
        end
    end



end %classdef zapit_build_tests < matlab.unittest.TestCase
