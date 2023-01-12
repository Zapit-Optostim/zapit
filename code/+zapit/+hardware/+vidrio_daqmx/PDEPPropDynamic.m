classdef PDEPPropDynamic < zapit.hardware.vidrio_daqmx.PDEPProp & dynamicprops
    % Abstract mixin class that adds support for pseudo-dependent (pdep)
    % properties (including dynamically-added pdep properties)
    
    methods (Abstract, Access=protected)
        % PDEPPropDynamic calls this method to determine whether a property
        % may be dynamically added to an object. All derived classes must
        % implement this method.
        %
        % propname is a string containing the name of the property to be
        % added. Typically this method is case sensitive with respect
        % to propname.
        %
        % Return possibilities:
        % * tf = true, didyoumean, allProps = []. propname is okay to add.
        % * tf = false, didyoumean = string, allProps = []. propname is not okay, but
        %   didyoumean is okay and is a suggested alternative.
        % * tf = false, didyoumean = [], allProps = cellString. propname is not okay to add, and there are no suggested alternatives, but cellString lists allowable properties for class.
        [tf didyoumean allProps] = pdepIsPropAddable(obj,propname);
    end
    
    %TMW: Would be able to avoid get/set methods if there were
    %get.(unknown) and set.(unknown) property access methods for dynamic
    %properties (or an event)   
    methods        
        function outVal = get(obj,varargin)
            
            %Handle case of array of objects
            if numel(obj) > 1
                %TODO outVal = arrayfun(@(x)get(x,varargin),obj); %TODO: Does this work in more recent Matlab releases? arrayfun didn't used to support object arrays
                for i=1:numel(obj)
                    outVal(i) = get(obj(i),varargin{:});
                end
                return;
            end
            
            if length(varargin) < 1 || ~ischar(varargin{1}) 
                %TODO Array first argument, or Cell array second argument not supported (at this time)
                outVal = get@hgsetget(obj,varargin{:});
            else
                propname = varargin{1};
                if ~isempty(findprop(obj,propname))
                    outVal = get@hgsetget(obj,varargin{:});
                else
                    [tf didyoumean allProps] = obj.pdepIsPropAddable(propname);
                    if tf
                        obj.addPDepProperty(propname);
                        outVal = get@hgsetget(obj,propname);
                    else
                        if ~isempty(didyoumean)
                            error('PDEPPropDynamic:PropertySuggestion',...
                                  'Did you mean to access property ''%s''?',didyoumean);
                        elseif ~isempty(allProps) && iscellstr(allProps)
                            error('PDEPPropDynamic:PropertyList',...
                                'Property not found. <a href ="matlab: fprintf(''%s\\n'')">Show list of allowed properties</a>',strjoin(allProps,'\\n'));
                        else
                            outVal = get@hgsetget(obj,propname); % will probably error
                        end
                    end
                end
            end
        end
        
        function set(obj,propName,setVal,varargin)            
            %Handle case of multiple property sets %TODO: Verify this can't be done via deferring to superclass set method (which does handle multiple property sets correctly)
            if ~isempty(varargin) && ~mod(length(varargin),2)
                set(obj,propName,setVal);
                for i=1:(length(varargin)/2)
                    set(obj,varargin{2*i-1},varargin{2*i});
                end
            end
            
            %Handle case of array of objects
            if numel(obj) > 1
                %arrayfun(@(x)set(x,propName,setVal),obj); %TODO: Double check this doesn't work
                for i=1:numel(obj)
                    set(obj(i),propName,setVal);
                end
                return;
            end
            
            if ~isempty(findprop(obj,propName))
                set@hgsetget(obj,propName,setVal);
            else
                [tf didyoumean allProps] = obj.pdepIsPropAddable(propName);
                if tf
                    obj.addPDepProperty(propName);
                    set@hgsetget(obj,propName,setVal);
                else
                    if ~isempty(didyoumean)
                        error('PDEPPropDynamic:PropertySuggestion',...
                              'Did you mean to access property ''%s''?',didyoumean);
                    elseif ~isempty(allProps) && iscellstr(allProps)
                        error('PDEPPropDynamic:PropertyList',...
                                'Property not found. <a href ="matlab: fprintf(''%s\\n'')">Show list of allowed properties</a>',strjoin(allProps,'\\n'));
                    else
                        set@hgsetget(obj,propName,setVal);
                    end
                end
            end
        end
    end
    
    methods (Access=private)
        function addPDepProperty(obj,propname)
            mp = obj.addprop(propname);
            mp.GetObservable = true;
            mp.SetObservable = true;
            addlistener(obj, propname, 'PreGet', @(src,evnt)pdepPropHandleGetHidden(obj,src,evnt));
            addlistener(obj, propname, 'PostSet', @(src,evnt)pdepPropHandleSetHidden(obj,src,evnt));
            addlistener(obj, propname, 'PreSet', @(src,evnt)pdepPropHandlePreSetHidden(obj,src,evnt));
        end
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
