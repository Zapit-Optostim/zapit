function out = className(className,type)
%className - returns the name / related paths of a class
%
% SYNTAX
%     s = className(className)
%     s = className(className,type)
%     
% ARGUMENTS
%     className: object or string specifying a class
%     type:      <optional> one of {'classNameShort','classPrivatePath','packagePrivatePath','classPath'}
%                   if omitted function defaults to 'classNameShort' 
%
% RETURNS
%     out - a string containing the appropriate class name / path

if nargin < 2 || isempty(type)
    type = 'classNameShort';
end

if isobject(className)
    className = class(className);
end

switch type
    case 'classNameShort'
        classNameParts = textscan(className,'%s','Delimiter','.');
        out = classNameParts{1}{end};
    case 'classPrivatePath'
        out = fullfile(fileparts(which(className)),'private');
    case 'packagePrivatePath'
        mc = meta.class.fromName(className);
        containingpack = mc.ContainingPackage;
        if isempty(containingpack)
            out = [];
        else
            p = fileparts(fileparts(which(className)));
            out = fullfile(p,'private');
        end
    case 'classPath'
        out = fileparts(which(className));
    otherwise
        error('most.util.className: Not a valid option: %s',type);
end
end




% ----------------------------------------------------------------------------
% Copyright (C) 2022 Vidrio Technologies, LLC
% 
% ScanImage (R) 2022 is software to be used under the purchased terms
% Code may be modified, but not redistributed without the permission
% of Vidrio Technologies, LLC
% 
% VIDRIO TECHNOLOGIES, LLC MAKES NO WARRANTIES, EXPRESS OR IMPLIED, WITH
% RESPECT TO THIS PRODUCT, AND EXPRESSLY DISCLAIMS ANY WARRANTY OF
% MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
% IN NO CASE SHALL VIDRIO TECHNOLOGIES, LLC BE LIABLE TO ANYONE FOR ANY
% CONSEQUENTIAL OR INCIDENTAL DAMAGES, EXPRESS OR IMPLIED, OR UPON ANY OTHER
% BASIS OF LIABILITY WHATSOEVER, EVEN IF THE LOSS OR DAMAGE IS CAUSED BY
% VIDRIO TECHNOLOGIES, LLC'S OWN NEGLIGENCE OR FAULT.
% CONSEQUENTLY, VIDRIO TECHNOLOGIES, LLC SHALL HAVE NO LIABILITY FOR ANY
% PERSONAL INJURY, PROPERTY DAMAGE OR OTHER LOSS BASED ON THE USE OF THE
% PRODUCT IN COMBINATION WITH OR INTEGRATED INTO ANY OTHER INSTRUMENT OR
% DEVICE.  HOWEVER, IF VIDRIO TECHNOLOGIES, LLC IS HELD LIABLE, WHETHER
% DIRECTLY OR INDIRECTLY, FOR ANY LOSS OR DAMAGE ARISING, REGARDLESS OF CAUSE
% OR ORIGIN, VIDRIO TECHNOLOGIES, LLC's MAXIMUM LIABILITY SHALL NOT IN ANY
% CASE EXCEED THE PURCHASE PRICE OF THE PRODUCT WHICH SHALL BE THE COMPLETE
% AND EXCLUSIVE REMEDY AGAINST VIDRIO TECHNOLOGIES, LLC.
% ----------------------------------------------------------------------------
