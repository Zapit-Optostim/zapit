function releases = getGitHubReleaseHistory(verbose)
    % Return a structure containing the release history on GitHub
    %
    % gURL = zapit.updater.getGitHubReleaseHistory(verbose)
    %
    % Purpose
    % Return the project's GitHub release history. This can be used to determine 
    % if the installed version is up to date. This function uses GitHub's REST
    % API. Returned releases are sorted according to when the tags were made 
    % (or the version number, I don't know which). They are not sorted according
    % to when the release itself was made. In other words, they are sorte according
    % to how they appear on the repo's releases page. 
    %
    % Inputs (optional)
    % verbose - false by default, if true we print to screen information about 
    %          what the function is doing.
    %
    % Outputs
    % releases - structure of GitHub releases
    %
    %
    % Rob Campbell - SWC 2023

    if nargin<1
        verbose = false;
    end


    % Build the URL
    API_URL = ['https://api.', zapit.updater.returnProjectGitHubURL, '/releases'];
    API_URL = regexprep(API_URL,'github\.com', 'github.com/repos');

    if verbose
        fprintf('Getting release data from %s\n', API_URL)
    end

    % Read RESTful content nicely as a structure
    try
        releases = webread(API_URL);
    catch ME
        if contains(ME.message,'rate limit exceeded')
            fprintf('GitHub reports API rate limit is exceeded. Not returning release history.\n')
        end

        % There is a cap on how many requests we can make or the connection might fail
        releases = [];
    end

end % getGitHubReleaseHistory
