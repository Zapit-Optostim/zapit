classdef utils_tests < matlab.unittest.TestCase
    % Simple tests of the updater pipeline

    properties

    end %properties


    methods(TestClassSetup)

    end


    methods (Test)

        function getDesktopPathExists(obj)
            obj.verifyEqual(exist(zapit.utils.getDesktopPath,'dir'),7)
        end


    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests

    end



end %classdef zapit_build_tests < matlab.unittest.TestCase
