function getIPaddress
    % Get the IP address of the local machine
    %
    % function zapit.interfaces.getIPaddress
    %
    % Purpose
    % Return IP address(es) to help user connect to TCP/IP server from a different PC on
    % the same network. It is common for PCs to have multiple IP addresses. e.g. A Windows
    % PC running the Linux sub-system will have an IP address for this. All IP addresses
    % are return and named.
    % NOTE: currently works only on Windows
    %
    % Inputs
    % none
    %
    % Outputs
    % none - details are printed to screen.
    %
    %
    % Rob Campbell - SWC 2023

    if isunix
        fprintf('Currently works only on Windows')
    end

    ipaddresses = [];
    if ispc
        % Windows
        [~,out] = system('ipconfig');
        tok=regexp(out,'(Ethernet adapter.*?Default Gateway )','tokens');
        if ~isempty(tok)
            ipaddresses = getIPwin(tok);
        end


    if isempty(ipaddresses)
        fprintf('IP address not found\n')
    else
        for ii=1:length(ipaddresses)
            fprintf('%d. %s %s\n', ii, ipaddresses(ii).adapterName, ipaddresses(ii).IP)
        end

    end

end % getIPaddress



function addresses = getIPwin(tokens)
    % Get IP addresses from the tokens extracted from a call to "ipconfig"

    for ii=1:length(tokens)
        tok = tokens{ii};

        % The name of the ethernet adapter
        tMatch = regexp(tok,'Ethernet.*?:','match');
        addresses(ii).adapterName = tMatch{1}{1};

        % The IP address of this adapter
        tMatch = regexp(tok,'Link-local IP.*?: (\d+\.\d+\.\d+\.\d+)','tokens');
        addresses(ii).IP = tMatch{1}{1}{1};
    end
