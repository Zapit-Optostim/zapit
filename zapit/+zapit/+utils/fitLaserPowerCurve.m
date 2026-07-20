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
    % Two candidate fits are made: a third order polynomial and a logistic sigmoid. The one
    % with the smaller residual RMS is kept. A supposedly linear laser but with peculiar
    % deviations (e.g. some cheaper ones) should be captured well by the polynomial,
    % whereas a modulator with a saturating (sigmoidal) response, such as an EOM, is
    % captured better by the sigmoid.
    %
    %
    % Inputs
    % controlValues - vector of laser control voltages that were applied.
    % sensorValues - vector of photodiode signals measured at each control voltage.
    % doPlot - [optional] if true (the default) the fit and data are plotted.
    %
    %
    % Outputs
    % laserFit - a structure with the following fields:
    %     sensorOnControl - fit of photodiode signal as a function of control voltage.
    %     fitType - 'poly3' or 'sigmoid': which fit was kept.
    %     rmse - the residual RMS of the kept fit.
    %     controlValues - the control voltages (column vector).
    %     sensorValues - the measured photodiode signals (column vector).
    %     fittedSensorValues - the fit evaluated at controlValues (denoised curve). This is
    %                          used by zapit.pointer.laser_mW_to_control to convert a
    %                          requested power to a control voltage by linear interpolation.
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


    % Fit a third order polynomial: photodiode signal as a function of control voltage.
    % This captures a linear (or gently curving) laser well.
    [polyFit,polyGof] = fit(controlValues,sensorValues,'poly3');

    % Fit a logistic sigmoid: this captures a laser with a saturating response, such as an
    % EOM. The fit is wrapped in a try/catch so a failure to converge simply leaves the
    % polynomial as the winner rather than erroring.
    sigFit = [];
    sigRMSE = inf;
    try
        [sigFit,sigRMSE] = fitSigmoid(controlValues,sensorValues);
    catch
        % Leave sigFit empty and sigRMSE as inf
    end


    % Keep whichever fit has the smaller residual RMS
    if polyGof.rmse <= sigRMSE
        laserFit.sensorOnControl = polyFit;
        laserFit.fitType = 'poly3';
        laserFit.rmse = polyGof.rmse;
    else
        laserFit.sensorOnControl = sigFit;
        laserFit.fitType = 'sigmoid';
        laserFit.rmse = sigRMSE;
    end

    % Store the raw data and the date alongside the fit so the structure is self-contained.
    % fittedSensorValues is the kept fit evaluated at the control voltages: a denoised curve
    % that laser_mW_to_control interpolates, so it does not need to re-run any fit.
    laserFit.controlValues = controlValues;
    laserFit.sensorValues = sensorValues;
    laserFit.fittedSensorValues = laserFit.sensorOnControl(controlValues);
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
        title(sprintf('%s fit (RMS = %0.3g)', laserFit.fitType, laserFit.rmse))
    end

end % fitLaserPowerCurve



function [sigFit,rmse] = fitSigmoid(controlValues,sensorValues)
    % Fit a four parameter logistic sigmoid: a + b ./ (1 + exp(-c*(x - d)))
    % a is the lower asymptote, b the range, c the steepness, and d the midpoint.

    sigModel = fittype('a + b ./ (1 + exp(-c*(x - d)))', ...
                        'independent', 'x', ...
                        'coefficients', {'a','b','c','d'});

    % Start points and bounds derived from the data. b and c are kept positive so the fit
    % is a monotonically increasing sigmoid.
    controlRange = max(controlValues) - min(controlValues);
    startPoint = [min(sensorValues), ...                     % a: lower asymptote
                  max(sensorValues)-min(sensorValues), ...   % b: range
                  4/controlRange, ...                        % c: steepness
                  mean(controlValues)];                      % d: midpoint

    opts = fitoptions('Method', 'NonlinearLeastSquares', ...
                        'StartPoint', startPoint, ...
                        'Lower', [-inf, 0, 0, -inf]);

    [sigFit,gof] = fit(controlValues,sensorValues,sigModel,opts);
    rmse = gof.rmse;

end % fitSigmoid
