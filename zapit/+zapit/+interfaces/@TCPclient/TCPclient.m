classdef TCPclient < zapit.interfaces.tcpip

    properties

    end % properties


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
            obj.buffer = []; % Wipe the buffer because we will later wait for it to change
            obj.sendMessage(commandString);

            waitfor(obj, 'buffer')
            reply_bytes = obj.buffer.message;
            % Parse the reply into its components
            reply = cell(4,1);
            reply{1} = typecast(reply_bytes(1:8),'double');
            reply{2} = reply_bytes{9};
            reply{3} = reply_bytes{10};
            reply{4} = reply_bytes{11};
            return
        end % sendCommand

    end % methods

end % TCPclient
