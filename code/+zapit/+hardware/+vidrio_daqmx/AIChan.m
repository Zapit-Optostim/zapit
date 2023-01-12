classdef AIChan < zapit.hardware.vidrio_daqmx.private.AnalogChan
    %AICHAN A DAQmx Analog Input Channel
    
    properties (Constant)
        type = 'AnalogInput';
    end
    
    properties (Constant, Hidden)
        typeCode = 'AI';
    end
    
    %% CONSTRUCTOR/DESTRUCTOR
    methods
        function obj = AIChan(varargin)
            %Constructor required, as this is a concrete subclass of abstract lineage
            obj = obj@zapit.hardware.vidrio_daqmx.private.AnalogChan(varargin{:});
            
        end
    end
    
    %% METHODS
    
    methods (Hidden)
        
        function postCreationListener(obj)
            %Handle input data type
            errorCond = false;
            for i=1:length(obj)
                rawSampSize = obj(i).getQuiet('rawSampSize');
                switch rawSampSize
                    case 8
                        rawSampClass = 'int8';
                    case 16
                        rawSampClass = 'int16';
                    case 32
                        rawSampClass = 'int32';
                    otherwise
                        errMessage = ['Unsupported sample size (' num2str(rawSampSize) '). Task deleted.'];
                        errorCond = true;
                        break;
                end
                if isempty(obj(i).task.rawDataArrayAI)
                    obj(1).task.rawDataArrayAI = feval(rawSampClass,0); %Creates a scalar array of rawSampClass
                elseif ~strcmpi(class(obj(i).task.rawDataArrayAI), rawSampClass);
                    errMessage = ['All ' obj(i).type ' channels in a given Task must have the same raw data type. Task deleted.'];
                    errorCond = true;
                    break;
                end
            end
            
            if errorCond
                delete(obj(1).task); %All created objects presumed (known) to belong to same class
                error(errMessage);
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
