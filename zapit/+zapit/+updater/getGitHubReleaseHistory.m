function releases = getGitHubReleaseHistory
    % Return a structure containing the release history on GitHub
    %
    % gURL = zapit.updater.getGitHubReleaseHistory
    %
    % Purpose
    % Return the project's GitHub release history. This can be used to determine 
    % if the installed version is up to date. This function uses GitHub's REST
    % API. Returned releases are sorted according to when the tags were made 
    % (or the version number, I don't know which). They are not sorted according
    % to when the release itself was made. In other words, they are sorte according
    % to how they appear on the repo's releases page. 
    %
    % Inputs
    % none
    %
    % Outputs
    % releases - structure of GitHub releases
    %
    % Rob Campbell - SWC 2023

    % Build the URL
    API_URL = ['https://api.', zapit.updater.returnProjectGitHubURL, '/releases'];
    API_URL = regexprep(API_URL,'github\.com', 'github.com/repos');

    % Read RESTful content nicely as a structure
    try
        releases = webread(API_URL);
    catch
        % There is a cap on how many requests we can make or the connection might fail
        releases = [];
    end

end % getGitHubReleaseHistory
