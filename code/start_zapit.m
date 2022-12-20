function start_zapit(varargin)
    % Creates a instance of the zapit pointer class and places it in the base workspace as hZP
    %
    % function start_zapit(varargin)
    %
    % Purpose
    % Zapit startup function. Starts software if it is not already started.
    %
    %
    % Optional Input args (param/val pairs
    % 'useExisting' - [false by default] if true, any existing BT object in the 
    %                 base workspace is used to start BakingTray
    % 'startGUI' - [false by default] TODO -- LATER MAKE TRUE
    %
    %
    % Rob Campbell - SWC 2022

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    %Parse optional arguments
    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('useExisting', false, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('startGUI', false, @(x) islogical(x) || x==0 || x==1);
    params.parse(varargin{:});

    useExisting=params.Results.useExisting;
    startGUI=params.Results.startGUI;

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    % Build optional arguments to feed to Zapit during its construction
    ZPargs={};


    %Does a Zapit object exist in the base workspace?
    evalin('base','clear ans') %Because it sometimes makes a copy of BT in ans when it fails
    hZP = zapit.utils.getObject(true);

    if isempty(hZP)
        %If not, we build hZP and place it in the base workspace
        try
            hZP = zapit.pointer(ZPargs{:});

            % Place the object in the base workspace as a variable called "hZP"
            assignin('base','hZP',hZP);
        catch ME
            fprintf('Build of hZP failed\n')
            delete(hZP) % Avoids blocked hardware controllers
            evalin('base','clear ans') % Because it sometimes makes a copy of ZP in ans when it fails
            rethrow(ME)
        end

    else

        %If it does exist, we only re-use it if the user explicitly asked for this and there
        if useExisting
            assignin('base','hZP',hZP);
        elseif ~isSafeToMake_hZP
            %TODO: run delete ourselves?
            return
        end

    end %if isempty(hZP)


    if hZP.buildFailed
        fprintf('%s failed to create an instance of BT. Quitting.\n', mfilename)
        evalin('base','clear hZP')
        return
    end %if hZP.buildFailed


    %By this point we should have a functioning hZP object, which is the model in our model/view system

    % Now we make the view
    if startGUI
        hZPview = zapit.gui.view(hZP);
        assignin('base','hZPview',hZPview);
    end


    fprintf('Zapit has started\n')



%-------------------------------------------------------------------------------------------------------------------------
function safe = isSafeToMake_hZP
    % Return true if it's safe to copy the created BT object to a variable called "hZP" in
    % the base workspace. Return false if not safe because the variable already exists.

    W=evalin('base','whos');

    if strmatch('hZP',{W.name})
        fprintf('Zapit seems to have already started. If this is an error, remove the variable called "hZP" in the base workspace.\n')
        fprintf('Then run "%s" again.\n',mfilename)
        safe=false;
    else
        safe=true;
    end

    