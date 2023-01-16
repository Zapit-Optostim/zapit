classdef DigitalChan < zapit.hardware.vidrio_daqmx.Channel
    %DIGITALCHAN  An abstract DAQmx Digital Channel class    
   
    
    properties  (SetAccess=protected)
        channelType=''; %One of {'port','line'}, indicating if Channel is port-based or line-based.
    end
    
    properties (Constant, Hidden)
        physChanIDsArgValidator = @ischar; %PhysChanIDs arg must be a string (or a cell array of such, for multi-device case)
    end
        
   %% CONSTRUCTOR/DESTRUCTOR
    methods (Access=protected)       
        function obj = DigitalChan(varargin)
            % obj = DigitalChan(createFunc,task,deviceName,physChanIDs,chanNames,varargin)            
            obj = obj@zapit.hardware.vidrio_daqmx.Channel(varargin{:});
        end
    end
    
   
    %% ABSTRACT METHOD IMPLEMENTATIONS (zapit.hardware.vidrio_daqmx.Channel)
    methods (Hidden)
        %TMW: This function is a regular method, rather than being static (despite having no object-dependence). This allows caller in abstract superclass to invoke it  by the correct subclass version.
        %%% This would not need to be a regular method if there were a simpler way to invoke static methods, without resorting to completely qualified names.
        function [physChanNameArray,chanNameArray] = createChanIDArrays(obj, numChans, deviceName, physChanIDs,chanNames)
            %NOTE: For DOChan objects, physChanIDs 
            
            [physChanNameArray,chanNameArray] = deal(cell(1,numChans));
            
            if numChans == 1
                physChanIDs = {physChanIDs};
            end
            
            for i=1:numChans     
                portOrLineID = regexpi(physChanIDs{i},'\s*/?(.*)','tokens','once'); %Removes leading slash, if any  
                physChanNameArray{i} = [deviceName '/' portOrLineID{1}];           
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

            %Determine if channel(s) added are port- or line-based
            for i=1:length(obj)
               if ~isempty(strfind(obj.chanNamePhysical,'line'))
                   obj(i).channelType = 'line';
               else
                   obj(i).channelType = 'port';
               end
            end
            
            %Ensure that all channel(s) added, now and previously to this Task, are of same type
            taskChannelTypes = unique({obj(1).task.channels.channelType});
            
            if length(taskChannelTypes) > 1
                delete(obj(1).task);
                zapit.hardware.vidrio_daqmx.idioms.dispError(['The Matlab DAQmx package does not, at this time, allow Digital I/O Tasks\n' ...
                    'to contain a mixture of port- and line-based Channels.\n' ...
                    'Task has been deleted!\n']);                
                return;
            end  
            
            %Store to Task whether Channel(s) of this Task are line-based 
            obj(1).task.isLineBasedDigital = strcmpi(taskChannelTypes,'line');
            
            
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
