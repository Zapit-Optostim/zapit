function setLaserInMW(obj,mW)
% Set laser to a value specified by the user in mW
%
% function setLaserInMW(obj,mW)
%
%
% Purpose
% User supplies value in mW. This is converted to a control value
% and applied to the laser.
%
%
%


% TODO -- there are issues with the fit, which is why we are doing this
if mW>0
    controlValue = obj.laser_mW_to_control(mW);
else
    controlValue = 0;
end

obj.DAQ.setLaserPowerControlVoltage(controlValue);
