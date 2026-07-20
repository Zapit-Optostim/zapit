function generateLaserCalibrationCurve(obj,minMax)
    % Calibrate the laser: determine the relationship between output and control voltage
    %
    % function laserFit = zapit.pointer.generateLaserCalibrationCurve(minMax)
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
    % Saturation in the curve may be due to the sensor! You may well need to put an ND
    % filter of some sort over the sensor.
    %
    % The zapit.pointer.laserFit property is updated and, optionally, the data are
    % saved to a laserFit.mat file in the user settings directory.
    %
    %
    % Inputs [optional]
    % minMax - [minValueToTest, maxValueToTest] These are the minimum and maximum control
    %           values to use. By default these come from the settings file that is
    %           accessible via zapit.pointer.settings.
    %
    % Outputs
    % none
    %
    % Rob Campbell - SWC 2022
    %
    % See also:
    % zapit.utils.fitLaserPowerCurve
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
    valsToTest = minMax(1):0.025:minMax(2);
    sensorVals = zeros(size(valsToTest));

    % Run
    if ~obj.simulated
        nValsToMeasure = 4; % Obtain this many values and take a average this many values
    else
        nValsToMeasure = 1;
    end

    for ii = 1:length(valsToTest)
        if mod(ii,10)==0
            fprintf('%d/%d\n',ii,length(valsToTest))
        end
        obj.setLaserPowerControlVoltage(valsToTest(ii))

        tmp = zeros(1,nValsToMeasure);
        for jj=1:nValsToMeasure
            tmp(jj) = obj.DAQ.readAnalogData();
            if ~obj.simulated
                pause(0.025)
            end
        end

        sensorVals(ii) = mean(tmp);
    end

    % Tidy up
    obj.setLaserPowerControlVoltage(0)


    % If we ran simulated mode we will make up some values
    if ~obj.simulated
        sensorVals = sensorVals';
    else
        sensorVals = (0.2*valsToTest.^2 + 2*valsToTest + sensorVals*0.21);
    end


    valsToTest = valsToTest';

    %%
    % Fit and plot the measured curve. This is done in a separate function so it can be
    % unit tested without hardware. The returned structure is complete, so we can assign
    % it to the laserFit property in a single line.
    laserFit = zapit.utils.fitLaserPowerCurve(valsToTest, sensorVals);

    obj.laserFit = laserFit;

    %%
    % Optionally save the fit to disk. Simulated runs are non-interactive and never save.
    if ~obj.simulated
        reply = input('Fit applied. Also save this laser fit to disk? [y/N] ', 's');
        if ~isempty(reply) && lower(reply(1))=='y'
            obj.saveLaserFit
        else
            fprintf('Not saving laser fit\n')
        end
    end
