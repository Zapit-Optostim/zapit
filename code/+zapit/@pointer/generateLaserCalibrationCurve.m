function laserFit = generateLaserCalibrationCurve(obj,minMax)
    % Calibrate the laser
    %
    % function laserFit = generateLaserCalibrationCurve(obj,minMax)
    %
    % Purpose
    % Calibrate the laser
    % Connect AI0 to the photodiode. Point laser at photodiode.
    % Run this function and get a curve.
    %
    % Inputs
    % minMax - [minValueToTest, maxValueToTest] by default this is [0,5]
    %
    % Outputs
    % fit objects. One that is sensor as a function of control values and one that is control
    % value as a function of sensor. The idea being that we can rescale the control values
    % by actually making a measurement of max and min power. Then do:
    % intendedPower -> my_Sensor_value
    % controlVoltage = laserFit.sensorOnControl(my_Sensor_value)
    % Then we know the control volage to use.
    %
    %
    % Rob Campbell - SWC 2022

    if nargin<2
        minMax = [0,5];
    end

    % Connect to DAQs
    obj.DAQ.connectUnclockedAO
    obj.DAQ.stopAndDeleteAITask
    obj.DAQ.connectUnclockedAI(0)


    % Generate vectors for testing
    valsToTest = minMax(1):0.1:minMax(2);
    sensorVals = zeros(size(valsToTest));

    % Run
    nValsToMeasure = 4; %Average this many values
    for ii = 1:length(valsToTest)
        obj.DAQ.setLaserPowerControlVoltage(valsToTest(ii))

        tmp = zeros(1,nValsToMeasure);
        for jj=1:nValsToMeasure
            tmp(jj) = obj.DAQ.hAI.readAnalogData;
        end

        sensorVals(ii) = mean(tmp);
    end

    % Tidy
    obj.DAQ.setLaserPowerControlVoltage(0)


    % Plot TODO -- tidy
    valsToTest = valsToTest';
    sensorVals = sensorVals';

    figure(123)
    subplot(1,2,1)
    laserFit.controlOnSensor = fit(valsToTest,sensorVals,'poly3');

    plot(laserFit.controlsOnSensor,valsToTest,sensorVals)
    ylim([0,12])
    grid on
    xlabel('Control value')
    ylabel('Analog voltage')

    subplot(1,2,2)
    laserFit.sensorOnConrtrol = fit(sensorVals,valsToTest,'poly3');
    plot(laserFit.sensorOnControl,sensorVals,valsToTest)
    grid on
    ylabel('Control value')
    xlabel('Analog voltage')

