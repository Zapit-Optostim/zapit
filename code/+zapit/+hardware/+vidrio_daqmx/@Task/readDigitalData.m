% General method for reading digital data from a Task containing one or more digital input Channels
%% function [outputData, sampsPerChanRead] = readDigitalData(task, numSampsPerChan, outputFormat, timeout, outputVarSizeOrName)
%	numSampsPerChan: <OPTIONAL - Default: 1/Inf> Specifies (maximum) number of samples per channel to read. If 'inf' or < 0, then all available samples are read, up to the size of the output array  
%                       If omitted/empty, value of 'Inf'/1 is used for buffered/unbuffered read operations, respectively.
%           
%	outputFormat: <OPTIONAL - one of {'logical' 'double' 'uint8' 'uint16' 'uint32'}> Data will be output as specified type, if possible. 
%               If omitted/empty, data type of output will be determined automatically:
%                   If read operation is non-buffered and Channels in Task are 'line-based', then double type will be used.
%                   Otherwise, the smallest allowable choice of uint8/16/32 will be used
%               If outputFormat=uint8/16/32, and the following restrictions should be followed:
%                   If Channel in Task are 'port-based', the data type specified must contain as many bits as the largest port in the Task.
%                   If Channel in Task are 'line-based', the data type specified must contain as many bits as the line in Task belonging to the largest port.
%                   If Task contains multiple Channels, then the largest data type required by any Channel must be specified (and used for all Channels).
%   timeout: <OPTIONAL - Default: Inf> Time, in seconds, to wait for function to complete read. If omitted/empty, value of 'Inf' is used. If 'Inf' or < 0, then function will wait indefinitely.
%	outputVarSizeOrName: <OPTIONAL> Size in samples of output variable to create (to be returned as outputData argument). 
%                                   If empty/omitted, the output array size is determined automatically. 
%                                   Alternatively, this may specify name of preallocated MATLAB variable into which to store read data.                                    
%
%   outputData: Array of output data with samples arranged in rows and channels in columns. This value is not output if outputVarOrSize is a string specifying a preallocated output variable.
%               For outputFormat=logical/double, samples for each line are output as separate values, so number of rows will equal (# samples) x (# lines/Channel)
%                   If multiple Channels are present, (# lines/Channel) value corresponds to Channel with largest # lines.
%               For outputFormat=uint8/16/32, one value is supplied for each sample, i.e. the number of rows equals (# samples)
%               NOTE: If Channels are 'line-based' and uint8/16/32 type is used, then data will be arranged in uint8/16/32 value according to the bit/line number 
%                   (e.g. bit 7 for line 7, even if line 7 is only line in Channel), and NOT by the order/number of lines in the Channel. 
%                   Bits in the output value corresponding to lines not included in Channel are meaningless.                       
%   sampsPerChanRead: Number of samples actually read. This may be smaller than that specified/implied by outputVarOrSize.
%
%% NOTES
%   The 'fillMode' parameter of DAQmx API functions is not supported -- data is always grouped by Channel (DAQmx_Val_GroupByChannel).
%   This corresponds to Matlab matrix ordering where each Channel corresponds to one column. 
%
%   If outputFormat is 'logical'/'double', then DAQmxReadDigitalLines function in DAQmx API is used
%   If outputFormat is 'uint8'/'uint16'/'uint32', then DAQmxReadDigitalU8/U16/U32 functions in DAQmx API are used.
%
%   At moment, the option to specify the name of a preallocated MATLAB variable, via the outputVarSizeOrName argument, is not supported.





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
