function generateLaserCalibrationCurve(obj,minMax)
    % Calibrate the laser
    %
    % function laserFit = generateLaserCalibrationCurve(obj,minMax)
    %
    % Purpose
    % Calibrate the laser
    % Connect AI0 to the photodiode. Point laser at photodiode.
    % Run this function and get a curve.
    % Data go to laserFit property
    %
    % Inputs
    % minMax - [minValueToTest, maxValueToTest] by default it comes from props of object
    %
    %
    % Rob Campbell - SWC 2022

    if nargin<2
        minMax = obj.laserMinMaxControl;
    end

    % Connect to DAQs
    obj.DAQ.connectUnclockedAO
    obj.DAQ.stopAndDeleteAITask
    obj.DAQ.connectUnclockedAI(0)


    % Generate vectors for testing
    valsToTest = minMax(1):0.1:minMax(2);
    sensorVals = zeros(size(valsToTest));

    % Run
    nValsToMeasure = 8; %Average this many values
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

    laserFit.controlOnSensor = fit(valsToTest,sensorVals,'poly3');
    laserFit.sensorOnControl = fit(sensorVals,valsToTest,'poly3');


    figure(123)
    subplot(1,2,1)
    plot(laserFit.controlOnSensor,valsToTest,sensorVals)
    ylim([0,12])
    grid on
    xlabel('Control value')
    ylabel('Analog voltage')

    subplot(1,2,2)
    plot(laserFit.sensorOnControl,sensorVals,valsToTest)
    grid on
    ylabel('Control value')
    xlabel('Analog voltage')




    obj.laserFit = laserFit;
    obj.laserFit.dateMade = now;
    obj.laserFit.sensorValues = sensorVals;
    obj.laserFit.controlValues = valsToTest;

    % TODO -- we will save to disk right here but this needs to be optional
    % For now it's OK to do this just to get it all working
    obj.saveLaserFit

