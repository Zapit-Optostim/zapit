function stopOptoStim(obj, rampDownInMS)
    % Stop laser stimulation. Slowly ramping down the signal over time
    %
    % zapit.pointer.stopOptoStim(obj, rampDownInMS)
    %
    % Purpose
    % Stop stimulation over a period of time specified by rampDownInMS.
    % The value of rampDownInMS is obtained from the stimConfig file,
    % which in turn gets a default values from the Zapit settings file. 
    % It can, however, be over-ridden by supplying an input argiument
    % to this function.
    %
    % Inputs
    % rampDownInMS - Defaults to value in stimConfig.
    %
    %
    % Rob Campbell - SWC 2022


    if nargin<2
        rampDownInMS = obj.stimConfig.offRampDownDuration_ms;
    end

    samplesPerSecond = obj.DAQ.samplesPerSecond;
    bufferSize = obj.DAQ.numSamplesInBuffer;

    if isempty(bufferSize) || obj.DAQ.hAO.isTaskDone
        return
    end


    % If the user requests no ramp-down then we simply stop the task
    if rampDownInMS ==0
    % Zero everything
        t = obj.DAQ.lastWaveform;
        t(:) = 0;
        obj.DAQ.writeAnalogData(t);
        obj.DAQ.stop
    end


    % Otherwise we do a ramp-down
    msPerBuffer = (bufferSize/samplesPerSecond) * 1E3;

    % Handle case where the user asks for a ramp-down that is smaller than the
    % buffer size.
    if rampDownInMS < msPerBuffer
        rampDownInMS = msPerBuffer;
    end

    numBuffers = ceil(rampDownInMS / msPerBuffer);

    % The series of amplitudes over which we will loop
    smoothRamp = true; % if true we ramp the waveform nicely and not in steps

    if smoothRamp
        ampSequence = linspace(1,0,numBuffers+1);
        ampSequence(end) = [];
        ind = 2:length(ampSequence)-1;
    else
        ampSequence = linspace(1,0,numBuffers+1);
        ampSequence(end) = [];
        ind = 2:length(ampSequence);
    end


    orig = obj.DAQ.lastWaveform;

    if obj.simulated
        data = [];
    end

    for ii = ind

        t = obj.DAQ.lastWaveform;

        if smoothRamp
            endVal = ampSequence(ii);
            startVal = endVal - mean(diff(ampSequence));
            t(:,3) = t(:,3) .* linspace(startVal, endVal, size(obj.DAQ.lastWaveform,1))';
        else
            t(:,3) = t(:,3) * ampSequence(ii);
        end

        if obj.simulated
            data = [data;t];
        end

        obj.DAQ.writeAnalogData(t);

    end

    if obj.simulated
        zapit.utils.focusNamedFig(mfilename)
        clf
        plot(data(:,3),'-k', 'LineWidth',2)
        xlabel('Sample number')
        ylabel('Voltage')
    end

    % Zero everything
    t(:) = 0;
    obj.DAQ.writeAnalogData(t);

    obj.DAQ.stop

end % stopOptoStim

