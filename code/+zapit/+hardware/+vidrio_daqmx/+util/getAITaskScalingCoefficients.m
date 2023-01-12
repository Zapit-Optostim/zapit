function coeff = getAITaskScalingCoefficients(hTask)
% Outputs a 4xN array with scalingcoefficients for each of the N Tasks
% such that f(X) = coeff(1,N)*X^0 + coeff(2,N)*X^1 + coeff(3,N)*X^2 + coeff(4,N)*X^3

% More information:
% Is NI-DAQmx Read Raw Data Calibrated and/or Scaled in LabVIEW?
% http://digital.ni.com/public.nsf/allkb/0FAD8D1DC10142FB482570DE00334AFB?OpenDocument

assert(isa(hTask.channels,'zapit.hardware.vidrio_daqmx.AIChan'),'hTask does not contain AI channels');
channelNames = arrayfun(@(ch)ch.chanName,hTask.channels,'UniformOutput',false);

numCoeff = 4;

coeff = zeros(numCoeff,numel(channelNames));
for idx = 1:length(channelNames)
    chName = channelNames{idx};
    a = zeros(numCoeff,1);
    ptr = libpointer('voidPtr',a);
    hTask.apiCallRaw('DAQmxGetAIDevScalingCoeff',hTask.taskID,chName,ptr,numCoeff);
    coeff(:,idx) = ptr.Value;
    ptr.delete();
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
