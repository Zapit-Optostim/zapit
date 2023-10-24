function ephysWaveform = filterForEphys(obj,inputWaveform)
    % Filter the laser waveform for ephys
    %
    % function ephysWaveform = zapit.stimConfig.filterForEphys(obj,inputWaveform)
    %
    % Purpose
    % By default the laser is gated by a square wave which is high (on) once the beam
    % is stably over a single point. For electrophysiology we want ramp the signal in
    % order to reduce photoelectric artifacts. This is achieved by this function. The
    % overall amplitude of the signal is increased such that the area under the curve
    % remains the same. Thus the total number of photons delivered to the sample remain
    % unaltered.
    % The ephys waveform is made by filtering the raw laser signal with a Hanning filter
    % and re-zeroing all values that were zero originally.
    %
    %
    % Inputs
    % inputWaveform - The raw laser waveform before filtering.
    %
    % Outputs
    % ephysWaveform - The filtered waveform.
    %
    % Rob Campbell - SWC 2023



    if isempty(obj.parent)
        return
    end


    % To filter we need to ensure the *on* periods are centred. Therefore we circshift by
    % half the blanking time if the first sample is not a zero
    if inputWaveform(1)>0
        blankingTime = obj.parent.settings.experiment.blankingTime_ms;
        samplesPerSecond = obj.parent.DAQ.samplesPerSecond;
        cShiftQuantity = samplesPerSecond * blankingTime*1E-3 * 0.5;

        inputWaveform = circshift(inputWaveform, -cShiftQuantity);
    else
        cShiftQuantity = 0;
    end


    % Find the length of the on and off blocks. We know the stimulus "on" times will be
    % the longest epochs, so we use that information to find those.
    blockLengths = diff(find(abs(diff(inputWaveform))));
    maxBlockLength = max(blockLengths);


    % Define the tapering filter (e.g., Hann window) based on the length of the "on" block.
    taperLength = round(maxBlockLength/4);
    taper = hann(taperLength * 2)';

    % Create the modified signal
    ephysWaveform = conv(inputWaveform, taper, 'same');

    % Find the indices where zeros should be placed
    zeroIndices = inputWaveform == 0;

    % Replace the values in the output signal where zeros should be present
    ephysWaveform(zeroIndices) = 0;


    % Shift back

    ephysWaveform = circshift(ephysWaveform, cShiftQuantity);





    % scale such that that area under the curves are the same
    E=(sum(ephysWaveform));
    I=(sum(inputWaveform));

    ephysWaveform = ephysWaveform / (E/I);

    if round(sum(ephysWaveform)) ~= round(sum(inputWaveform))
        fprintf('Warning! The areas under the original and ephys-corrected waveforms are not the same!\n')
    end

    doPlot = false;
    if doPlot
        inputWaveform = circshift(inputWaveform, cShiftQuantity);
        plot(ephysWaveform,'-k')
        hold on
        plot(inputWaveform,'-r')
        hold off
    end



end %filterForEphys
