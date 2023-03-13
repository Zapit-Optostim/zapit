classdef utils_tests < matlab.unittest.TestCase
    % Simple tests of the utils module

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



end %classdef utils_tests < matlab.unittest.TestCase
