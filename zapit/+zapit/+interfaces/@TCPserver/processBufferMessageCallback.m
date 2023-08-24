function response = processBufferMessageCallback(obj,~,~)
    % Process TCP/IP message coming into the buffer from the client
    %
    % function response = zapit.interfaces.TCPserver.processBufferMessageCallback()
    %
    % Purpose
    % Callback function that handles the TCP messaging system for zapit.
    % For more information see doc text at https://github.com/Zapit-Optostim/zapit-tcp-bridge
    %
    % Inputs
    % none
    %
    % Outputs
    % response - a 15 byte response message (see link above).
    %
    %
    % Rob Campbell, Peter Vincent - SWC 2023


    % This dictionary defines a lookup table for optional parameter value names for
    % zapit.pointer.sendSamples
    sendSampBools = containers.Map([2,3,4,5],["laserOn","hardwareTriggered","logging","verbose"]);
    bitLocs = keys(sendSampBools);

    % Define the default response bytes. If nothing modifies the response output variable,
    % the "error" state of 255 in each byte is returned.
    response = uint8(repmat(255,1,6));


    verbose = false;

    if verbose
        fprintf('In processBufferMessageCallback\n')
    end


    % Get the current time for the datestamp
    current_date = datetime('now');
    date_float = datenum(current_date);

    % Return error bytes if the class is not connected to a zapit.pointer
    if isempty(obj.parent)
        write(obj.hSocket, [typecast(date_float,"uint8"), uint8(255), response], "uint8");
        return
    end


    % The command byte. This indicates what the client requested
    com_byte = obj.buffer.command;


    % First we handle commands that have input args
    try


    % Command "1" is sendSamples. Handle this first.
    if com_byte == 1

        % Get bits associated with parameter/value pairs of sendSamples
        arg_keys  = bitget(obj.buffer.ArgKeys,1:8,"uint8");
        arg_vals  = bitget(obj.buffer.ArgVals,1:8,"uint8");
        condNum   = obj.buffer.ConditionNumber;

        % Process the stimulus duration
        if (obj.buffer.stimDurationWholeSeconds + obj.buffer.stimDurationFractionSeconds)== 0
            stimDuration = -1; % Stimulus will continue until stopOptoStim
        else
            stimDuration = obj.buffer.stimDurationWholeSeconds;
            stimDuration = stimDuration + (obj.buffer.stimDurationFractionSeconds/256);
        end

        if verbose
            disp('Starting routine to call zapit.pointer.sendSamples')
        end

        if sum(arg_keys) > 0
            % If true, the command contains parameter value pairs for sendSamples.
            % Build the arguments then call sendSamples with these.
            sendSamplesArgs = {};

            for ii = 1:length(bitLocs)
                bit_loc = bitLocs{ii};
                if logical(arg_keys(bit_loc))
                    sendSamplesArgs{end + 1} = sendSampBools(bit_loc);
                    sendSamplesArgs{end + 1} = logical(arg_vals(bit_loc));
                end
            end

            if logical(arg_keys(1))
                sendSamplesArgs{end + 1} = "conditionNum";
                sendSamplesArgs{end + 1} = condNum;
            end

            if stimDuration > -1
                sendSamplesArgs{end + 1} = "stimDurationSeconds";
                sendSamplesArgs{end + 1} = stimDuration;
            end

            if verbose
                disp('zapit.pointer.sendSamples called with input arguments')
            end

            [varCondNum, varLaserOn] = obj.parent.sendSamples(sendSamplesArgs{:});
        else
            % If false, the command contains no parameter value pairs for sendSamples
            % so we call it without any input arguments.
            [varCondNum, varLaserOn] = obj.parent.sendSamples;
            if verbose
                disp('zapit.pointer.sendSamples called with no input arguments')
            end
        end

        if varCondNum>0 && varLaserOn>=0
            % If -1 is being returned for either, then sendSamples failed
            response(1) = varCondNum;
            response(2) = varLaserOn;
        end

        if verbose
            disp('Finished calling sendSamples')
        end
    else

        % Now handle other commands with no input args
        switch com_byte
            % Queries
            case 2
                % Is a stimulus config loaded?
                if isempty(obj.parent.stimConfig)
                    response(1) = 0;
                else
                    response(1) = 1;
                end

            case 4
                % How many conditions?
                if isempty(obj.parent.stimConfig)
                    response(1) = 0;
                else
                    response(1) = obj.parent.stimConfig.numConditions;
                end

            case 3
                % State of zapit
                cur_state = obj.parent.state;
                switch cur_state
                    case "idle"
                        response(1) = 0;
                    case "active"
                        response(1) = 1;
                    case "rampdown"
                        response(1) = 2;
                end

            case 0
                % stopOptoStim
                if verbose
                    disp('Stopping stim')
                end
                obj.parent.stopOptoStim;
                response(1) = 1; % Placeholder
        end % switch

    end
    catch ME
        disp(ME.message)
        date_float = -1.0;
    end


    % Generate response bytes
    response_array = [typecast(date_float,'uint8') com_byte response];
    % Reply to the client
    write(obj.hSocket, response_array, "uint8");


end % processBufferMessageCallback
