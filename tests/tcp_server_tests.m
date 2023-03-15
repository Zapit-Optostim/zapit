classdef tcp_server_tests < matlab.unittest.TestCase
    % Tests of the tcp/ip server. Tests here pick up where the
    % interface module tests leave off
    %
    % NOTE: tests will fail if you don't have the TCP server
    % enabled in the settings file.

    % TODO -- test also the API state: zapit.pointer.state
    %            idle, rampdown, stim 
    properties
        client
        hZPview
        hZP
        stimConfigFname
    end %properties


    methods(TestClassSetup)
        function buildZapit(obj)
            % Does Zapit build with dummy parameters?
            [obj.hZP, obj.hZPview] = start_zapit('simulated',true);

            % "calibrate" it. No transformation will be done.
            obj.hZP.refPointsSample = obj.hZP.refPointsStereotaxic;

            % To communicate with the server
            pause(0.05)
            obj.client = zapit.interfaces.TCPclient;

            obj.stimConfigFname = ...
             fullfile(zapit.updater.getInstallPath, ...
                'examples', ...
                'example_stimulus_config_files/', ...
                'uniAndBilateral_5_conditions.yml');
        end
    end
 
    methods(TestClassTeardown)
        function closeBT(obj)
            delete(obj.hZPview);
            delete(obj.client)
            delete(obj.hZP.tcpServer); % TODO temp: later is integrated 
            delete(obj.hZP);
        end
    end



    methods (Test)

        % Basic tests of the TCP server and client classes

        function checkMessageIsSent(obj)
            % Verify that a simple message is sent and recieved OK
            msg = 'my test message';
            obj.client.sendMessage(msg);
            pause(0.05)

            obj.verifyClass(obj.hZP.tcpServer.buffer,"struct")
            obj.verifyTrue(isequal(msg,obj.hZP.tcpServer.buffer.message))
            obj.verifyFalse(isequal(msg(1:end-3),obj.hZP.tcpServer.buffer.message))
        end


        function sendJunk(obj)
            % Verify that a junk command returns -1  

            % Use low-level commands
            obj.client.sendMessage('NOT_A_VALID_COMMAND');
            pause(0.05)
            obj.verifyClass(obj.client.buffer, "struct")
            obj.verifyTrue(isequal('-1',obj.client.buffer.message))

            % Use high-level function to do the same thing twice
            response = obj.client.sendCommand('NOT_A_VALID_COMMAND');
            obj.verifyTrue(isequal('-1',response))

            response = obj.client.sendCommand('NOT_A_VALID_COMMAND');
            obj.verifyTrue(isequal('-1',response))
        end % sendJunk


        function checkStimLoaded(obj)
            response = obj.client.sendCommand('scl?');
            obj.verifyTrue(isequal('0',response))

            response = obj.client.sendCommand('stimConfLoaded?');
            obj.verifyTrue(isequal('0',response))

            % Now load a settings and verify that it recognises this
            obj.hZP.loadStimConfig(obj.stimConfigFname);
            response = obj.client.sendCommand('scl?');
            obj.verifyTrue(isequal('1',response))

            obj.hZP.stimConfig = [];

        end % checkStimLoaded


        function checkTwoIdenticalResponsesBackToBack(obj)
            % Confirm the system does not lock up when there are two 
            % identical responses recieved back to back. This could
            % happen if it's waiting for a value to change but it does
            % not.
            response = obj.client.sendCommand('scl?');
            obj.verifyTrue(isequal('0',response))

            response = obj.client.sendCommand('scl?');
            obj.verifyTrue(isequal('0',response))
        end % checkStimLoaded


        function checkNumConditions(obj)
            % Read correctly the number of stimulus conditions
            obj.hZP.loadStimConfig(obj.stimConfigFname);

            response = obj.client.sendCommand('ncs?');
            obj.verifyTrue(isequal('5',response))

            response = obj.client.sendCommand('numConditions?');
            obj.verifyTrue(isequal('5',response))

            obj.hZP.stimConfig = [];

        end % checkNumConditions

        function checkReadIdleState(obj)
            response = obj.client.sendCommand('res?');
            obj.verifyTrue(strcmp('idle',response))

            response = obj.client.sendCommand('returnState?');
            obj.verifyTrue(strcmp('idle',response))
        end % checkReadIdleState


        % TODO - Test for stopping optostim
        % TODO - Tests for sendSamples. 
        % TODO - Need a way of determining which stim is being presented. 

    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests

    end



end %classdef interfaces_tests < matlab.unittest.TestCase
