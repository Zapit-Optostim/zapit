function stopOptoStim(obj, rampDownInMS)
    % Stop laser stimulation. Slowly ramping down the signal over time
    %
    % zapit.pointer.stopOptoStim(obj, rampDownInMS)
    %
    % Purpose
    % Stop stimulation over a period of time specified by rampDownInMS.
    % This is 250 ms by default.
    %
    % Inputs
    % rampDownInMS - 250 ms by default.
    %
    %
    % Rob Campbell - SWC 2022


    % Number of ms over which to ramp down. TODO -- set up as parameter
    if nargin<2
        rampDownInMS = 250;
    end

    samplesPerSecond = obj.DAQ.samplesPerSecond;
    bufferSize = obj.numSamplesPerChannel;

    if isempty(bufferSize)
        return
    end


    % If the user requests no ramp-down then we simply stop the task
    if rampDownInMS ==0
    % Zero everything
        t = obj.waveforms;
        t(:) = 0;
        obj.DAQ.hC.writeAnalogData(t);
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
    ampSequence = linspace(1,0,numBuffers+2);
    ampSequence(1) = [];
    ampSequence(end) = [];

    for amp = ampSequence
        t = obj.waveforms;
        t(:,3) = t(:,3) * amp;
        obj.DAQ.hC.writeAnalogData(t);
    end

    % Zero everything
    t(:) = 0;
    obj.DAQ.hC.writeAnalogData(t);

    % stop task and send to pre-generation stage, allowing to write
    % next trial samples without conflicts
    obj.DAQ.hC.stop
    % TODO - might need to hC.abort

end % stopOptoStim

