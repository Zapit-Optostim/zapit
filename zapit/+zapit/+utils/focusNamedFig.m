function varargout=focusNamedFig(figTagName)
    % Bring to focus a figure window identfied by its tag property
    %
    % zapit.utils.focusNamedFig(figTagName)
    %
    % Purpose
    % Brings to focus the figure with the tag name 'figTagName'.
    % Creates the figure if it does not exist
    %
    % Inputs
    % figTagName - string defining the tag name to search for.
    %
    % Outputs [optional]
    % hFig - the figure object that was brought into focus.
    %
    %
    % Rob Campbell - SWC 2022

    if nargin<1 || isempty(figTagName)
        fprintf('zapit.utils.%s expects one input argument\n',mfilename)
        return
    end

    if ~ischar(figTagName)
        fprintf('zapit.utils.%s expects figTagName to be a character array\n',mfilename)
        return
    end


    f=findobj('tag',figTagName);

    if isempty(f)
        hFig=figure;
        hFig.Tag=figTagName;
    else
        hFig=f;
    end % if
    
    figure(hFig) %bring to focus
    if nargout>0
        varargout{1}=hFig;
    end % if

end % focusNamedFig
