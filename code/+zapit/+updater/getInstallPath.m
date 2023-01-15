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
    installPath = regexprep(installPath,['code','\',filesep,'start_zapit.m'],'');
    
end % getInstallPath
