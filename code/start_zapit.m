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
    % 'simulated'  -  [false by default] If true does not connect to hardware but runs in 
    %             simulated mode.
    % 'useExisting'  -  [false by default] If true, an exsiting instance of hZP is used.
    % 'startGUI'  -  [true by default]
    %
    %
    % Rob Campbell - SWC 2022

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    %Parse optional arguments
    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('simulated', false, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('useExisting', false, @(x) islogical(x) || x==0 || x==1);
    params.addParameter('startGUI', true, @(x) islogical(x) || x==0 || x==1);

    params.parse(varargin{:});

    useExisting=params.Results.useExisting;
    simulated=params.Results.simulated;
    startGUI=params.Results.startGUI;

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    % Build optional arguments to feed to Zapit during its construction
    ZPargs={'simulated',simulated};


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
        else
            fprintf('hZP already exists. No building.\n')
            return
        end

    end %if isempty(hZP)


    if hZP.buildFailed
        fprintf('%s failed to create an instance of zapit pointer. Quitting.\n', mfilename)
        hZP.delete
        evalin('base','clear hZP')
        return
    end %if hZP.buildFailed


    %By this point we should have a functioning hZP object, which is the model in our model/view system

    % Now we make the view
    if startGUI
        fprintf('Building GUI\n')
        hZPview = zapit.gui.main.controller(hZP);
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

    
