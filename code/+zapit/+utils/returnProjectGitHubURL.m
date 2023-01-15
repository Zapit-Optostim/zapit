function gURL = returnProjectGitHubURL
    % Return the URL of the project on GitHub
    %
    % gURL = zapit.utils.returnProjectGitHubURL
    %
    % Purpose
    % Return the project's GitHub URL as a string without leading "https://" or "www"
    %
    % Inputs
    % none
    %
    % Outputs
    % gURL - String containing the web address URL of the project. 
    %
    % Rob Campbell - SWC 2023
    %
    % See also zapit.utils.getGitHubReleaseHistory

    gURL = 'github.com/BaselLaserMouse/zapit';

end %returnProjectGitHubURL