function conditionsExceedingLaserPower = checkLaserPower(obj)
    % Flag any stimulus condition that needs more laser power than the hardware can deliver
    %
    % conditionsExceedingLaserPower = zapit.stimConfig.checkLaserPower()
    %
    % Purpose
    % For each stimulus condition we work out the peak laser power it will demand. The peak
    % is higher than the requested time-averaged power because the laser is only on for part
    % of each modulation cycle (see zapit.stimConfig.laserPowerFromTrial). If a condition's
    % peak power exceeds the maximum the laser can produce, it will be silently capped at
    % presentation time (zapit.pointer.laser_mW_to_control), so the delivered power will be
    % lower than requested. We detect that here, when the config is loaded, so the user is
    % warned up front rather than only via per-trial messages during an experiment.
    %
    % The result is stored in the observable property conditionsExceedingLaserPower and also
    % returned. It is an empty vector if every condition is deliverable, otherwise a row
    % vector of the offending condition indices. If a breach is found it is always reported
    % to the CLI; the GUI additionally shows a warning dialog (see
    % zapit.gui.main.controller.loadStimConfig_Callback).
    %
    % Inputs
    % none
    %
    % Outputs
    % conditionsExceedingLaserPower - indices of conditions whose peak power exceeds the max
    %
    %
    % Rob Campbell - SWC 2026
    %
    % See also
    % zapit.stimConfig.laserPowerFromTrial
    % zapit.pointer.laser_mW_to_control


    conditionsExceedingLaserPower = [];

    % We can not know the laser maximum without the hardware settings, which arrive via the
    % parent zapit.pointer. If it is not attached yet we can not check, so bail out.
    if isempty(obj.parent)
        obj.conditionsExceedingLaserPower = conditionsExceedingLaserPower;
        return
    end

    tolerance_mW = 0.01; % Generous numerical tolerance so float noise can not flag a condition
    maxPower_mW = obj.parent.settings.laser.laserMinMax_mW(2);

    % Peak power required by each condition
    peakPower_mW = zeros(1,obj.numConditions);
    for ii = 1:obj.numConditions
        peakPower_mW(ii) = obj.laserPowerFromTrial(ii);
    end

    conditionsExceedingLaserPower = find(peakPower_mW > (maxPower_mW + tolerance_mW));
    obj.conditionsExceedingLaserPower = conditionsExceedingLaserPower;

    % Always report a breach to the CLI
    if ~isempty(conditionsExceedingLaserPower)
        fprintf(['\n ** WARNING: %d stimulus condition(s) request more laser power than your ', ...
            'laser can deliver (max %0.2f mW).\n'], ...
            length(conditionsExceedingLaserPower), maxPower_mW)
        for ii = conditionsExceedingLaserPower
            fprintf('    Condition %d needs %0.2f mW peak\n', ii, peakPower_mW(ii))
        end
        fprintf(['    These will be capped at the laser maximum during presentation, so the ', ...
            'delivered power will be lower than requested.\n\n'])
    end

end % checkLaserPower
