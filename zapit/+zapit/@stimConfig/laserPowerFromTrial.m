function [peak_mW, standardised_mW] = laserPowerFromTrial(obj,trialIndex)
    % Get laser power specified at a given trial. If necessary, scale by stim pulse duration
    %
    % function t_mW = zapit.stimConfig.laserPowerFromTrial(trialIndex)
    %
    % Purpose
    % Return the laser power in mW specified in the stim config YML file for trial at
    % index "trialIndex". This power value assumes a 0.5 duty cycle at 40 Hz for two stimuli.
    % If duty cycle is shorter then power will increase linearly. e.g. if the duty cycle is
    % 0.05, so the laser is on for only one 10th of the time then the power will be 10x.
    % TODO -- check above is clear
    % TODO -- handle case where there is no longer enough
    %
    % Inputs
    % trialIndex - index of zapit.stimConfig.stimLocations
    %
    % Outputs
    % peak_mW - Peak power for each pulse. This will be higher than the requested power
    %           if the stimulus duration is shorter. This matches standardised_mW for
    %           duty cycles of 0.5.
    % standardised_mW - This is simply power value requested in the YML.


    standardised_mW = obj.stimLocations(trialIndex).Attributes.laserPowerInMW;

    % Handle situation where user has asked for a shorter stimulus pulses.
    % TODO: These will eventually be used to present multiple stimuli in a trial
    % We scale the waveform amplitude:
    if isfield(obj.stimLocations(trialIndex).Attributes,'stimPulseDuration_ms')
        stimDuration = obj.stimLocations(trialIndex).Attributes.stimPulseDuration_ms;
        peak_mW = (obj.maxStimPulseDuration / stimDuration) * standardised_mW;
    else
        peak_mW = standardised_mW;
    end
