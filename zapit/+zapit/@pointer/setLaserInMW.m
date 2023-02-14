function setLaserInMW(obj,mW)
    % Set laser to a value specified by the user in mW
    %
    % function zapit.pointer.setLaserInMW(mW)
    %
    %
    % Purpose
    % User supplies value in mW. This is converted to a control value
    % and applied to the laser.
    %
    % Inputs
    % mW - (scalar) laser power in mW
    %
    % Outputs
    % none


    % Some lasers (usually cheap ones) may have funny non-linear fits near
    % zero. So we force a value of zero to ensure the laser turns off. This
    % if statement will have no affect on nice, linear, ones like the Obis.
    if mW>0
        controlValue = obj.laser_mW_to_control(mW);
    else
        controlValue = 0;
    end

    obj.setLaserPowerControlVoltage(controlValue);

end % setLaserInMW
