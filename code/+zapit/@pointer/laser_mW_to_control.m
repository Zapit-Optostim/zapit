function controlVal = laser_mW_to_control(obj,mW)
% Convert a value in mW to a control voltage for laser
% 
% function controlVal = laser_mW_to_control(obj,mW)
%
%  Purpose
%  Convert laser valye in mW to control voltage
%
% See also: zapit.pointer.setLaserInMW


if isempty(obj.laserFit)
    fprintf('** No laser fit. Making linear conversion as a guess! ** \n')
    laserFit_mWToControl = fit(obj.laserMinMax_mW', obj.laserMinMaxControl','linear');
    controlVal = laserFit_mWToControl(mW);
else
    % Get a dumb conversion of sensor values to mW
    sensorVals = [obj.laserFit.sensorValues(1);obj.laserFit.sensorValues(end)];
    laserFit_mWToSensorVal = fit(obj.laserMinMax_mW', sensorVals,'linear');
    sensorVal = laserFit_mWToSensorVal(mW);

    controlVal = obj.laserFit.sensorOnControl(sensorVal);
end

