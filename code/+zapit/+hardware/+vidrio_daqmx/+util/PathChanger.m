classdef PathChanger < handle
    properties (SetAccess = private)
        originalPath
        originalPathWasOnSearchPath
    end
    
    methods
        function obj = PathChanger(newDirectory)
            % adds current directory to path, then changes to new directory
            % on delete, changes back to original directory and restores
            % path to original state
            
            assert(exist(newDirectory,'dir')==7,'Folder ''%s'' not found on disk.',newDirectory);
            
            obj.originalPath = pwd();
            obj.originalPathWasOnSearchPath = zapit.hardware.vidrio_daqmx.idioms.isOnPath(obj.originalPath);
            
            s = warning('off','MATLAB:mpath:privateDirectoriesNotAllowedOnPath');
            addpath(obj.originalPath);
            warning(s);
            
            cd(newDirectory);
            cd(newDirectory); % workaround for weired bug in Matlab 2015b: one single cd does not work
        end
        
        function delete(obj)
            cd(obj.originalPath);
            cd(obj.originalPath); % workaround for weired bug in Matlab 2015b: one single cd does not work
            
            if ~obj.originalPathWasOnSearchPath
                s = warning('off','MATLAB:rmpath:DirNotFound');
                rmpath(obj.originalPath);
                warning(s);
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
