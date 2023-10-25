function [peak_mW, standardised_mW] = laserPowerFromTrial(obj, trialIndex, standardised_mW)
    % Get laser power specified at a given trial. If necessary, scale by stim pulse duration
    %
    % function  [peak_mW, standardised_mW] = zapit.stimConfig.laserPowerFromTrial(trialIndex)
    %
    % Purpose
    % Return the laser power in mW specified in the stim config YML file for trial at
    % index "trialIndex". Two values are returned. The second is the "standardised"
    % value requested in the stimulus config. The first is the corrected peak power
    % should the user have requested a short pulse duration. If the duty cycle is 0.5
    % and two stimuli are presented then the two numbers will match.
    % If duty cycle is shorter then power will increase linearly. e.g. if the duty cycle is
    % 0.05, so the laser is on for only one 10th of the time then the power will be 10x.
    %
    %
    % Inputs (required)
    % trialIndex - index of zapit.stimConfig.stimLocations
    %
    % Inputs (optional)
    % standardised_mW - By default this value is obtained from the stimConfig file. But
    %               the user can also request a specific power. The reason for this is
    %               so that a peak power can be calculated based upon this value and the
    %               stimulus duration. It allows laser power to be set on the fly by
    %               zapit.pointer.sendSamples
    %
    % Outputs
    % peak_mW - Peak power for each pulse. This will be higher than the requested power
    %           if the stimulus duration is shorter. This matches standardised_mW for
    %           duty cycles of 0.5.
    % standardised_mW - This is simply power value requested in the YML.
    %
    % Rob Campbell - SWC 2023

    if nargin<3
        standardised_mW = obj.stimLocations(trialIndex).Attributes.laserPowerInMW;
    end

    % Handle situation where user has asked for a shorter stimulus pulses.
    % TODO: This is being modified to present multiple stimuli in a trial
    % We scale the waveform amplitude:

    if isfield(obj.stimLocations(trialIndex).Attributes,'stimPulseDuration_ms')
        stimDuration = obj.stimLocations(trialIndex).Attributes.stimPulseDuration_ms;
    else
        numStimuli = length(obj.stimLocations(trialIndex).ML);

        if numStimuli <= 2
            stimDuration = obj.maxStimPulseDuration;
        else
            % TODO: need to set correctly! <---
            stimDuration = obj.maxStimPulseDuration * (2/numStimuli);
        end


    end

    peak_mW = correctLaserPower(obj,standardised_mW,stimDuration);
