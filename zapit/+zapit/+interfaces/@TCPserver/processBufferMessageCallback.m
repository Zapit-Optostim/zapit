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


    % If nothing modifies the response output variable, the "error"
    % state of -1 is returned. 
    response = '-1';

    verbose = false;

    if verbose
        fprintf('In processBufferMessageCallback\n')
    end

    if isempty(obj.parent)
        write(obj.hSocket, sprintf('%s\n',response), "string")
        return
    end

    commandIn = obj.buffer.message;

    % If the command is empty, return
    % First we handle commands that have input args
    if startsWith(commandIn, 'sendsamples')
        if verbose
            disp('Starting routin to call zapit.pointer.sendSamples')
        end
        % Handle send sendSamples
        sendSamplesArgs = strsplit(char(commandIn),' ');
        
        if length(sendSamplesArgs)>2
            % Convert values from strings if needed
            sendSamplesArgs(1) = [];
            for ii = 1:length(sendSamplesArgs)
                if strcmp(sendSamplesArgs{ii},'false')
                    sendSamplesArgs{ii} = false;
                elseif strcmp(sendSamplesArgs{ii},'true')
                    sendSamplesArgs{ii} = true;
                elseif ~isempty(str2num(sendSamplesArgs{ii}))
                    sendSamplesArgs{ii} = str2num(sendSamplesArgs{ii});
                end
            end

            if verbose
                disp('zapit.pointer.sendSamples called with input arguments')
            end
            response = obj.parent.sendSamples(sendSamplesArgs{:});
        else
            response = obj.parent.sendSamples;
            if verbose
                disp('zapit.pointer.sendSamples called with no input arguments')
            end
        end
        response = num2str(response);

        if verbose
            disp('Finished calling sendsamples')
        end
    else

        % Now handle other commands with no input args
        switch commandIn

        % Queries
        case {'stimConfLoaded?', 'scl?'}
            % Is a stimulus config loaded?
            if isempty(obj.parent.stimConfig)
                response = '0';
            else
                response = '1';
            end

        case {'numConditions?', 'ncs?'}
            if isempty(obj.parent.stimConfig)
                response = '-1';
            else
                response = num2str(obj.parent.stimConfig.numConditions);
            end

        case {'returnState?', 'res?'}
            response = obj.parent.state;

        % Commands
        case {'stopOptoStim', 'sos'}
            if verbose
                disp('Stopping stim')
            end
            obj.parent.stopOptoStim
            response = '1'; % Placeholder

            
        end % switch

    end % if

        

    % Reply to the client
    write(obj.hSocket, sprintf('%s\n',response), "string");

end % processBufferMessageCallback
