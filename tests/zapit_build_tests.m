classdef zapit_build_tests < matlab.unittest.TestCase
    % Basic integration tests of the Zapit GUI with its dummy components.

    properties
        hZP = [];
        hZPview = [];
    end %properties


    methods(TestClassSetup)
        function buildZapit(obj)
            % Does Zapit build with dummy parameters?
            [obj.hZP, obj.hZPview] = start_zapit('simulated',true);
            obj.verifyClass(obj.hZP,'zapit.pointer');
            obj.verifyClass(obj.hZPview,'zapit.gui.main.controller');
        end
    end
 
    methods(TestClassTeardown)
        function closeBT(obj)
            delete(obj.hZPview);
            delete(obj.hZP);
        end
    end





    methods (Test)

        function checkSimulated(obj)
            %Check that the dummy laser turn on/off methods toggle the isLaserOn property
            obj.assumeTrue(obj.hZP.simulated, 'Tests must run in simulated mode');
        end

        function componentsPresent(obj)
            %Check that all components are present (basic)
            obj.verifyNotEmpty(obj.hZP.settings);
            obj.verifyNotEmpty(obj.hZP.DAQ);
            obj.verifyNotEmpty(obj.hZP.cam);
        end

        function componentsCorrectClass(obj)
            %Check that all components are of the correct class
            obj.verifyInstanceOf(obj.hZP.settings,'struct');
            obj.verifyInstanceOf(obj.hZP.DAQ,'zapit.simulated.DAQ');
            obj.verifyInstanceOf(obj.hZP.cam,'zapit.simulated.camera');
        end



    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests

    end



end %classdef zapit_build_tests < matlab.unittest.TestCase
