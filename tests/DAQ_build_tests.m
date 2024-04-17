classdef DAQ_build_tests < matlab.unittest.TestCase
    % Tests associated with whether the DAQ builds correctly

    properties
        DAQ = [];
    end %properties


    methods(TestClassSetup)
        function buildDAQ(obj)
            obj.DAQ = zapit.hardware.DAQ.dotNETwrapper;
        end
    end

    methods(TestClassTeardown)
        function closeBT(obj)
            delete(obj.DAQ);
        end
    end





    methods (Test)

        function chanStringWith_Dev1(obj)
            %Check that the dummy laser turn on/off methods toggle the isLaserOn property
            obj.DAQ.device_ID = 'Dev3';
            chanString = obj.DAQ.genChanString(0:3);
            obj.verifyEqual(chanString,'Dev3/ao0,Dev3/ao1,Dev3/ao2,Dev3/ao3')
        end

        function chanStringWith_ZAPTEST(obj)
            %Check that the dummy laser turn on/off methods toggle the isLaserOn property
            obj.DAQ.device_ID = 'ZAPTEST';
            chanString = obj.DAQ.genChanString(0:3);
            obj.verifyEqual(chanString,'ZAPTEST/ao0,ZAPTEST/ao1,ZAPTEST/ao2,ZAPTEST/ao3')
        end
    end %methods (Test)




end %classdef DAQ_build_tests < matlab.unittest.TestCase
