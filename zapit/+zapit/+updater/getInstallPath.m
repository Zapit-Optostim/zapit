function installPath = getInstallPath
    % Get the install path for the Zapit package
    %
    % zapit.updater.getInstallPath
    %
    % Purpose
    % Return the path to the package install. This is used for reporting to the
    % user this information and also for house-keeping tasks related to keeping
    % the install up to date. 
    %
    % Inputs
    % none
    %
    % Outputs
    % installPath - string defining the absolute path to the install


    installPath = which('start_zapit');
    installPath = regexprep(installPath,['zapit','\',filesep,'start_zapit.m'],'');
    
    if ~exist(installPath,'dir')
        fprintf(['Install location expected at %s but not found there\n'...
            'Your Zapit install might be broken'],installPath)
        installPath=[];
    end

end % getInstallPath
