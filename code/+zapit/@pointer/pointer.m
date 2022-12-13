classdef pointer < handle
    
    % pointer
    %
    % Drives a galvo-based photo-stimulator. Scan lens doubles as an
    % objective to scan the beam over the sample and also to form an
    % image via a camera.
    %
    %
    % Rob Campbell - 2020/2021
    % Maja Skretowska - 2021/2022

    
    properties

        % TODO -- The following properties need to be in a settings structure
        % 0/0 volts on DAQ corresponds to the middle of the image
        invertX = true
        invertY = true
        flipXY % TODO -- should add this but only once everything else is working
        voltsPerPixel = 2.2E-3 %TODO -- HARDCODED
        micsPix = 19.3 %Measured this %TODO -- HARDCODED
        
        % Properties related to where we stimulate
        transform
        config % Object of class zapit.config

        
        % behavioural task properties
        coordsLibrary
        newpoint
        topUpCall
        rampDown % Not used
        chanSamples
        topCall = 1;
        freqLaser
        numSamplesPerChannel
        sampleRate
    end


    properties (Hidden)
        % Handles for plot elements
        hFig
        hImAx
        hImLive
        hLastPoint % plot handle with location of the last clicked point

        axRange
        imSize % Size of the displayed image

        % NI DAQmx
        hTask
        AIrange = 10 % +/- this many volts

        % Camera and image related
        cam % camera object goes here


    end
    
    
    methods
        function obj = pointer
            % Constructor
            disp('STARTING BEAMPOINTER')
            obj.cam = zapit.camera(2); % TODO -  Hard-coded selection of camera ID
            
            % Connect to camera
            imSize = obj.cam.vid.ROIPosition;
            obj.imSize = imSize(3:4);

            obj.cam.exposure = 3000; % TODO - HARDCODED
            

            % TODO - put figure creation in a method
            % Make the figure window
            obj.hFig = figure(7824);
            obj.hFig.NumberTitle='off';
            obj.hImAx=axes(obj.hFig);
            
            obj.hImLive = image(zeros(obj.imSize),'Parent',obj.hImAx);
            % Set up a callback function to run each time the user clicks on the axes
            obj.hImLive.ButtonDownFcn = @obj.pointBeamToLocationInImage;
            
            colormap gray
            axis tight equal
            
            obj.cam.vid.FramesAcquiredFcn = @obj.dispFrame;
            obj.cam.vid.FramesAcquiredFcnCount=1; %Run frame acq fun every N frames
            obj.cam.startVideo;
            
            % Overlay an invisible red circle
            hold on
            obj.hLastPoint = plot(nan,nan,'or','MarkerSize',8,'LineWidth',1);
            hold off
            
            
            
            % TODO - Put connection to DAQ in a method
            obj.hTask = dabs.ni.daqmx.Task('beamplacer'); % create a task that lives in the plot axes
            obj.hTask.createAOVoltageChan('Dev2', 0:2, [], -obj.AIrange, obj.AIrange); % # TODO -- hardcoded!
            
            
            % TODO -- we should presumbably implement the following again?
            % When window closes we disconnect from the DAQ
            % obj.hFig.CloseRequestFcn = @obj.figClose;
            
            
            obj.zeroScanners

            
            % load configuration files
            [fname,fpath] = uigetfile('*.yaml','Pick a config file');
            pathToConfig = fullfile(fpath,fname);
            obj.config = zapit.config(pathToConfig);
        end
        
        
        
        function delete(obj)
            fprintf('Shutting down optostim software\n')
            obj.cam.stopVideo;
            delete(obj.cam)
            delete(obj.hFig)
            delete(obj.hTask)
        end
        
        
        
        function zeroScanners(obj)
            % Zero the scanners and also turn off the laser
            % TODO - rename method or create a different method to zero laser

            % TODO - running this does not update the plot
            obj.hTask.writeAnalogData([0,0,0])
        end
        
        
        function varargout = runAffineTransform(obj, OUT)
            % TODO - refactor
            % method running a transformation of x-y beam position into pixels
            % in camera
            
            % it can be run repeatedly with each new mouse and it doesn't
            % require scaling from the start (new transformation matrices
            % are added on top of existing ones in function pixelToVolt)
            
            % runs affine transformation
            tform = fitgeotrans(OUT.targetPixelCoords,OUT.actualPixelCoords,'similarity');
            
            obj.transform = tform;

            if nargout>0
                varargout{1} = tform;
            end
            
        end
        

        function obj = makeChanSamples(obj, freqLaser, laserAmplitude)
            % Prepares voltages for each inactivation site
            %
            % pointer.makeChanSamples(freqLaser, laserAmplitude)
            %
            %
            % Inputs
            % freqLaser - Frequency of inactivation, amplitude of voltage fed to laser
            % laserAmplitude -
            %
            %
            % Outputs
            % None but the chanSamples property matrix is updated.
            
            % you can later check if everything works if you plot figure at the end
            plotFigure = 0;
            
            obj.sampleRate = 1000;                      % samples in Hz
            obj.freqLaser = freqLaser;                  % full cycles in Hz
            numHalfCycles = 4;                          % arbitrary, no of half cycles to buffer
            obj.numSamplesPerChannel = obj.sampleRate/obj.freqLaser*(numHalfCycles/2);
            
            % TODO -- hardcoded stuff
            %  digitalAmplitude = 0.72;                       % old version with analog obis settings and without an arduino (gives 3.8 mW power)
            digitalAmplitude = 1.5; % fed into Arduino
            
            % find edges of half cycles
            cycleEdges = linspace(1, obj.numSamplesPerChannel, numHalfCycles+1);
            edgeSamples = ceil(cycleEdges(1,:));
            
            
            % make up samples for scanner channels
            % (coordsLibrary is already in a volt format)
            scanChnl = zeros(obj.numSamplesPerChannel,2,size(obj.coordsLibrary,2)); % matrix for each channel
            %             lghtChnl = zeros(obj.numSamplesPerChannel,2,2);                         % 1st dim is samples, 2nd dim is channel, 3rd dim is conditions
            
            %% make up scanner volts to switch between two areas
            for inactSite = 1:size(obj.coordsLibrary, 1)    % CHECK if it really is the first dim
                
                % inactSite gets column from the coordinates library
                xVolts = obj.coordsLibrary(inactSite,1,:);
                yVolts = obj.coordsLibrary(inactSite,2,:);
                for cycleNum = 1:(length(edgeSamples)-1)
                    segStart = edgeSamples(cycleNum);
                    segStop = edgeSamples(cycleNum+1);
                    siteIndx = rem(cycleNum+1,2)+1;         % check whether it's an odd (rem = 1) or even (rem = 0) number and then add 1 to get an index
                    scanChnl(segStart:segStop,1,inactSite) = xVolts(siteIndx);
                    scanChnl(segStart:segStop,2,inactSite) = yVolts(siteIndx);
                end
                
            end
            
            %% make up samples for laser and masking light channels
            
            %masking light is always on, laser is on only when LaserOn == 1
            anlgOut = (-cos(linspace(0,numHalfCycles*2*pi,obj.numSamplesPerChannel)) + 1)*laserAmplitude;
            digOut = ones(1,obj.numSamplesPerChannel)*digitalAmplitude;
            digOut([edgeSamples,edgeSamples(1:end-1)+1])= 0;% allow 2 samples around halfcycle change to be 0 (in case scanners are not in the right spot
            
            for lightCond = 0:1
                % if light condition is 0, then laser samples become 0 too
                lghtChnl(:,1,lightCond+1) = anlgOut*lightCond;              % analog laser output
                lghtChnl(:,2,lightCond+1) = digOut*(5/digitalAmplitude);    % analog masking light output
                lghtChnl(:,3,lightCond+1) = digOut*lightCond;               % digital laser gate
            end
            
            %% make up a figure to visualise what is fed from daq board (optional)
            if plotFigure
                showvisual();
            end
            
            %% save all samples in a structure to access as object property
            obj.chanSamples.scan = scanChnl;
            % x-by-2-by-6, where rows are samples, columns are channels, and 3rd dim
            % is which area is selected
            
            obj.chanSamples.light = lghtChnl;
            % x-by-3-by-2, where rows are samples, columns are channels, and 3rd dim
            % is whether laser is off or on
            
            %% visualization of channel samples
            function showvisual()
                % TODO -- this is weird nested function that should be somewhere else.
                xAxis = [1:obj.numSamplesPerChannel];
                
                figure(22) % TODO -- improve figure ID. This can cause a bug
                clf
                subplot(4,1,1)
                % inactivation structure
                %                 hold off
                %                 scatter(xAxis, ones(1,obj.numSamplesPerChannel),'.')
                %                 hold on
                %                 plot(xAxis,freqInact,'r');
                %                 for ii = cycleEdges(1,:)
                %                     plot([ii ii],[0 2],'g-','LineWidth',1)
                %                 end
                %                 title('inactivation structure')
                
                subplot(4,1,2)
                % analog volt output for 1st area to 1st scanner mirror
                plot(xAxis,scanChnl(:,1,1),'.','MarkerSize',10);
                hold on
                for ii = cycleEdges(1,:)
                    plot([ii ii],[min(scanChnl(:,1,1)) max(scanChnl(:,1,1))],'g-','LineWidth',1)
                end
                title('analog output to scan mirrors')
                ylabel('area')
                
                subplot(4,1,3)
                % analog volt output to laser and masking light
                plot(xAxis,anlgOut,'.','MarkerSize',10);
                hold on
                for ii = cycleEdges(1,:)
                    plot([ii ii],laserAmplitude*[0 2],'g-','LineWidth',1)
                end
                title('analog output to laser')
                ylabel('amplitude')
                
                subplot(4,1,4)
                % digital volt output to laser
                plot(xAxis, digOUT,'.','MarkerSize',10);
                hold on
                for ii = cycleEdges(1,:)
                    plot([ii ii],digitalAmplitude*[0 1],'g-','LineWidth',1)
                end
                title('digital output to laser')
                ylabel('on/off')
                xlabel('samples generated at 5000 Hz rate')
            end
            
        end
        
        
        
        function sendSamples(obj, new_trial)
            % take coordinates of two points[x and y Coords], and exchange laser between
            % them at freqLaser for pulseDuration seconds, locking it at a given point for tOpen ms
            % inputs: obj.chanSamples,
            %         CoordNum,
            %         LaserOn
            %         powerOption - if 1 send 2 mW, if 2 send 4 mW (mean)
            % output: nothing. The function just sends correct samples to
            % the pointer
            CoordNum = new_trial.area;
            LaserOn = new_trial.LaserOn;
            trialPower = new_trial.powerOption;
            taskName = 'flashAreas';
            
            if ~strcmp(obj.hTask.taskName, taskName);
                % close the old task used for logging points and open a new one with the
                % right properties. hTask is an object that 'rests' on the NI
                % board and gives it information to play back once command start
                % arrives. It contains a clock and sampled voltages.
                createNewTask(obj, taskName);
            end
            
            % update coordinate parameters/channel samples
            voltChannel(:,1:2) = obj.chanSamples.scan(:,:,CoordNum);
            voltChannel(:,3:4) = trialPower * obj.chanSamples.light(:,[3 2],LaserOn+1);  % if laseron = 0, no inactivation
            % for now, I exchanged the analog output 1 with the digital 3
            % so that we have a square waveform (until we figure out how to
            % get higher output wattage from obis laser)
            
            % write voltage samples onto the task
            obj.hTask.writeAnalogData(voltChannel);
            % start the execution of the new task
            obj.hTask.start;
        end
        
        
        
        function createNewTask(obj, taskName)
            
            devName = 'Dev2';
            
            % channel 0 = x Axis
            % channel 1 = y Axis
            % channel 2 = analog laser
            % channel 3 = masking light
            %             % channel 4 = digital laser gating
            % channel PFI0 = digital trigger
            
            % output channel params
            chanIDs = [0 1 2 3];
            sampleRate = obj.sampleRate;                        % set in makeChanSamples
            sampleMode = 'DAQmx_Val_ContSamps';
            sampleClockSource = 'OnboardClock';
            numSamplesPerChannel = obj.numSamplesPerChannel;    % set in makeChanSamples
            
            % trigger setup
            dTriggerSource = 'PFI0';
            dTriggerEdge = 'DAQmx_Val_Rising';
            
            % Execute a cleanup function (below)
            cleanUpFunction;
            
            %% Create the inactivation task
            % taskName is defined in the previous function ('flashAreas')
            obj.hTask = dabs.ni.daqmx.Task(taskName);
            
            % Set output channels
            obj.hTask.createAOVoltageChan(devName, chanIDs);
            
            
            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hTask.cfgSampClkTiming(sampleRate, sampleMode, numSamplesPerChannel, sampleClockSource);
            obj.hTask.cfgOutputBuffer(numSamplesPerChannel);
            
            % allow sample regeneration
            obj.hTask.set('writeRegenMode', 'DAQmx_Val_AllowRegen');
            obj.hTask.set('writeRelativeTo','DAQmx_Val_FirstSample');
            
            % Configure the trigger
            obj.hTask.cfgDigEdgeStartTrig(dTriggerSource, dTriggerEdge);
            
            %% cleanup function copied from example
            function cleanUpFunction
                if exist('obj.hTask')
                    fprintf('Cleaning up DAQ task\n');
                    obj.hTask.stop;    % Calls DAQmxStopTask
                    delete(obj.hTask); % The destructor (dabs.ni.daqmx.Task.delete) calls DAQmxClearTask
                else
                    fprintf('this task is not available for cleanup\n')
                end
            end
        end
        
        
        
        function stopInactivation(obj)
            % called at the end of a trial
            % send 0 Volts if sample generation has already been triggered
            % and stops task
            
            try
                % try-end used because overwriting buffer before trigger
                % comes (e.g. run abort before inactivation) may throw errors
                
                voltChannel(:,1:2) = obj.chanSamples.light(:,[1 1],1); % just zeros
                voltChannel(:,3:4) = obj.chanSamples.light(:,[1 1],1); % just zeros
                
                obj.hTask.writeAnalogData(voltChannel);
                
                % pause to wait for 0s to be updated in the buffer and
                % generated before closing
                pause(1);
            end
            
            % stop task and send to pre-generation stage, allowing to write
            % next trial samples without conflicts
            obj.hTask.abort
        end
        
        

        
        function topUpBuffer(obj)
            % NOT USED FOR NOW (TODO -- really? topCall is true by default)
            if logical(obj.topCall)
                disp('Top Up')
                obj.hTask.writeAnalogData(obj.voltChannel);
            end
        end
        
        
        
        function out = getLaserPosAccuracy(obj, XYdata)
            % Find the coords of the beam location and compare to
            % the desired location. Returns results to screen if no
            % outputs. Otherwise returns a structure and does not
            % print to screen.
            
            %% find centre of laser field after averaging a few frames

            % Get images
            nFrames = 5;
            tFrames = obj.hImLive.CData;
            lastFrameAcquired = obj.cam.vid.FramesAcquired;

            while size(tFrames,3) < nFrames
                currentFramesAcquired = obj.cam.vid.FramesAcquired;
                if currentFramesAcquired > lastFrameAcquired
                    tFrames(:,:,end+1) = obj.hImLive.CData;
                    lastFrameAcquired = currentFramesAcquired;
                end
            end

            % Binarize
            for ii = 1:nFrames
                tFrame = tFrames(:,:,ii);
                tFrames(:,:,ii) = tFrames(:,:,ii) > (max(tFrame(:))*0.5) ;
            end

            BWmean = mean(tFrames,3);

            BW = BWmean>(max(BWmean(:))*0.7);
            BWc = regionprops(bwareaopen(BW,50),'Centroid');
            
            out = [];
            % Bail out if we find no or multiple points
            if length(BWc) ~= 1
                fprintf('Expected to find one point. Found %d points\n', length(BWc))
                return
            end
            
            %% report to screen or return as a structure
            if nargout==0
                fprintf('Laser at x = %d y = %d\n', round(BWc.Centroid))
                fprintf('User point at x = %d y = %d\n', ...
                    round(obj.hLastPoint.XData), round(obj.hLastPoint.YData))
                
                fprintf('Error: x = %0.2f um  y = %0.1f um\n', ...
                    abs(obj.hLastPoint.XData-BWc.Centroid(1)) * obj.micsPix, ...
                    abs(obj.hLastPoint.YData-BWc.Centroid(2)) * obj.micsPix)
            elseif nargout>0
                if nargin<2
                    out.targetPixelCoords = [obj.hLastPoint.XData, obj.hLastPoint.YData];
                else
                    out.targetPixelCoords = XYdata;
                end

                % Return
                out.actualPixelCoords = BWc.Centroid;
                out.error = out.targetPixelCoords-out.actualPixelCoords;
                out.absErrorMicrons = abs(out.error) * obj.micsPix;
            end
            
        end
        
        
        
        function pointBeamToLocationInImage(obj,~,~)
            % This callback function obtains the mouse position in the
            % image and uses this to point the scanners to this location.
            
            
            % Get the current mouse position (at the clicked location) and use it
            % to place a point there and display coords to the axes title.
            pos = obj.hImAx.CurrentPoint;
            xPos = pos(1,1);
            yPos = pos(1,2);
            
            % convert to voltage values to send to scanners
            [xVolts, yVolts] = pixelToVolt(obj, xPos, yPos);
            
            obj.hLastPoint.XData = xPos;
            obj.hLastPoint.YData = yPos;
            
            %SEND TO SCANNERS:
            obj.hTask.writeAnalogData([xVolts, yVolts, 3]); % send beam to this location
            
            msg = sprintf('X=%0.2f (%0.1f V) Y=%0.2f (%0.1f V)',...
                xPos, xVolts, yPos, yVolts);
            set(get( obj.hImAx,'Title'),'String',msg)
            
        end
        
        
        
        function [xVolts, yVolts] = pixelToVolt(obj, pixelColumn, pixelRow)
            % Converts pixel position to voltage value to send to scanners
            %
            % function [xVolts, yVolts] = pixelToVolt(obj, pixelColumn, pixelRow)
            %
            % Purpose
            % Converts pixel coordinates to volt values for scanner mirrors
            % taking into account created transformation matrices (infinite
            % number of those allowed).
            %
            % This function is important and used every time the laser is
            % pointed to a location. Called in: pointBeamToLocationInImage,
            % getAreaCoordinates and logPoints
            %
            %
            % Inputs
            % Pixel row and column


            if ~isempty(obj.transform)
                % TODO -- WHERE THE HELL IS transformPointsInverse???
                [pixelColumn, pixelRow] = transformPointsInverse(obj.transform, pixelColumn, pixelRow);
            end
            
            
            xVolts = (pixelColumn - (obj.imSize(1)/2)) * obj.voltsPerPixel;
            yVolts = (pixelRow    - (obj.imSize(2)/2)) * obj.voltsPerPixel;
            
            if obj.invertX
                xVolts = xVolts*-1;
            end

            if obj.invertY
                yVolts= yVolts*-1;
            end
            
        end
        
        
        
        function dispFrame(obj,~,~)
            % This callback is run every time a frame has been acquired
            if obj.cam.vid.FramesAvailable==0
                return
            end
            
            tmp=obj.cam.getLastFrame;
            
            obj.hImLive.CData = tmp;
            drawnow
            obj.cam.flushdata
        end
        
        
        
        %% power-test methods
        % to test power, call obj.testPower, rest of instructions are in the program.
        % remember to update the bridge first before runnig the program -- TODO -- what does that mean?
        
        function laserPower = testPower(obj)
            % start new task
            
            % TODO -- refactor to model/view
            % TODO -- what is power 1 or 2?
            trialPower = input(char("what's the power to use (1 or 2)?"));
            
            
            obj.hFig;
            title('find a point beyond power meter');
            waitforbuttonpress
            while obj.hFig.SelectionType ~= "alt"
                figure(obj.hFig);
                Point2 = obj.hImAx.CurrentPoint([1 3])';
                waitforbuttonpress;
            end
            
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
                    obj.hTask.stop;
                else
                    marker_color = [1 (1-(laserPower(3,ii)/5)) 1];
                    hold on;
                    plot(obj.hImAx, laserPower(1,ii), laserPower(2, ii), 'o', ...
                        'MarkerEdgeColor', marker_color, 'MarkerFaceColor', marker_color);
                end
            end
            
            
            saveOption = input('save?');
            whichAnimal = input('whichAnimal', 's');
            if saveOption
                % TODO -- hardcoded
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
                
                if ~strcmp(obj.hTask.taskName, taskName)
                    createTestTask(obj);
                else
                    obj.hTask.abort;
                    pause(0.3);
                end
                
                % update coordinate parameters/channel samples
                [lightChnl, scanChnl] = makeSamples(obj, Point2, laserPower);
                voltChannel(:,1:2) = scanChnl;
                voltChannel(:,3) = trialPower*lightChnl;
                
                % send voltage to ni daq
                obj.hTask.writeAnalogData(voltChannel);
                obj.hTask.start;
                
                
                
                %%
                
                % inside functions of the inside function
                function  [lightChnl, scanChnl] = makeSamples(obj, Point2, laserPower)
                    % inputs: frequency of inactivation, amplitude of voltage fed
                    % to laser
                    % output: obj.chanSamples (matrix of channel samples for each inactivation)
                    numHalfCycles = 4;                          % arbitrary, no of half cycles to buffer
                    digitalAmplitude = 1.5; % fed into Arduino TODO -- remove this
                    
                    
                    % find edges of half cycles
                    cycleEdges = linspace(1, obj.numSamplesPerChannel, numHalfCycles+1);
                    edgeSamples = ceil(cycleEdges(1,:));
                    
                    
                    % make up samples for scanner channels
                    % (coordsLibrary is already in a volt format)
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
                    
                    
                end
            end
            function createTestTask(obj)
                devName = 'Dev2';
                taskName = 'testPower';
                % channel 0 = x Axis
                % channel 1 = y Axis
                % channel 2 = analog laser
                
                % output channel params
                chanIDs = [0 1 2];
                obj.freqLaser = 40;
                sampleRate = 1000;                        % set in makeChanSamples
                obj.sampleRate = sampleRate;
                sampleMode = 'DAQmx_Val_ContSamps';
                sampleClockSource = 'OnboardClock';
                numHalfCycles = 4;
                numSamplesPerChannel = sampleRate/obj.freqLaser*(numHalfCycles/2);    % set in makeChanSamples
                obj.numSamplesPerChannel = numSamplesPerChannel;
                
                % Execute a cleanup function (below)
                cleanUpFunction;
                
                
                
                %% Create the inactivation task
                % taskName is defined in the previous function ('flashAreas')
                obj.hTask = dabs.ni.daqmx.Task(taskName);
                
                % Set output channels
                obj.hTask.createAOVoltageChan(devName, chanIDs);
                
                
                % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
                obj.hTask.cfgSampClkTiming(sampleRate, sampleMode, numSamplesPerChannel, sampleClockSource);
                obj.hTask.cfgOutputBuffer(numSamplesPerChannel);
                
                % allow sample regeneration
                obj.hTask.set('writeRegenMode', 'DAQmx_Val_AllowRegen');
                obj.hTask.set('writeRelativeTo','DAQmx_Val_FirstSample');
                
                
                
                
                %% cleanup function copied from example
                function cleanUpFunction
                    if exist('obj.hTask')
                        fprintf('Cleaning up DAQ task\n');
                        obj.hTask.stop;    % Calls DAQmxStopTask
                        delete(obj.hTask); % The destructor (dabs.ni.daqmx.Task.delete) calls DAQmxClearTask
                    else
                        fprintf('this task is not available for cleanup\n')
                    end
                end
            end
            
        end
        
        function laserPower = findLaserRange(obj)
            ii = 0;
            condition = 1;
            while condition
                try
                    ii = ii + 1;
                    % press left (without waiting for right)
                    figure(obj.hFig);
                    waitforbuttonpress
                    laserPower([1 2], ii) = obj.hImAx.CurrentPoint([1 3])';
                    laserPower(3, ii) = input(char("what's the power (if you want to finish)"));
                    
                    if laserPower(3, ii) == -1
                        condition = 0;
                        obj.hTask.stop;
                    else
                        marker_color = [1 (1-(laserPower(3,ii)/3)) 1];
                        hold on;
                        plot(obj.hImAx, laserPower(1,ii), laserPower(2, ii), 'o', ...
                            'MarkerEdgeColor', marker_color, 'MarkerFaceColor', marker_color);
                    end
                catch
                    return
                end
            end
        end
        
        function plotLaserRange(obj, laserPower)
            dotNum = size(laserPower, 2);
            laserPower = laserPower(:, laserPower(3,:) ~= -1);
            powerMean = mean(laserPower(3,laserPower));
            laserPower(3,:) = and(laserPower(3,:)>(0.95*powerMean), laserPower(3,:)<(1.05*powerMean));
            for ii = 1:dotNum
                marker_color = [1 (laserPower/2) 1];
                hold on;
                plot(obj.hImAx, laserPower(1,ii), laserPower(2, ii), 'o', ...
                    'MarkerEdgeColor', marker_color, 'MarkerFaceColor', marker_color, 'MarkerSize', 1);
            end
        end
    end
end
