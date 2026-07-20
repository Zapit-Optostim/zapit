function writeAnalogData(obj,waveforms)
    % Write analog data to the buffer
    %
    % function zapit.DAQ.dotNETwrapper.writeAnalogData
    %
    % Purpose
    % Write analog data to the buffer and also log in a property the
    % data that were written.
    %
    % Inputs
    % waveforms - columns are channels and rows are samples
    %
    %
    % Rob Campbell - SWC

    % Double-check no values are out of range
    if any(abs(max(waveforms,[],1))>10)
        fprintf(' ** There are waveform data that exceed the +/- 10V range **\n')
    end

    % If this is a long waveform we cache it
    if size(waveforms,1)>1
        obj.lastWaveform = waveforms;
    end

    % If the task is a finite samples we must set the number of samples in the
    % DAQ buffer.
    if strcmp(obj.hAO.Timing.SampleQuantityMode,'FiniteSamples')
        obj.hAO.Timing.SamplesPerChannel = length(waveforms);
    end

    % We want to auto-start only the on-demand tasks because zapit.pointer
    % has methods that calls DAQmx start for the clocked operations.
    verbose = false; % For debugging
    if strcmp(char(obj.hAO.Timing.SampleTimingType),'OnDemand')
        if verbose
            fprintf('Writing to buffer: on-demand\n')
        end
        obj.hAOtaskWriter.WriteMultiSample(false,waveforms');
    else
        if verbose
            fprintf('Writing to buffer: clocked\n')
        end
        obj.hAOtaskWriter.WriteMultiSample(false,waveforms');
    end
end % writeAnalogData