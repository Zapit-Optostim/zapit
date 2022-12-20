function controlVal = laser_mW_to_control(obj,mW)
% Convert a value in mW to a control voltage for laser
% 
% function controlVal = laser_mW_to_control(obj,mW)
%
%  Purpose
%  Convert laser value in mW to control voltage
%
% See also: zapit.pointer.setLaserInMW


if isempty(obj.laserFit)
    fprintf('** No laser fit. Making linear conversion as a guess! ** \n')
    laserFit_mWToControl = fit(obj.laserMinMax_mW', obj.laserMinMaxControl','linear');
    controlVal = laserFit_mWToControl(mW);
else
    % Re-scale the sensory values so they are in mW
    mWvals = obj.laserFit.sensorValues;
    mWvals = mWvals - min(mWvals);
    mWvals = mWvals / max(mWvals);

    % TODO -- for now let us just assume that it starts at zero
    mWvals = mWvals * obj.laserMinMax_mW(2);

    % We want the other way around, but this is the correct way to fit
    laserFit_ControlToMW = fit(obj.laserFit.controlValues,mWvals,'poly5');

    % So now we find the closest value
    contV = linspace(obj.laserFit.controlValues(1),obj.laserFit.controlValues(end),100);
    mwV = laserFit_ControlToMW(contV);

    [~,ind] = min(abs(mwV-mW));

    controlVal = contV(ind(1)); % take the first if there are multiple
end

