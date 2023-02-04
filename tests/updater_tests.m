classdef updater_tests < matlab.unittest.TestCase
    % Simple tests of the updater pipeline

    properties
        vStruct % version structure
    end %properties


    methods(TestClassSetup)
        function getVersion(obj)
            obj.vStruct = zapit.version;
        end
    end


    methods (Test)

        function versionStructReasonable(obj)
            v = obj.vStruct.version;
            obj.verifyClass(v.MAJOR,'double')
            obj.verifyClass(v.MINOR,'double')
            obj.verifyClass(v.PATCH,'double')
            obj.verifyClass(v.preReleaseString,'char')
            obj.verifyClass(v.string,'char')
        end


        function checkDateIsReasonable(obj)
            d = obj.vStruct.date;
            obj.verifyClass(d.year,'double')
            obj.verifyClass(d.month,'double')
            obj.verifyClass(d.day,'double')

            obj.verifyGreaterThanOrEqual(d.year,2023)
            obj.verifyGreaterThanOrEqual(d.month,1)
            obj.verifyLessThanOrEqual(d.month,12)
            obj.verifyGreaterThanOrEqual(d.day,1)
            obj.verifyLessThanOrEqual(d.day,31)
        end


        function versionMesssageReasonable(obj)
            % Check whether the zapit version is producing the output we expect
            msg = obj.vStruct.message;
            obj.verifyEqual(regexp(msg,'^Zapit version \d+\.\d+\.\d+  --  \d{4}/\d+/\d+'),1);
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
