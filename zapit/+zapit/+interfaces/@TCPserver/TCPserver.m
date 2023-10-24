classdef TCPserver < handle
    % zapit.interfaces.TCPserver
    %
    % This class handles TCP/IP comms. If the tcpServer.enable setting is
    % set to "true" then a server is set up and attached to Zapit using the
    % port and IP address defined in the settings file.
    %
    %
    properties (Hidden)
        parent % instance of zapit.pointer to which we attached
        listeners  % Structure that holds listeners so they can be easily cleaned up in the destructor
        bytesInMessage = 16 % Number of bytes in incoming message
    end % properties

    properties
        hSocket % The server or client object will reside here
        port = 1488
        ip = 'localhost'
    end

    properties (SetObservable)
        buffer
    end


    methods

        function obj = TCPserver(varargin)
            % Inputs (optional param/val pairs)
            % 'ip' - [string] Is 'localhost' by default
            % 'port' - [numeric scalar] is 1488 by default
            
            % Do not proceed if Instrument Control Toolbox is not installed
            V = ver;
            VName = {V.Name};
            if ~any(strcmp(VName, 'Instrument Control Toolbox'))
                fprintf('\n** The TCP/IP server requires the Instrument Control Toolbox **\n\n')
                return
            end

            params = inputParser;
            params.CaseSensitive = false;

            params.addParameter('ip', obj.ip, @ischar)
            params.addParameter('port', obj.port, @isnumeric)

            params.parse(varargin{:})

            obj.ip = params.Results.ip;
            obj.port = params.Results.port;

            obj.hSocket = tcpserver(obj.ip, obj.port);
            obj.setupSocket;

            fprintf('Set up Zapit TCP server on %s port %d\n', obj.ip, obj.port)

            obj.listeners.bufferUpdated = addlistener(obj, 'buffer', 'PostSet', ...
                @obj.processBufferMessageCallback);

        end % Constructor

        function setupSocket(obj)
            % Set up for reading messages of 4 bytes
            configureCallback(obj.hSocket, "byte", obj.bytesInMessage, @obj.readDataFcn);
        end % setupSocket

        function readDataFcn(obj, src, ~)
            % Read "bytesInMessage" bytes from the
            msg = read(src, obj.bytesInMessage,"uint8");

            obj.buffer = struct('command', msg(1), ...
                                'ArgKeys', msg(2), ...
                                'ArgVals', msg(3), ...
                                'ConditionNumber', msg(4), ...
                                'stimDuration', typecast(uint8(msg(5:8)),'single'), ...
                                'laserPower_mW', typecast(uint8(msg(9:12)),'single'), ...
                                'startDelaySeconds', typecast(uint8(msg(13:16)),'single'));
        end % readDataFcn


        function delete(obj)
            if isempty(obj.hSocket)
                return
            end
            flush(obj.hSocket)
            clear obj.hSocket
            delete(obj.hSocket)
        end % Destructor


        function varargout = isClientConnected(obj)
            % Check if a client is currently connected to the server
            %
            % function zapit.interfaces.TCPserver.isClientConnected
            %
            % Purpose
            % Return true if a client is connected. False otherwise. If no output
            % argument is requested, the state is printed to screen.
            %
            % Inputs
            % none
            %
            % Outputs
            % isConnected - [optional] True if connected. False otherwise

            if isempty(obj.hSocket)
                isConnected = false;
            else
                isConnected = obj.hSocket.Connected;
            end

            if nargout>0
                varargout{1} = isConnected;
                return
            end

            if isConnected
                fprintf('Client is connected to the TCP server\n')
            else
                fprintf('No client is connected to the TCP server\n')
            end
        end % isClientConnected

    end % methods

end  % TCPserver

