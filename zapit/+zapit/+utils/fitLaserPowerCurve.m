function laserFit = fitLaserPowerCurve(controlValues, sensorValues, doPlot)
    % Fit the measured laser power curve and (optionally) plot it
    %
    % function laserFit = zapit.utils.fitLaserPowerCurve(controlValues, sensorValues, doPlot)
    %
    % Purpose
    % Fit the relationship between laser control voltage and the measured photodiode
    % signal. The measured data are acquired by zapit.pointer.generateLaserCalibrationCurve.
    % Separating the fitting and plotting from the data acquisition allows this step to be
    % unit tested without hardware. The returned laserFit structure is complete, so the
    % caller can assign it directly to the zapit.pointer.laserFit property in a single line.
    %
    % Inputs
    % controlValues - vector of laser control voltages that were applied.
    % sensorValues - vector of photodiode signals measured at each control voltage.
    % doPlot - [optional] if true (the default) the fit and data are plotted.
    %
    % Outputs
    % laserFit - a structure with the following fields:
    %     sensorOnControl - fit of photodiode signal as a function of control voltage.
    %     controlValues - the control voltages (column vector).
    %     sensorValues - the measured photodiode signals (column vector).
    %     dateMade - the date the fit was made.
    %
    %
    % Rob Campbell - SWC 2026
    %
    % See also:
    % zapit.pointer.generateLaserCalibrationCurve
    % zapit.pointer.laser_mW_to_control


    if nargin<3
        doPlot = true;
    end

    % Ensure column vectors so the fit and plot behave regardless of input orientation
    controlValues = controlValues(:);
    sensorValues = sensorValues(:);

    if length(controlValues) ~= length(sensorValues)
        error('control and sensor value vectors must have the same length')
    end


    % Fit a third order polynomial: photodiode voltage as a function of control voltage
    % This fit is mainly for display purposes, we don't actually use it directly.
    % see zapit.pointer.laser_mW_to_control
    laserFit.sensorOnControl = fit(controlValues,sensorValues,'poly3');

    % Store the raw data and the date alongside the fit so the structure is self-contained
    laserFit.controlValues = controlValues;
    laserFit.sensorValues = sensorValues;
    laserFit.dateMade = now;

    % plot the data
    if doPlot
        zapit.utils.focusNamedFig('lasercalibrate');
        clf
        plot(laserFit.sensorOnControl,controlValues,sensorValues)
        ylim([0,max(sensorValues)*1.1])
        grid on
        xlabel('Laser Control Value [V]')
        ylabel('Photodiode Signal [V]')
    end

end % fitLaserPowerCurve
