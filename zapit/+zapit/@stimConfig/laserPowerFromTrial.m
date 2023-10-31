function [peak_mW, standardised_mW, stimDuration_ms] = laserPowerFromTrial(obj, trialIndex, standardised_mW, power_vector)
    % Get laser power specified at a given trial. If necessary, scale by stim pulse duration
    %
    % function  [peak_mW, standardised_mW] = zapit.stimConfig.laserPowerFromTrial(trialIndex)
    %
    % Purpose
    % Return the laser power in mW specified in the stim config YML file for trial at
    % index "trialIndex". Two values are returned. The second is the "standardised"
    % or "time-averaged" value requested in the stimulus config. The first is the corrected
    % peak power this value takes into account the stimulus duration such each point will
    % receive the time averaged power.
    % If duty cycle is shorter then power will increase linearly. e.g. if the duty cycle is
    % 0.05, so the laser is on for only one 10th of the time then the power will be 10x.
    %
    %
    % Inputs (required)
    % trialIndex - index of zapit.stimConfig.stimLocations
    %
    % Inputs (optional)
    % standardised_mW - By default this value is obtained from the stimConfig file. But
    %               the user can also request a specific power when calling
    %               pointer.sendSamples. The reason for this is o that a peak power can be
    %               calculated based upon this value and the stimulus duration. It allows
    %               laser power to be set on the fly by zapit.pointer.sendSamples
    %
    %
    % Outputs
    % peak_mW - Peak power for each photo-stimulation pulse. This will be higher than the
    %           requested power if the stimulus duration is shorter than the stimulus
    %           period which it always will be.
    % standardised_mW - This is simply power value requested in the YML.
    % stimDuration_ms - The stimulus duration in ms.
    %
    % Rob Campbell - SWC 2023




    % Get the standardised (time-averaged) power from the settings
    if nargin<3 || isempty(standardised_mW)
        standardised_mW = obj.stimLocations(trialIndex).Attributes.laserPowerInMW;
    end


    % Handle situation where user has asked for a shorter stimulus pulses.
    % TODO: This is being modified to present multiple stimuli in a trial
    % We scale the waveform amplitude:

    modulationPeriod = 1/obj.stimLocations(trialIndex).Attributes.stimModulationFreqHz;
    modulationPeriod_ms = modulationPeriod * 1E3;


    numStimuli = length(obj.stimLocations(trialIndex).ML);

    if numStimuli <= 1
        stimDuration_ms = modulationPeriod_ms * obj.dutyCycle;
    else

        stimDuration_ms = (modulationPeriod_ms - obj.blankingTime_ms * numStimuli) / numStimuli;

        % NOTE. The requirement for the following fudge factor was discovered by measuring
        % the actual pulse duration using checkTimeAveragedPower in the development director.
        % I am not aware of why it's needed. The actual duration values are 0.13 to 0.12 ms
        % smaller consistently. It's much more than one one sample.
        % TODO & NOTE: we still do not exactly the correct stim duration. Off by about 20 microseconds.
        stimDuration_ms = stimDuration_ms - obj.blankingTime_ms/2;

        if nargin>3
            pointsPerStim = sum(power_vector>0) / numStimuli;
            TIME= (pointsPerStim / obj.parent.DAQ.samplesPerSecond) * 1E3;
            fprintf('CALC %0.3f ; actual %0.3f\n', TIME, stimDuration_ms)
        end
    end


    peak_mW = (modulationPeriod_ms / stimDuration_ms) * standardised_mW;

    verbose = false;

    if verbose
        fprintf('Peak laser power: %0.2f mW from %0.2f mW time averaged.\n', ...
            peak_mW, standardised_mW);
    end
