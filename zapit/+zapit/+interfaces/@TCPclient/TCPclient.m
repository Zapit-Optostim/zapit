classdef TCPclient < handle

    properties (Hidden)
        listeners
    end

    properties
        connected
        hSocket % The server or client object will reside here
        port = 1488
        ip = 'localhost'
    end % properties

    properties (SetObservable)
        buffer
    end


    methods

        function obj = TCPclient(varargin)
            % Inputs (optional param/val pairs)
            % 'ip' - [string] Is 'localhost' by default (see zapit.interfaces.tcpip)
            % 'port' - [numeric scalar] is 1488 by default

            params = inputParser;
            params.CaseSensitive = false;

            params.addParameter('ip', obj.ip, @ischar)
            params.addParameter('port', obj.port, @isnumeric)

            params.parse(varargin{:})

            obj.ip = params.Results.ip;
            obj.port = params.Results.port;
            obj.connected = false;

            
        end % Constructor

        function response = connect(obj)
            % Build the client
            if obj.connected
                % Message to connect whilst already connected
                response = {-1.0,uint8(0),uint8(1),uint8(0)}; 
                return
            else
                % Message to connect whilst not connected
                obj.hSocket = tcpclient(obj.ip, obj.port);
                obj.setupSocket;
                obj.connected = true;
                response = {1.0,uint8(1),uint8(1),uint8(1)};
                return
            end
        end

        function response = close(obj)
            if obj.connected
                % Message to disconnect whilst connected
                delete(obj.hSocket);
                disp("TCPclient connection closed")
                obj.connected=false;
                response = {-1.0,uint8(1),uint8(0),uint8(0)};
                return
            else
                % Message to disconnect whilst not connected
                response = {-1.0,uint8(0),uint8(1),uint8(0)};
                return 
            end
        end

        function delete(obj)
            close(obj)
        end % Destructor


        function sendMessage(obj, byte_tuple)
            % Send a message to the server. Adds a new line. 
            % This should be treated as a lower-level function
            message = cell2mat(byte_tuple);
            write(obj.hSocket, message);
        end % sendMessage


        function reply = send_receive(obj,byte_tuple)
            if byte_tuple{1} == uint8(255)
                obj.connect(obj)
            elseif byte_tuple{1} == uint8(254)
                obj.close(obj)
            elseif (byte_tuple{1} < uint8(254)) && (~obj.connected)
                reply = {-1.0,uint8(0),uint8(0),uint8(1)};
                return
            end
            % Sends a command and waits for a response
            obj.sendMessage(byte_tuple);

            waitfor(obj, 'buffer')
            % Parse the reply into its components
            reply = cell(4,1);
            reply{1} = obj.buffer.datetime;
            reply{2} = obj.buffer.message_type;
            reply{3} = obj.buffer.response_tuple(1);
            reply{4} = obj.buffer.response_tuple(2);
            return
        end % sendCommand

        function setupSocket(obj)
            % Set up for reading messages of 11 bytes (replies from the
            % server)
            configureCallback(obj.hSocket,"byte",11,@obj.readDataFcn);
        end % setupSocket

        function readDataFcn(obj, src, ~)
            msg = read(src,11,"uint8");
            obj.buffer = struct('datetime', typecast(msg(1:8),'double'), ...
                                'message_type', msg(9), ...
                                'response_tuple', msg(10:11));

        end % readDataFcn

    end % methods

end % TCPclient
