function slewScanners(obj,targetPosition)
    % Moves the scanners slowly (quietly) from one position to another
    %
    % zapit.pointer.slewScanners(targetPosition, currentPosition))
    %
    % Purpose
    % Move the scanners in a slow (3 ms) and quiet way between points. Assumes the
    % currentPosition is the last position from the last played waveform.
    %
    % Inputs
    % targetPosition - [xPos, yPos] values in mm.
    %
    % Rob Campbell - SWC 2023


    % Do not try to run if no stimuli loaded
    if isempty(obj.DAQ.lastWaveform)
        return
    end

    [targetXVolts, targetYVolts]=obj.mmToVolt(targetPosition(1), targetPosition(2));

    nSamples = hZP.DAQ.samplesPerSecond * 3E-3;


    slewWaveform = [linspace(obj.DAQ.lastWaveform(end,1), targetXVolts,,nSamples)', ...
         linspace(obj.DAQ.lastWaveform(end,2), targetYVolts,,nSamples)'];


    % TODO -- check this is not connecting when it should not
    obj.DAQ.connectClockedAO('fixedDurationWaveform', true, ...
                        'numSamplesPerChannel', size(slewWaveform,1), ...
                        'hardwareTriggered', false, ...
                        'taskName', 'sendSamplesSTrig', ...


    % Write voltage samples onto the task
    obj.DAQ.writeAnalogData(slewWaveform);

    % Start the execution of the new task. Waveforms will only play immediately if
    % we are not waiting for a hardware trigger.
    obj.DAQ.start

end % stopOptoStim
