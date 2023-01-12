% General method for writing analog data to a Task containing one or more anlog output Channels
%% function sampsPerChanWritten = writeAnalogData(task, writeData, timeout, autoStart, numSampsPerChan)
%   writeData: Data to write to the Channel(s) of this Task. Supplied as matrix, whose columns represent Channels.
%              Data should be of numeric types double, uint16, or int16.
%              Data of double type will be 'scaled' by DAQmx driver, which includes application of software calibration, for devices which support this.
%              Data of uint16/int16 types will be 'unscaled' -- i.e. in the 'native' format of the device. Note such samples will not be calibrated in software.
%
%   timeout: <OPTIONAL - Default: inf) Time, in seconds, to wait for function to complete read. If 'inf' or < 0, then function will wait indefinitely. A value of 0 indicates to try once to write the submitted samples. If this function successfully writes all submitted samples, it does not return an error. Otherwise, the function returns a timeout error and returns the number of samples actually written.
%   autoStart: <OPTIONAL - Logical - Default: true if sample timing type is 'On Demand', false otherwise> Logical value specifies whether or not this function automatically starts the task if you do not start it. 
%   numSampsPerChan: <OPTIONAL> Specifies number of samples per channel to write. If omitted/empty, the number of samples is inferred from number of rows in writeData array. 
%
%   sampsPerChanWritten: The actual number of samples per channel successfully written to the buffer.
%
%% NOTES
%   If double data is supplied, the DAQmxWriteAnalogF64 function in DAQmx API is used. 
%   If uint16/int16 data is supplied, the DAQmxWriteBinaryU16/I16 functions, respectively, in DAQmx API are used.
%
%   The 'dataLayout' parameter of DAQmx API functions is not supported -- data is always grouped by Channel (DAQmx_Val_GroupByChannel).
%   This corresponds to Matlab matrix ordering where each Channel corresponds to one column. 
%
%   Some general rules:
%       If you configured timing for your task (using a cfgXXXTiming() method), your write is considered a buffered write. The # of samples in the FIRST write call to Task configures the buffer size, unless cfgOutputBuffer() is called first.
%       Note that a minimum buffer size of 2 samples is required, so a FIRST write operation of only 1 sample (without prior call to cfgOutputBuffer()) will generate an error.
%






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
