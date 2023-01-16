function generateLaserCalibrationCurve(obj,minMax)
    % Calibrate the laser: determine the relationship between output and control voltage
    %
    % function laserFit = zapit.pointer.generateLaserCalibrationCurve(obj,minMax)
    %
    % Purpose
    % Measure the relationship between control voltage laser output using an uncalibrated
    % photodiode. This curve can then be easily used to generate a value in mW once we
    % have measured the number of mW at the maximum and minimum values. The fit is used
    % by zapit.pointer.laser_mW_to_control in order to convert a desired value in mW to
    % a control voltage that can be sent to the laser. 
    %
    % Instructions
    % * Connect AI0 to the photodiode. 
    % * Turn on the photodiode, place it under the objective and point the beam at it. 
    % * Run this function and get a curve.
    % * Data are stored in the laserFit property
    %
    % The zapit.pointer.laserFit property is updated and, optionally, the data are 
    % saved to a laserFit.mat file in the user settings directory.
    %
    %
    % Inputs [optioanl]
    % minMax - [minValueToTest, maxValueToTest] These are the minimum and maximum control 
    %           values to use. By default these come from the settings file that is accesible
    %           via zapit.pointer.settings. 
    %
    % Outputs
    % none
    %
    % Rob Campbell - SWC 2022
    %
    % See also:
    % zapit.pointer.saveLaserFit
    % zapit.pointer.loadLaserFit
    % zapit.pointer.laser_mW_to_control


    if nargin<2
        minMax = obj.settings.laser.laserMinMaxControlVolts;
    end

    % Connect to DAQ
    obj.DAQ.connectUnclockedAO
    obj.DAQ.stopAndDeleteAITask
    obj.DAQ.connectUnclockedAI(0) % To read data from AI0


    % Generate vectors for testing
    valsToTest = minMax(1):0.1:minMax(2);
    sensorVals = zeros(size(valsToTest));

    % Run
    if ~obj.simulated
        nValsToMeasure = 8; % Obtain this many values and take a average this many values
    else
        nValsToMeasure = 1;
    end

    for ii = 1:length(valsToTest)
        obj.DAQ.setLaserPowerControlVoltage(valsToTest(ii))

        tmp = zeros(1,nValsToMeasure);
        for jj=1:nValsToMeasure
            tmp(jj) = obj.DAQ.hAI.readAnalogData();
        end

        sensorVals(ii) = mean(tmp);
    end

    % Tidy up
    obj.DAQ.setLaserPowerControlVoltage(0)

    %%
    % Fit a third order polynomial: photodiode voltage as a function of control voltage
    % This fit is mainly for display purposes, we don't actually use it directly.
    % see zapit.pointer.laser_mW_to_control

    % If we ran simulated mode we will make up some values
    if ~obj.simulated
        sensorVals = sensorVals';
    else 
        sensorVals = (2*valsToTest + sensorVals');
    end

    valsToTest = valsToTest';

    laserFit.sensorOnControl = fit(valsToTest,sensorVals,'poly3');


    %% 
    % plot the data
    fig = zapit.utils.focusNamedFig('lasercalibrate');
    clf
    plot(laserFit.sensorOnControl,valsToTest,sensorVals)
    ylim([0,12])
    grid on
    xlabel('Laser Control Value [V]')
    ylabel('Photodiode Signal [V]')


    %%
    % Add the data to the laserFit property
    obj.laserFit = laserFit;
    obj.laserFit.dateMade = now;
    obj.laserFit.sensorValues = sensorVals;
    obj.laserFit.controlValues = valsToTest;

    % TODO -- we will save to disk right here but this should eventually be done after a confirmatio
    % For now it's OK to do this just to get it all working
    if ~obj.simulated
        obj.saveLaserFit
    end
