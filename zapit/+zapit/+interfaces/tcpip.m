classdef (Abstract) tcpip < handle
    % superclass inherited by both TCPserver and TCPclient
    %
    % Messages are written to the buffer property. 
    properties
        hSocket % The server or client object will reside here
        port = 1488
        ip = 'localhost'
    end

    properties (SetObservable)
        buffer
    end % properties


    methods

        function obj = tcpip(varargin)

        end % Constructor


        function delete(obj)
        end % Destructor

        function setupSocket(obj)
            % Set up for reading strings
            configureCallback(obj.hSocket,"terminator",@obj.readDataFcn);
            configureTerminator(obj.hSocket,"LF"); 
        end % setupSocket

        function readDataFcn(obj, src, ~)
            % Must modify buffer just once as there is a listener on this property
            % TODO: consider a more elaborate message system where we supply a timestamp
            % and also the message type. e.g. we could send a string like this to stop 
            % the optostim:
            % '20230120 19:23:01;char;stopOptoStim'
            % or the response from the server indicating the number of stimuli could be 
            % the string:
            % '20230120 19:23:01;numeric;5'

            msg = readline(src);
            obj.buffer = struct('message', msg, 'messageClass', 'char');

        end % readDataFcn

    end % methods

end % tcpip
