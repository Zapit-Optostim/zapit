function peak_mW = correctLaserPowerForShorterDurationPulses(obj,standardisedPower_mw,stimDuration_ms)
    % Increase laser peak power if duty cycle is below 50%. e.g. multiple samples
    %
    % function peak_mW = zapit.stimConfig.correctLaserPowerForShorterDurationPulses(standardisedPower_mw,stimDuration_ms)
    %
    % Purpose
    % Implements peak power calculation described in  zapit.stimConfig.laserPowerFromTrial
    % This is the corrected peak power which is needed should the user have requested a
    % short pulse duration. If the duty cycle is 0.5 and two stimuli are presented then the
    % two numbers will match. If duty cycle is shorter then power will increase linearly.
    % e.g. if the duty cycle is 0.05, so the laser is on for only one 10th of the time then
    % the power will be 10x.
    %
    % Inputs
    % standardisedPower_mw - that requested and defined in terms of 40 Hz 50% duty cycle.
    % stimDuration_ms - the stimulus pulse duration that has been requested.
    %
    % Outputs
    % peak_mW - Peak power for each pulse. This will be higher than the requested power
    %           if the stimulus duration is shorter. This matches standardised_mW for
    %
    % Rob Campbell - SWC 2023

    % TODO -- handle cases where there is no longer enough power.

    peak_mW = (obj.maxStimPulseDuration / stimDuration_ms) * standardisedPower_mw;

end % correctLaserPowerForShorterDurationPulses
