function versions = getSupportedDAQmxVersions
switch computer('arch')
    case 'win32'
        archFolder = 'win32';
    case 'win64'
        archFolder = 'x64';
    otherwise
        error('NI DAQmx: Unknown computer architecture :%s',computer(arch));
end
    folders = dir('NIDAQmx_*');
    folders = {folders.name};
    
    versions = {};
    for i = 1:length(folders)
        folder = folders{i};
        supported = 0 < exist(fullfile(pwd,folder,archFolder,'NIDAQmx_proto.m'),'file') ...
                 || 0 < exist(fullfile(pwd,folder,archFolder,'NIDAQmx_proto.p'),'file');
        if strcmp(archFolder,'x64')
            supported = supported && 0 < exist(fullfile(pwd,folder,archFolder,'nicaiu_thunk_pcwin64.dll'),'file');
        end
        
        if supported
           versions{end+1} = strrep(strrep(folder,'NIDAQmx_',''),'_','.'); %#ok<AGROW>
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
