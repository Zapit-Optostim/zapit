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
            % Set up for reading messages of 4 bytes
            configureCallback(obj.hSocket,"byte",4,@obj.readDataFcn);
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

            msg = read(src,4,"uint8");
            obj.buffer = struct('command', msg(1), ...
                                'ArgKeys', msg(2), ...
                                'ArgVals', msg(3), ...
                                'NumSamples', msg(4));

        end % readDataFcn

    end % methods

end % tcpip
