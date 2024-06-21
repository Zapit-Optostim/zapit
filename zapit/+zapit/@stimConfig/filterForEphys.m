function [ephysWaveform,scaleFactor] = filterForEphys(obj,inputWaveform)
    % Filter the laser waveform for ephys: turning square waves into sinusoids
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
    % The ephys waveform is made by converting the "on" epochs into a half cycle of
    % sinusoid.
    %
    % NOTE
    % The waveform will have a higher peak value (>1) and this should take into account
    % the higher laser power that we need to produce. See how zapit.pointer.sendSamples
    % produces the laser power.
    %
    % Inputs
    % inputWaveform - The raw laser waveform before filtering.
    %
    % Outputs
    % ephysWaveform - The filtered waveform.
    % scaleFactor [optional] - Scalar indicating by how much the waveform was multiplied such that
    %       it has the same area as the original trace. So takes into account the lower
    %       integrated power of the sinusoidal waveform.
    %
    %
    % Rob Campbell - SWC 2023



    % Find the length of the on and off blocks. We know the stimulus "on" times will be
    % the longest epochs, so we use that information to find those.
    blockLengths = diff(find(abs(diff(inputWaveform))));
    maxBlockLength = max(blockLengths);

    % The start of the stim epoch blocks
    f=find(diff(inputWaveform)==1);

    % Waveform
    wForm = sin(linspace(0,pi,maxBlockLength));
    maxVal = 1;
    wForm(wForm>maxVal)=maxVal;

    % Populate
    ephysWaveform = zeros(size(inputWaveform));
    for ii=1:length(f)
        s = f(ii)+1;
        ephysWaveform(s:s+maxBlockLength-1) = wForm;
    end




    % scale such that that area under the curves are the same
    E = sum(ephysWaveform);
    I = sum(inputWaveform);
    scaleFactor = I/E;

    % Check that the scaling is correct (it must be, but let's be paranoid)
    ephysWaveform = ephysWaveform * scaleFactor;

    if round(sum(ephysWaveform)) ~= round(sum(inputWaveform))
        fprintf('zapit.stimConfig.%s -- Warning! The areas under the original and ephys-corrected waveforms are not the same!\n', mfilename)
    end

    doPlot = true;
    if doPlot
        plot(ephysWaveform,'-k')
        hold on
        plot(inputWaveform,'-r')
        hold off
    end

end %filterForEphys
