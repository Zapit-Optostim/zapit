function hZP = getObject(quiet)
% Returns the Zapit object from the base workspace regardless of its name
%
% hZP = zapit.utils.getObject(quiet)
%
% Purpose
% Used by methods to import Zapit without requiring it to be passed as an input argument.
%
% Inputs
% quiet - false by default. If true, print no messages to screen. 
%
% Outputs
% hZP - the Zapit object. Returns empty if an instance could not be found. 
%
%
% Rob Campbell - SWC 2022

    if nargin<1
        quiet=false;
    end

    W=evalin('base','whos');

    varClasses = {W.class};

    ind=strmatch('zapit.pointer',varClasses);

    if isempty(ind)
        if ~quiet
            fprintf('No Zapit object in base workspace\n')
        end
        hZP=[];
        return
    end

    if length(ind)>1
        if ~quiet
            fprintf('More than one Zapit object in base workspace\n')
        end
        hZP=[];
        return
    end


    hZP=evalin('base',W(ind).name);

end % getObject
