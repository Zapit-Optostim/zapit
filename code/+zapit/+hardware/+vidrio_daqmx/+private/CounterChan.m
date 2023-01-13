classdef CounterChan < zapit.hardware.vidrio_daqmx.Channel
    %DIGITALCHAN  An abstract DAQmx Counter Channel class    
   
    properties (Constant, Hidden)
        physChanIDsArgValidator = @isnumeric; %PhysChanIDs arg must be a string (or a cell array of such, for multi-device case)
    end
        
   %% CONSTRUCTOR/DESTRUCTOR
    methods (Access=protected)
        function obj = CounterChan(varargin)
            % obj = CounterChan(createFunc,task,deviceName,physChanIDs,chanNames,varargin)            
            obj = obj@zapit.hardware.vidrio_daqmx.Channel(varargin{:});
        end
    end
    
   
    %% METHODS
    methods (Hidden)
        %TMW: This function is a regular method, rather than being static (despite having no object-dependence). This allows caller in abstract superclass to invoke it  by the correct subclass version.
        %%% This would not need to be a regular method if there were a simpler way to invoke static methods, without resorting to completely qualified names.
        function [physChanNameArray,chanNameArray] = createChanIDArrays(obj, numChans, deviceName, physChanIDs,chanNames)
            %ToDo: Consider how to better share this code with AnalogChan. Implementations are extremely similar.
            
            [physChanNameArray,chanNameArray] = deal(cell(1,numChans));
            for i=1:numChans     
                if ~isnumeric(physChanIDs)
                    error([class(obj) ':Arg Error'], ['Argument ''' inputname(4) ''' must be a numeric array (or cell array of such, for multi-device case)']);
                else
                    physChanNameArray{i} = [deviceName '/ctr' num2str(physChanIDs(i))];
                end

                if isempty(chanNames)
                    chanNameArray{i} = ''; %Would prefer to give it the physical chan name, but DAQmx won't take any special characters in the given channel name (even as it proceeds to use them in supplying the default itself)
                elseif ischar(chanNames)
                    if numChans > 1
                        chanNameArray{i} = [chanNames num2str(i)];
                    else
                        chanNameArray{i} = chanNames;
                    end
                elseif iscellstr(chanNames) && length(chanNames)==numChans
                    chanNameArray{i} = chanNames{i};
                else
                    error(['Argument ''' inputname(5) ''' must be a string or cell array of strings of length equal to the number of channels.']);
                end
            end
        end
        
        function postCreationListener(obj)
            %Concrete realization of abstract superclass method
            %Do Nothing
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
