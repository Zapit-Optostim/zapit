classdef TCPserver < zapit.interfaces.tcpip
    % zapit.interfaces.TCPserver
    %
    % This class handles TCP/IP comms. If the tcpServer.enable setting is
    % set to "true" then a server is set up and attached to Zapit using the
    % port and IP address defined in the settings file. 
    % 
    %  
    properties (Hidden)
        parent % instance of zaptit.pointer to which we attached
        listeners  % Structure that holds listeners so they can be easily cleaned up in the destructor

    end % properties


    methods

        function obj = TCPserver(varargin)
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

             %  ;%localhost';

            obj.hSocket = tcpserver(obj.ip, obj.port);
            obj.setupSocket;

            fprintf('Set up TCP server on %s port %d\n', obj.ip, obj.port)

            obj.listeners.bufferUpdated = addlistener(obj, 'buffer', 'PostSet', ...
                @obj.processBufferMessageCallback);

        end % Constructor


        function delete(obj)
            flush(obj.hSocket)
            clear obj.hSocket
            delete(obj.hSocket)
        end % Destructor

    end % methods

end  % TCPserver
