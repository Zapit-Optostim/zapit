function success = openPythonBridge
    % Start the MATLAB engine to link to Python return success as a bool
    %
    % function rotMat = zapit.utils.openPythonBridge
    %
    % Purpose
    % Share the MATLAB engine with Python in a session named 'zapit'.
    % The initialization of the share will fail if another MATLAB 
    % instance is already shared with this name. Return false in this
    % case. Also returns false if called on a non-Windows system.
    %
    % Inputs
    % none
    %
    % Outputs
    % success - true if we opened the bridge. False if we failed.
    %
    %
    % Rob Campbell - SWC 2023

    if ~ispc
        success = false;
        return
    end

    % No need to connect if we're already connected with the right name
    if matlab.engine.isEngineShared
        if matlab.engine.engineName == "zapit"
            success = true;
            return
        else
            fprintf('\n\n** It seems another MATLAB instance is already bridged to Python. **\n')
            fprintf('** Either use that MATLAB instance or close all MATLAB windows and restart Zapit.\n\n')
            success = false;
            return
        end
    end


    % Attempt to open connection to Python 
    try
        matlab.engine.shareEngine('zapit')
        success = true;
    catch ME
        fprintf('\n\nFailed to share MATLAB engine with session name "zapit"\n')
        fprintf('%s\n%s\n', ME.identifier, ME.message)
        success = false;
    end

end % openPythonBridge
