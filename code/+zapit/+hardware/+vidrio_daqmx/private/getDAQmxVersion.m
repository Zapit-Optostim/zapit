function [majorVer,minorVer,updateVer] = getDAQmxVersion()
persistent versionInfo

if ~isempty(versionInfo)
    majorVer  = versionInfo.majorVer;
    minorVer  = versionInfo.minorVer;
    updateVer = versionInfo.updateVer;
    return
end

if libisloaded('nicaiu')
    unloadlibrary('nicaiu');
end

try
    switch computer('arch')
        case 'win32'
            loadlibrary('nicaiu',@apiVersionDetect);
        case 'win64'
            loadlibrary('nicaiu',@apiVersionDetect64);
        otherwise
            error('NI DAQmx: Unknown computer architecture :%s',computer(arch));
    end
catch ME
    majorVer =  [];
    minorVer =  [];
    updateVer = [];
    return
end

[code,majorVer] = calllib('nicaiu','DAQmxGetSysNIDAQMajorVersion',0);
assert(code==0);
[code,minorVer] = calllib('nicaiu','DAQmxGetSysNIDAQMinorVersion',0);
assert(code==0);

if ismember('DAQmxGetSysNIDAQUpdateVersion',libfunctions('nicaiu'))
    [code,updateVer] = calllib('nicaiu','DAQmxGetSysNIDAQUpdateVersion',0);
else
    updateVer = 0;
end

unloadlibrary('nicaiu');

versionInfo = struct();
versionInfo.majorVer  = majorVer;
versionInfo.minorVer  = minorVer;
versionInfo.updateVer = updateVer;
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
