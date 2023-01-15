function laserPower = testPower(obj)
    %% power-test methods
    % to test power, call obj.testPower, rest of instructions are in the program.
    % remember to update the bridge first before runnig the program.
    %
    % Maja Skretowska - SWC 2021

    
    % start new task
    
    trialPower = input(char("what's the power to use (1 or 2)?"));
    
    
    obj.hFig;
    title('find a point beyond power meter');
    waitforbuttonpress
    while obj.hFig.SelectionType ~= "alt"
        figure(obj.hFig);
        Point2 = obj.hImAx.CurrentPoint([1 3])';
        waitforbuttonpress;
    end % while
    
    title(obj.hImAx, 'ok, recorded');
    
    
    ii = 0;
    condition = 1;
    while condition
        ii = ii + 1;
        % press left (without waiting for right)
        figure(obj.hFig);
        waitforbuttonpress
        laserPower([1 2], ii) = obj.hImAx.CurrentPoint([1 3])';
        
        % send laser between the two places and measure
        startTesting(obj, trialPower, Point2, (laserPower([1,2],ii)));
        laserPower(3, ii) = input(char("what's the power (if you want to finish)"));
        
        if laserPower(3, ii) == -1
            condition = 0;
            obj.DAQ.hAO.stop;
        else
            marker_color = [1 (1-(laserPower(3,ii)/5)) 1];
            hold on;
            plot(obj.hImAx, laserPower(1,ii), laserPower(2, ii), 'o', ..
                'MarkerEdgeColor', marker_color, 'MarkerFaceColor', marker_color);
        end
    end % while
    
    
    saveOption = input('save?');
    whichAnimal = input('whichAnimal', 's');
    if saveOption
        fileName = char(join(['D:\Maja\FSMdata\power_' trialPower '_' string(datetime('now', 'format', 'yyyy-MM-dd-hh-mm')) '_' whichAnimal], ''));
        save(fileName, 'laserPower');
    end
    
    
    % inside functions
    function startTesting(obj, trialPower, Point2, laserPower)
        % take coordinates of two points[x and y Coords], and exchange laser between
        % them at freqLaser for pulseDuration seconds, locking it at a given point for tOpen ms
        % inputs: obj.chanSamples,
        %         CoordNum,
        %         LaserOn
        %         powerOption - if 1 send 2 mW, if 2 send 4 mW (mean)
        % output: nothing. The function just sends correct samples to
        % the pointer
        taskName = 'testPower';
        
        if ~strcmp(obj.DAQ.hAO.taskName, taskName)
            createTestTask(obj);
        else
            obj.DAQ.hAO.abort;
            pause(0.3);
        end
        
        % update coordinate parameters/channel samples
        [lightChnl, scanChnl] = makeSamples(obj, Point2, laserPower);
        voltChannel(:,1:2) = scanChnl;
        voltChannel(:,3) = trialPower*lightChnl;
        
        % send voltage to ni daq
        obj.DAQ.hAO.writeAnalogData(voltChannel);
        obj.DAQ.hAO.start;
        
        
        
        %%
        
        % inside functions of the inside function
        function  [lightChnl, scanChnl] = makeSamples(obj, Point2, laserPower)
            % inputs: frequency of inactivation, amplitude of voltage fed
            % to laser
            % output: obj.chanSamples (matrix of channel samples for each inactivation)
            numHalfCycles = 4;                          % arbitrary, no of half cycles to buffer
            digitalAmplitude = 1.5; % fed into Arduino
            
            
            % find edges of half cycles
            cycleEdges = linspace(1, obj.numSamplesPerChannel, numHalfCycles+1);
            edgeSamples = ceil(cycleEdges(1,:));
            
            
            % make up samples for scanner channels
            % (calibratedPointsInVolts is already in a volt format)
            scanChnl = zeros(obj.numSamplesPerChannel,2); % matrix for each channel
            
            %% make up scanner volts to switch between two areas
            
            % inactSite gets column from the coordinates library
            [xVolts, yVolts] = obj.pixelToVolt([Point2(1), laserPower(1)], [Point2(2), laserPower(2)]);
            
            for cycleNum = 1:(length(edgeSamples)-1)
                segStart = edgeSamples(cycleNum);
                segStop = edgeSamples(cycleNum+1);
                siteIndx = rem(cycleNum+1,2)+1;         % check whether it's an odd (rem = 1) or even (rem = 0) number and then add 1 to get an index
                scanChnl(segStart:segStop,1) = xVolts(siteIndx);
                scanChnl(segStart:segStop,2) = yVolts(siteIndx);
            end
            
            %% make up samples for laser and masking light channels
            lightChnl = ones(1,obj.numSamplesPerChannel)*digitalAmplitude;
            lightChnl([edgeSamples,edgeSamples(1:end-1)+1])= 0;% allow 2 samples around halfcycle change to be 0 (in case scanners are not in the right spot
            
            
        end % makeSamples
    end % startTesting


    function createTestTask(obj)

        obj.DAQ.stopAndDeleteTask
        devName = obj.DAQ.device_ID;
        taskName = 'testPower';

        % channel 0 = x Axis
        % channel 1 = y Axis
        % channel 2 = analog laser
        
        % output channel params
        chanIDs = [0 1 2];
        obj.freqLaser = 40;
        samplesPerSecond = 1000;                        % set in makeChanSamples
        obj.samplesPerSecond = samplesPerSecond;
        sampleMode = 'DAQmx_Val_ContSamps';
        sampleClockSource = 'OnboardClock';
        numHalfCycles = 4;
        numSamplesPerChannel = samplesPerSecond/obj.freqLaser*(numHalfCycles/2);    % set in makeChanSamples
        obj.numSamplesPerChannel = numSamplesPerChannel;
        
        %% Create the inactivation task
        % taskName is defined in the previous function ('flashAreas')
        obj.DAQ.hAO = dabs.ni.daqmx.Task(taskName);
        
        % Set output channels
        obj.DAQ.hAO.createAOVoltageChan(devName, chanIDs);
        
        
        % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
        obj.DAQ.hAO.cfgSampClkTiming(samplesPerSecond, sampleMode, numSamplesPerChannel, sampleClockSource);
        obj.DAQ.hAO.cfgOutputBuffer(numSamplesPerChannel);
        
        % allow sample regeneration
        obj.DAQ.hAO.set('writeRegenMode', 'DAQmx_Val_AllowRegen');
        obj.DAQ.hAO.set('writeRelativeTo','DAQmx_Val_FirstSample');

    end % createTestTask
    
end % testPower