function unpresentable = returnUnpresentableConditions(obj)
    % Return indices of conditions that can not be physically presented
    %
    % unpresentable = zapit.stimConfig.returnUnpresentableConditions()
    %
    % Purpose
    % A stimulus condition can not be presented if the beam-blanking at each point
    % transition leaves no time to actually illuminate the point. This happens when too
    % many points are packed into one modulation cycle for the blanking duration: each
    % point's time-slot is numSamplesPerChannel/points samples, and the blanking eats
    % totalBlank of those. When totalBlank fills (or overruns) the slot, the point gets
    % zero (or negative) laser-on time and the waveform is meaningless. There is no valid
    % waveform for such a condition, so zapit.pointer.loadStimConfig refuses to load a
    % config that contains one, and zapit.stimConfig.chanSamples errors if one is reached.
    %
    % We require a small buffer (minOnSamples) of on-time per point, so a point that would
    % be illuminated for essentially zero samples is also rejected.
    %
    % The limit depends on the modulation frequency (from the config), the DAQ sample rate,
    % and the blanking settings (all from the parent). It is recomputed from live values,
    % since those settings can change.
    %
    % Inputs
    % none
    %
    % Outputs
    % unpresentable - row vector of the indices of conditions that can not be presented.
    %                 Empty if all conditions are fine.
    %
    %
    % Rob Campbell - SWC 2026
    %
    % See also
    % zapit.stimConfig.chanSamples
    % zapit.pointer.loadStimConfig


    unpresentable = [];

    % Without a parent we do not have the sample rate / blanking settings, so we can not check
    if isempty(obj.parent)
        return
    end

    minOnSamples = 2; % require at least this many samples of laser-on time per point

    samplesPerSecond = obj.parent.DAQ.samplesPerSecond;
    numSamplesPerChannel = round(samplesPerSecond / obj.stimModulationFreqHz);

    % Total blanking samples per point transition. This mirrors the quantities used in
    % zapit.stimConfig.chanSamples (blankingSamples + the two shift terms).
    totalBlank = round(obj.blankingTime_ms * 1E-3 * samplesPerSecond) + ...
                 round(obj.parent.settings.experiment.blankOnsetShift_ms  * 1E-3 * samplesPerSecond) + ...
                 round(obj.parent.settings.experiment.blankOffsetShift_ms * 1E-3 * samplesPerSecond);

    for ii = 1:obj.numConditions
        % Single points are spoofed to two points internally (see chanSamples), so the
        % effective number of points per cycle is at least two.
        effectivePoints = max(length(obj.stimLocations(ii).ML), 2);
        if effectivePoints * (totalBlank + minOnSamples) > numSamplesPerChannel
            unpresentable(end+1) = ii; %#ok<AGROW>
        end
    end

end % returnUnpresentableConditions
