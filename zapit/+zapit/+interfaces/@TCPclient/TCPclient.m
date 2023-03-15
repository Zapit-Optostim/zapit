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

            % Build the client
            obj.hSocket = tcpclient(obj.ip, obj.port);
            obj.setupSocket; 
        end % Constructor


        function delete(obj)
            delete(obj.hSocket)
        end % Destructor


        function sendMessage(obj, messageString)
            % Send a message to the server. Adds a new line. 
            % This should be treated as a lower-level function
            write(obj.hSocket, sprintf('%s\n',messageString), 'char');
        end % sendMessage


        function response = sendCommand(obj,commandString)
            % Sends a command and waits for a response

            obj.buffer = []; % Wipe the buffer because we will later wait for it to change
            obj.sendMessage(commandString);

            waitfor(obj, 'buffer')
            response = obj.buffer.message;
        end % sendCommand

    end % methods

end % TCPclient
