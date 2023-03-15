classdef interfaces_tests < matlab.unittest.TestCase
    % Simple tests of the interfaces module

    properties
        client
        server
    end %properties


    methods(TestClassSetup)
        function connectClientAndServer(obj)
            disp('CONNECTING TO CLIENT AND SERVER')
            obj.server = zapit.interfaces.TCPserver;
            pause(0.05)
            obj.client = zapit.interfaces.TCPclient;
            pause(0.05)
        end
    end

    methods(TestClassTeardown)
        function disconnect(obj)
            disp('Disconnecting from client and server')
            delete(obj.client)
            delete(obj.server)
        end
    end


    methods (Test)

        % Basic tests of the TCP server and client classes
        function checkSockets(obj)
            obj.verifyClass(obj.server.hSocket,'tcpserver.internal.TCPServer')
            obj.verifyClass(obj.client.hSocket,'tcpclient')
        end

        function checkMessageIsSent(obj)
            msg = 'my test message';
            obj.client.sendMessage(msg);
            pause(0.05)

            obj.verifyClass(obj.server.buffer,"struct")
            obj.verifyTrue(isequal(msg,obj.server.buffer.message))
            obj.verifyFalse(isequal(msg(1:end-3),obj.server.buffer.message))
        end

    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests

    end



end %classdef interfaces_tests < matlab.unittest.TestCase
