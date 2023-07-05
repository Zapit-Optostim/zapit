function response = processBufferMessageCallback(obj,~,~)
    % Process message coming into the buffer
    %
    % function response = zapit.interfaces.TCPserver.processBufferMessageCallback()
    %
    % Purpose
    % Callback function that handles the TCP messaging system for zapit. 
    %
    % Commands
    % IN: 'stimConfLoaded?', 'scl?' ; OUT: 0 or 1
    % IN: 'numConditions?', 'ncs?' ; OUT: [int] num conditions. -1 if fail
    % IN: 'returnState?', 'res?' ; OUT: string defining the state
    % DOC TODO: sendsamples, stopoptostim
    %
    % Return false if not connected to zapit.pointer
    %
    % Rob Campbell - SWC 2023


    sendSampBools = dictionary([2,3,4,5],["laserOn","hardwareTriggered","logging","verbose"]);
    bitLocs = keys(sendSampBools);
    % If nothing modifies the response output variable, the "error"
    % state of 255 in each byte is returned. 
    response = [uint8(255),uint8(255)];


    verbose = false;

    if verbose
        fprintf('In processBufferMessageCallback\n')
    end

    if isempty(obj.parent)
        current_date = datetime('now');
        date_float = datenum(current_date);
        date_bytes = typecast(date_float,"uint8");

        write(obj.hSocket, [date_bytes uint8(255) response], "uint8")
        return
    end
    current_date = datetime('now');
    date_float = datenum(current_date);
    commandIn = obj.buffer.command;
    com_byte = commandIn;
     % If the command is empty, return
    % First we handle commands that have input args
    try
    if commandIn == 1  
        
        arg_keys  = bitget(obj.buffer.ArgKeys,1:8,"uint8");
        arg_vals  = bitget(obj.buffer.ArgVals,1:8,"uint8");
        sampNum   = obj.buffer.NumSamples;
        if verbose
            disp('Starting routin to call zapit.pointer.sendSamples')
        end
        % Handle send sendSamples

        
        if sum(arg_keys) > 0
            sendSamplesArgs = {};
                for ii = 1:length(bitLocs)
                    bit_loc = bitLocs(ii);
                    if logical(arg_keys(bit_loc))
                        sendSamplesArgs{end + 1} = sendSampBools(bit_loc);
                        sendSamplesArgs{end + 1} = logical(arg_vals(bit_loc));
                    end
                end
                if logical(arg_keys(1))
                    sendSamplesArgs{end + 1} = "conditionNum";
                    sendSamplesArgs{end + 1} = sampNum;
                end
            if verbose
                disp('zapit.pointer.sendSamples called with input arguments')
            end
            [varCondNum, varLaserOn] = obj.parent.sendSamples(sendSamplesArgs{:});
        else
            [varCondNum, varLaserOn] = obj.parent.sendSamples;
            if verbose
                disp('zapit.pointer.sendSamples called with no input arguments')
            end
        end
        response(1) = varCondNum;
        response(2) = varLaserOn;
        if verbose
            disp('Finished calling sendsamples')
        end
    else
        % Now handle other commands with no input args
        switch commandIn
            % Queries
            case {2} 
                % Is a stimulus config loaded?
                if isempty(obj.parent.stimConfig)
                    response(1) = 0;
                else
                    response(1) = 1;
                end
    
            case {4}
                % How many conditions?
                if isempty(obj.parent.stimConfig)
                    response(1) = 0;
                else
                    response(1) = obj.parent.stimConfig.numConditions;
                end
    
            case {3}
                % State of zapit
                cur_state = obj.parent.state;
                switch cur_state
                    case {"idle"}
                        response(1) = 0;
                    case {"active"}
                        response(1) = 1;
                end
                
    
            % Commands
            case {0}
                % stopOptoStim
                if verbose
                    disp('Stopping stim')
                end
                obj.parent.stopOptoStim
                response(1) = 1; % Placeholder 
        end % switch
    
    end
    catch
        date_float = -1.0;
    end
        
    
    % Generate response bytes
    response_array = [typecast(date_float,'uint8') com_byte response];
    % Reply to the client
    write(obj.hSocket, response_array, "uint8");

    
end % processBufferMessageCallback
