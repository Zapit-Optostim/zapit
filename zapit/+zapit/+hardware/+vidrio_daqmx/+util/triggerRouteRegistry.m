classdef triggerRouteRegistry < handle
    % Helper class to manage DAQmx trigger routes
    % This class is used to track routes that are connected via an objects
    % lifetime - on deletion of this object all registered routes are
    % disconnected
    properties
        verbose = false;
    end
    
    properties (SetAccess = private)
        routes = cell.empty(0,2);
        enable = true;
    end
    
    properties (Access = private)
        daqSys;
    end
    
    %% Lifecycle
    methods
        function obj = triggerRouteRegistry()
            obj.daqSys = zapit.hardware.vidrio_daqmx.System();
        end
        
        function delete(obj)
            if zapit.hardware.vidrio_daqmx.idioms.isValidObj(obj.daqSys)
                obj.clearRoutes();
            end
        end
    end
    
    %% User methods
    methods
        function connectTerms(obj,src,dest)
            if ~strcmpi(src,dest)
                if obj.enable
                    obj.daqSys.connectTerms(src,dest);
                end
                obj.addRoute(src,dest);
            end
        end
        
        function disconnectTerms(obj,src,dest)
            if ~strcmpi(src,dest)
                if obj.enable
                    obj.physicallyDisconnectTerms(src,dest);
                end
                obj.removeRoute(src,dest);
            end
        end
        
        function reinitRoutes(obj)
            if ~obj.enable
                obj.enable = true;
                
                routes_ = obj.routes;
                for idx = 1:size(routes_,1)
                    try
                        src = routes_{idx,1};
                        dest = routes_{idx,2};
                        obj.connectTerms(src,dest);
                    catch ME
                        most.ErrorHandler.logAndReportError(ME);
                    end
                end
            end
        end
        
        function deinitRoutes(obj)
            if obj.enable
                routes_ = obj.routes;
                for idx = 1:size(routes_,1)
                    try
                        src = routes_{idx,1};
                        dest = routes_{idx,2};
                        obj.physicallyDisconnectTerms(src,dest);
                    catch ME
                        most.ErrorHandler.logAndReportError(ME);
                    end
                end
                obj.enable = false;
            end
        end
        
        function clearRoutes(obj)
            for idx = 1:size(obj.routes,1)
                src = obj.routes{idx,1};
                dest = obj.routes{idx,2};
                if obj.enable
                    obj.physicallyDisconnectTerms(src,dest);
                end
            end
            
            obj.routes = cell.empty(0,2);
        end
    end
    
    %% Private methods
    methods (Access = private)        
        function idx = findRouteIdx(obj,src,dest)
            if isempty(obj.routes)
                idx = 0;
                return
            end
            
            src = lower(src);
            dest = lower(dest);
            routes_ = lower(obj.routes);            
            
            [~,srcidxs] = ismember(src,routes_(:,1));
            if srcidxs > 0
                [~,destidxs] = ismember(dest,routes_(srcidxs,2));
            end
            
            if srcidxs < 1 || destidxs < 1
                idx = 0;
            else
                idx = srcidxs(destidxs);
            end
        end
        
        function addRoute(obj,src,dest)
            if ~strcmpi(src,dest)
                if obj.findRouteIdx(src,dest)==0
                    obj.routes(end+1,:) =  {src,dest};
                end
            end
        end
        
        function removeRoute(obj,src,dest)
            if ~strcmpi(src,dest)
                idx = obj.findRouteIdx(src,dest);
                if idx~=0
                    obj.routes(idx,:) =  [];
                end
            end
        end
        
        function physicallyConnectTerms(obj,src,dest)
            if ~strcmpi(src,dest)
                obj.daqSys.connectTerms(src,dest);
                obj.fprintf('Connecting terminals: %s -> %s\n',src,dest);
            end
        end
        
        function physicallyDisconnectTerms(obj,src,dest)
            if ~strcmpi(src,dest)
                obj.daqSys.disconnectTerms(src,dest);
                obj.fprintf('Disonnecting terminals: %s -> %s',src,dest);
                
                if strfind(dest,'PFI')
                    obj.daqSys.tristateOutputTerm(dest);
                    obj.fprintf(' and tristating terminal %s',dest);
                end
                obj.fprintf('\n');
            end
        end
        
        function fprintf(obj,varargin)
            if obj.verbose
                fprintf(varargin{:});
            end
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
