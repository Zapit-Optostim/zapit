classdef Device < zapit.hardware.vidrio_daqmx.private.DAQmxClass
    %DEVICE Class encapsulating a DAQmx device
    %
    
    %NOTES
    %   At moment, it is not possible to delete Device objects.
    %   This is because of the peristent memory store containing the DeviceMap. 
    %   Without some reference counting scheme, there is no way to clear the handles stored by that Map anyway.
    
    

    %% ABSTRACT PROPERTY REALIZATION (zapit.hardware.vidrio_daqmx.private.DAQmxClass)
    properties (SetAccess=private, Hidden)
        gsPropRegExp = {'.*DAQmxGetDev(?<varName>.*)\(\s*cstring,\s*(?<varType>\S*)[\),].*'}; 
        gsPropPrefix = 'Dev'; 
        gsPropIDArgNames = {'deviceName'};
        gsPropNumStringIDArgs=1;
    end

    %% PDEP PROPERTIES
    %DAQmx-defined properties explicitly added to Device, because they are commonly used. Remaining properties are added dynamically, based on demand.
    
    properties (GetObservable, SetObservable)
       productCategory; 
       productType;
       serialNum;                     
    end
    
    %% PUBLIC PROPERTIES
    properties
        deviceName='';
    end
   
    %% CONSTRUCTOR/DESTRUCTOR
    
    methods
        function obj = Device(devname,varargin)
            % obj = Device(devname,varargin)
            % Get a Device handle
            %
            % This "constructor" method typically will not create a new
            % Device object. Instead, it will return a handle to the
            % existing Device object with name devname.
            
            
            %Handle case where superclass construction was aborted
            if obj.cancelConstruct
                delete(obj);
                return;
            end
            
            narginchk(1,inf);            
            
            if ~ischar(devname) || isempty(strtrim(devname))
                error('Invalid devname specified.');
            end
                        
            devmap = zapit.hardware.vidrio_daqmx.Device.getDeviceMap();
            
            if devmap.isKey(devname)
                % vj trick: delete half-constructed obj, return existing
                obj.delete;
                obj = devmap(devname);
            elseif zapit.hardware.vidrio_daqmx.Device.isValidDeviceName(devname)
                obj.deviceName = devname;
                devmap(devname) = obj; %#ok<NASGU>
            else
                % DAQmx doesn't know about a device by that name
                error(['There is no device ''' devname ''' in the system.']);
            end
        end        
    end
    
    methods (Access=private)
        function delete(obj) %#ok             
        end
    end        
    
    %% USER METHODS
    methods
        function reset(obj)
            %Immediately aborts all tasks associated with a device and returns the device to an initialized state. Aborting a task stops and releases any resources the task reserved.
            obj.apiCall('DAQmxResetDevice',obj.deviceName);                        
        end
        
        function selfTest(obj)
            %Causes a device to self-test.
            obj.apiCall('DAQmxSelfTestDevice',obj.deviceName);
        end        
    end
    
    %% DEVELOPER METHODS
    methods (Hidden, Static)
        function m = getDeviceMap()
            persistent map;
            if isequal(map,[])
                map = containers.Map();
            end
            m = map;            
        end
        function tf = isValidDeviceName(name)
            sys = zapit.hardware.vidrio_daqmx.System.getHandle();
            devnames = get(sys,'devNames'); % devnames are comma-delimited
            devnames = regexp(devnames,', ','split'); % devnames is now a cellstr
            tf = ismember(lower(name),lower(devnames));
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
