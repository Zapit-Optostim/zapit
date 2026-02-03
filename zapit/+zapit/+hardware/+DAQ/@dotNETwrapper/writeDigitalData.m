function writeDigitalData(obj,waveforms)
    % Write digital data to the buffer
    %
    % function zapit.DAQ.dotNETwrapper.writeDigitalData(waveforms)
    %
    % Purpose
    % Write digital data to the buffer and also log in a property the
    % data that were written.
    %
    % Inputs
    % waveforms - columns are channels and rows are samples
    %
    % Rob Campbell 


    % TODO -- check we have zeros and ones only


    % If this is a long waveform we cache it
    %if size(waveforms,1)>1
    %    obj.lastWaveform = waveforms;
    %end

    % Convert the waveforms to the correct format for the portData
    for ii=0:size(waveforms,2)-1
        b(ii+1) = bitshift(1,ii);
    end
    
    DOportData = uint32(sum(waveforms.*b,2));

    % We want to auto-start only the on-demand tasks because zapit.pointer
    % has methods that calls DAQmx start for the clocked operations.
    verbose = false; % For debugging


    % TODO -- this should probably never be on demand
    if strcmp(char(obj.hAO.Timing.SampleTimingType),'OnDemand')
        if verbose
            fprintf('Writing to buffer: on-demand\n')
        end
        obj.hDOtaskWriter.WriteMultiSamplePort(false,DOportData);
    else
        if verbose
            fprintf('Writing to buffer: clocked\n')
        end
        obj.hDOtaskWriter.WriteMultiSamplePort(false,DOportData);
    end

end % writeDigitalData