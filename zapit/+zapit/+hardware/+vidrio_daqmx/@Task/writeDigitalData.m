% General method for writing digital data to a Task containing one or more digital output Channels
%% function sampsPerChanWritten = writeDigitalData(task, writeData, timeout, autoStart, numSampsPerChan)
%   writeData: Data to write to the Channel(s) of this Task. Supplied as matrix, whose columns represent Channels.
%              Data should be of one of types: uint8,uint16,uint32,logical, or double.
%              Data of logical/double type should be supplied as a separate value per line (bit), so that number of rows should equal (# samples) x (# lines/Channel). 
%                  If multiple Channels are present, (# lines/Channel) value corresponds to Channel with largest # lines.
%              Data of type uint8/16/32 is supplied to write only one value per sample (per Channel), with the value specifying each of the lines (bits) in a Channel.
%                  If Channel in Task is 'port-based', the data type used should contain as many bits as the largest port in the Task.
%                  If Channel in Task is 'line-based', the data type used should contain as many bits as the largest port that any line in Task belongs to
%                  If Task contains multiple Channels, then the largest data type required by any Channel must be used for all Channels.
%                  Note that data for 'line-based' Channels must be arranged in uint8/16/32 value according to the bit/line number 
%                    (e.g. bit 7 for line 7, even if line 7 is only line in Channel), and NOT by the order/number of lines in the Channel. 
%                    Bits in the supplied value corresponding to lines not included in Channel are simply ignored.                                      
%
%   timeout: <OPTIONAL - Default: inf) Time, in seconds, to wait for function to complete read. If 'inf' or < 0, then function will wait indefinitely. A value of 0 indicates to try once to write the submitted samples. If this function successfully writes all submitted samples, it does not return an error. Otherwise, the function returns a timeout error and returns the number of samples actually written.
%   autoStart: <OPTIONAL - Logical> Logical value specifies whether or not this function automatically starts the task if you do not start it. 
%              If empty/omitted, true is assumed when writeData is logical/double and false is assumed when writeData is uint8/16/32.
%   numSampsPerChan: <OPTIONAL> Specifies number of samples per channel to write. If omitted/empty, the number of samples is inferred from number of rows in writeData array. 
%
%   sampsPerChanWritten: The actual number of samples per channel successfully written to the buffer.
%
%% NOTES
%   If uint8/16/32 data is supplied, the DAQmxWriteDigitalU8/U16/U32 functions in DAQmx API are used.
%   If logical/double data is supplied, the DAQmxWriteDigitalLines function in DAQmx API is used. 
%       (double data is converted to logical type)
%
%   The 'dataLayout' parameter of DAQmx API functions is not supported -- data is always grouped by Channel (DAQmx_Val_GroupByChannel).
%   This corresponds to Matlab matrix ordering where each Channel corresponds to one column. 
%
%   Some general rules:
%       logical/double data is generally supplied for non-buffered write operations, i.e. Tasks for which timing has NOT been configured with a cfgXXXTiming() method.
%       uint8/16/32 data is recommended (more efficient), but not required, for buffered write operations, i.e. Tasks for which timing has been configured with a cfgXXXTiming() method.
%   
%       Generally, logical/double data should only be supplied if Channel(s) in Task are 'line-based', rather than 'port-based'.   
%       In contrast, uint8/16/32 data is commonly used with either 'port-based' or 'line-based' Channels.
%
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
