classdef beamPointer < handle
    
    % beamPointer
    %
    % Drives a galvo-based photo-stimulator. Scan lens doubles as an
    % objective to scan the beam over the sample and also to form an
    % image via a camera.
    %
    %
    % Rob Campbell - 2020/2021
    % Maja Skretowska - 2021/2022

    
    properties
        
        % Handles for plot elements
        hFig
        hImAx
        hImLive
        hLastPoint % plot handle with location of the last clicked point
        
        axRange
        
        % NI DAQmx
        hTask
        AIrange = 10 % +/- this many volts
        
        % Camera and image related
        cam % camera object goes here
        imSize
        
        % 0/0 volts on DAQ corresponds to the middle of the image
        invertX = true;
        invertY = false;
        xOffset = 1.8; %TODO -- HARDCODED
        yOffset = 5; %TODO -- HARDCODED
        voltsPerPixel = 2.2E-3; %TODO -- HARDCODED
        
        micsPix = 19.3 %Measured this %TODO -- HARDCODED
        
        transform
        template
        refPoints
        powerOption
        
        % behavioural task properties
        coordsLibrary
        newpoint
        topUpCall
        rampDown
        chanSamples
        topCall = 1;
        freqLaser
        numSamplesPerChannel
        sampleRate
        filename
    end
    
    
    methods
        function obj = beamPointer
            % Constructor
            disp('STARTING BEAMPOINTER')
            obj.cam = zapit.camera(2); % Hard-coded selection of camera ID
            
            % Connect to camera
            imSize = obj.cam.vid.ROIPosition;
            obj.imSize = imSize(3:4);
            obj.cam.src.ExposureTime=50000;
            
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
            
            
            
            
            obj.hTask = dabs.ni.daqmx.Task('beamplacer'); % create a task that lives in the plot axes
            obj.hTask.createAOVoltageChan('Dev2', 0:2, [], -obj.AIrange, obj.AIrange); % changed to Dev2 because that seems to be the name of this device on the new computer
            
            
            % TODO -- we should presumbably implement the following again?
            % When window closes we disconnect from the DAQ
            % obj.hFig.CloseRequestFcn = @obj.figClose;
            
            
            obj.zeroScanners
            
            % load configuration files
            areasFile = input('what is the config file to use for mapping inactivation areas?', 's');
            load(areasFile);
            temp = split(areasFile, '\');
            filename = split(temp{end}, '.');
            obj.filename = filename(1);
            obj.template = template;
            obj.refPoints = refPoints;
            obj.powerOption = powerOption;
        end
        
        
        
        function delete(obj)
            fprintf('Cleaning up object\n')
            obj.cam.stopVideo;
            delete(obj.cam)
            delete(obj.hFig)
            delete(obj.hTask)
        end
        
        
        
        function zeroScanners(obj)
            obj.hTask.writeAnalogData([0,0,0])
        end
        
        
        
        function OUT=logPoints(obj, varargin)
            % log the precision of beam:
            % records how different intended (target) pixel coordinates are
            % from where the beam actually is
            % input (optional): how many points to record (I usually use 7 but can be
            % more or less, at least 5)
            % output: target and actual pixel coordinates
            
            % lower camera illumination for precision
            obj.cam.src.Gain = 1;
            
            if isempty(varargin)
                % if no varargin given, use standard coordinates
                % TODO -- what are these hardcoded numbers??
                nPoints = 9;
                r = [800 800 800 1000 1000 1000 1200 1200 1200; ...
                    400 600 800  400  600  800  400  600  800]';
                
                % change pixel coords into voltage
                [rVolts(:,1), rVolts(:,2)] = obj.pixelToVolt(r(:,1), r(:,2));
                
                for ii=1:nPoints
                    % feed volts into scan mirrors, wait for precise image
                    % without smudges and take position in pixels
                    obj.hTask.writeAnalogData([rVolts(ii,:), 3.3]);
                    pause(1)
                    v(ii)=obj.getLaserPosAccuracy([r(ii,1), r(ii,2)]);
                end
            else
                % same procedure as above, but using points clicked by user
                v = recordPoints(obj.hImAx, obj.hFig, varargin{1});
            end
            
            % save recorded outcoming (intended) and incoming (calculated)
            % pixel coordinates to calculate the offset and transformation
            OUT.targetPixelCoords = cat(1,v(:).targetPixelCoords);
            OUT.actualPixelCoords = cat(1,v(:).actualPixelCoords);
            
            function v = recordPoints(hImAx, hImFig, numPoints)
                for nn = 1:numPoints
                    obj.hTask.writeAnalogData([0 0 0])
                    title(hImAx, string(nn));
                    figure(hImFig)
                    waitforbuttonpress;
                    while hImFig.SelectionType ~= "alt"
                        points(nn,:) = hImAx.CurrentPoint([1 3]);
                        waitforbuttonpress;
                    end
                    v(nn) = obj.getLaserPosAccuracy(points(nn,:));
                end
            end
            
            % change the illumination of the camrea image to high value
            % again
            obj.cam.src.Gain = 25;
            [tform, obj] = runAffineTransform(obj, OUT);
            obj.hTask.writeAnalogData([0 0 0]);
        end
        
      
        
        function [tform, obj] = runAffineTransform(obj, OUT)
            % method running a transformation of x-y beam position into pixels
            % in camera
            
            % it can be run repeatedly with each new mouse and it doesn't
            % require scaling from the start (new transformation matrices
            % are added on top of existing ones in function pixelToVolt)
            
            % runs affine transformation
            tform = fitgeotrans(OUT.targetPixelCoords,OUT.actualPixelCoords,'similarity');
            
            if ~isempty(obj.transform)
                % check if there are existing transformations already
                numTform = size(obj.transform)+1;
                obj.transform(numTform) = tform;
            else
                obj.transform = tform;
            end
            
            
        end
        
        
        
        function opaqueArea = getAreaCoordinates(obj)
            % This method checks what actual pixel coordinates are of the
            % template coordinates kept in session_settings.template, and
            % it stores them in the object's property transformed into
            % volts
            
            % change illumination to get a clearer image of beam position
            obj.cam.src.Gain = 25;
            
            % record points in the screen
            refPoints = obj.refPoints;                        % coordinate references on the mouse skull (bregma and 0,-2 marked with pen)
            template = obj.template;
            hold(obj.hImAx, 'on');
            %             plot(obj.hImAx, refPoints(:,1), refPoints(:,2));
            realPoints = recordPoints(obj.hImAx, obj.hFig); % output columns are x and y coords
            
            % calculate rotation and displacement in pixel coordinates
            [newpoint, rotMat] = coordsRotation(template, refPoints, realPoints);
            
            % ask if you're using the option of an opaque area as additional control for inactivation
            [newpoint, opaqueArea] = checkOpaqueArea(obj, newpoint);
            
            % translate obtained points into volts
            [xVolt, yVolt] = pixelToVolt(obj, newpoint(1,:,1), newpoint(2,:,1)); % newpoint should have an n-by-2 dimension
            [xVolt2, yVolt2] = pixelToVolt(obj, newpoint(1,:,2), newpoint(2,:,2));
            
            
            %% save coords into object and show in the camera image
            coordsLibrary = [xVolt' yVolt'];
            coordsLibrary(:,:,2) = [xVolt2' yVolt2'];
            obj.coordsLibrary = coordsLibrary;
            obj.newpoint = newpoint;
            
            
            hold(obj.hImAx, 'on');
            plot(obj.hImAx, newpoint(1, :, 1), newpoint(2, :, 1), 'o'); % left hemisphere coords
            plot(obj.hImAx, newpoint(1, :, 2), newpoint(2, :, 2), 'o'); % right hemisphere coords
            
            % move laser into each position as a check
            for xx = 1:length(newpoint)
                for yy = 1:2
                    obj.hTask.writeAnalogData([obj.coordsLibrary(xx, 1, yy), obj.coordsLibrary(xx, 2, yy)]);
                    pause(1)
                end
            end
            
            
            
            %% functions
            
            function points = recordPoints(hImAx, hImFig)
                % choose a point by left-click in the figure, and report
                % the choice by right-click (then proceed to next step)
                
                % left-click automatically sends the beam to the location
                % by the callback pointBeamToLocationInImage function
                
                title(hImAx, 'click bregma');
                figure(hImFig)                                  % call figure to make sure matlab is waiting for clicks in the right window
                waitforbuttonpress;
                while hImFig.SelectionType ~= "alt"             % 'alt' is right-click in the figure
                    points(1,:) = hImAx.CurrentPoint([1 3]);    % so until left-click choice is confirmed with right click, you can change location of the beam until precise enough
                    figure(hImFig)
                    waitforbuttonpress;
                end
                figureText = join(['bregma recorded, click ', string(refPoints(:,2)')]);
                title(hImAx,figureText);
                figure(hImFig)
                waitforbuttonpress;
                while hImFig.SelectionType ~= "alt"
                    points(2,:) = hImAx.CurrentPoint([1 3]);
                    figure(hImFig)
                    waitforbuttonpress;
                end
                
                title(hImAx, 'both points recorded');
                plot(hImAx, points(:,1), points(:,2));
            end
            
            function [newpoint,rotMat] = coordsRotation(template, refPoints, points, hImAx)
                % get displacement vector
                translationVector = points(1,:);
                pntZeroed = points-points(1,:);
                
                % get rotation angle
                [th, ro] = cart2pol([pntZeroed(2,1), refPoints(2,1)], [pntZeroed(2,2), refPoints(2,2)]);
                rotationAngle = th(1)-th(2);
                rotMat = rotationMatrix(rotationAngle);
                
                % get rescaling factor
                reScale = ro(1)/ro(2);
                
                % map template onto new angle, scale, and displacement
                newpoint = rotMat*template(:,:,1)*reScale;
                newpoint = newpoint + translationVector';
                newpoint(:,:,2) = rotMat*template(:,:,2)*reScale;
                newpoint(:,:,2) = newpoint(:,:,2) + translationVector';
            end
            
            function rotMat = rotationMatrix(theta)
                rotMat = [cos(theta) -sin(theta); sin(theta) cos(theta)];
            end
            
            function [newpoint, opaqueArea] = checkOpaqueArea(obj, newpoint)
                opaqueArea = input('using an additional opaque area as control? 1 or 0');
                if opaqueArea
                    figure(obj.hFig)
                    title(obj.hImAx, 'find opaque area 1')
                    waitforbuttonpress
                    while obj.hFig.SelectionType ~= "alt"
                        figure(obj.hFig)
                        newpoint(:,end+1,1) =obj.hImAx.CurrentPoint([1 3])';
                        waitforbuttonpress;
                    end
                    title(obj.hImAx, 'find opaque area 2')
                    waitforbuttonpress
                    while obj.hFig.SelectionType ~= "alt"
                        figure(obj.hFig)
                        newpoint(:,end,2) =obj.hImAx.CurrentPoint([1 3])';
                        waitforbuttonpress;
                    end
                end
            end
        end
        
        
        
        function obj = makeChanSamples(obj, freqLaser, laserAmplitude)
            % inputs: frequency of inactivation, amplitude of voltage fed
            % to laser
            % output: obj.chanSamples (matrix of channel samples for each inactivation)
            
            % you can later check if everything works if you plot figure at
            % the end
            plotFigure = 0;
            
            obj.sampleRate = 1000;                      % samples in Hz
            obj.freqLaser = freqLaser;                  % full cycles in Hz
            numHalfCycles = 4;                          % arbitrary, no of half cycles to buffer
            obj.numSamplesPerChannel = obj.sampleRate/obj.freqLaser*(numHalfCycles/2);
            
            %             digitalAmplitude = 0.72;                       % old version with analog obis settings and without an arduino (gives 3.8 mW power)
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
            % the beamPointer
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
        
        
        
        function createNewTask2(obj, taskName)
            % TODO -- NOT USED FOR NOW
            % in construction to make the task run smoother
            
            devName = 'Dev2';
            
            chanIDs = [0 1 2 3];
            sampleRate = 5000; % in samples per second (Hz)
            sampleMode = 'DAQmx_Val_ContSamps';
            sampleClockSource = 'OnboardClock';
            
            numSamplesPerChannel = sampleRate;
            
            dTriggerSource = 'PFI0';
            dTriggerEdge = 'DAQmx_Val_Rising';
            
            obj.hTask = dabs.ni.daqmx.Task(taskName);
            
            obj.hTask.createAOVoltageChan(devName, chanIDs);
            
            obj.hTask.cfgSampClkTiming(sampleRate, sampleMode, numSamplesPerChannel, sampleClockSource);
            obj.hTask.cfgOutputBuffer(numSamplesPerChannel);
            
            obj.hTask.set('writeRegenMode', 'DAQmx_Val_DoNotAllowRegen');
            obj.hTask.registerEveryNSamplesEvent(@obj.topUpBuffer, 2500);
            
            % Configure the trigger
            %                 obj.hTask.cfgDigEdgeStartTrig(dTriggerSource, dTriggerEdge);
            %                 obj.hTask.set('startTrigRetriggerable',1);
            
            function cleanUpFunction % THIS IS COPIED FROM EXAMPLE
                if strcmp(obj.hTask.taskName, 'flashAreas')
                    fprintf('Cleaning up DAQ task\n');
                    obj.hTask.stop;    % Calls DAQmxStopTask
                    delete(obj.hTask); % The destructor (dabs.ni.daqmx.Task.delete) calls DAQmxClearTask
                else
                    fprintf('this task is not available for cleanup\n')
                end
            end %close cleanUpFunction
        end
        
                
        
        function topUpBuffer(obj)
            % NOT USED FOR NOW (TODO -- really? topCall is true by default)
            if logical(obj.topCall)
                disp('Top Up')
                obj.hTask.writeAnalogData(obj.voltChannel);
            end
        end
        
        
        
        function varargout=getLaserPosAccuracy(obj, varargin)
            % Find the coords of the beam location and compare to
            % the desired location. Returns results to screen if no
            % outputs. Otherwise returns a structure and does not
            % print to screen.
            
            %% find centre of laser field by averaging over three frames
            % Get images
            im1=obj.hImLive.CData;
            pause(0.01);
            im2 = obj.hImLive.CData;
            pause(0.01);
            im3 = obj.hImLive.CData;
            
            % Average and find the centre
            BW1=im1>(max(im1(:))*0.5); BW2=im2>(max(im2(:))*0.5); BW3=im3>(max(im3(:))*0.5);
            BWmean = (BW1+BW2+BW3)/3;
            BW = BWmean>(max(BWmean(:))*0.7);
            BWc = regionprops(bwareaopen(BW,50),'Centroid');
            
            
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
                if nargin==1
                    out.targetPixelCoords = [obj.hLastPoint.XData, obj.hLastPoint.YData];
                else
                    XData = varargin{1}(1);
                    YData = varargin{1}(2);
                    out.targetPixelCoords = [XData, YData];
                end
                out.actualPixelCoords = BWc.Centroid;
                out.error = out.targetPixelCoords-out.actualPixelCoords;
                out.absErrorMicrons = abs(out.error) * obj.micsPix;
                varargout{1} = out;
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
        
        
        
        function [xVolts, yVolts] = pixelToVolt(obj, xPos, yPos, varargin)
            % converts pixel coordinates to volt values for scanner mirrors
            % taking into account created transformation matrices (infinite
            % number of those allowed)
            
            % this function is important and used every time the laser is
            % pointed to a location. Called in: pointBeamToLocationInImage,
            % getAreaCoordinates and logPoints
            
            % varargin can contain 0 or 1 to indicate we want to take
            % Rob's offsets into account (not too important with the
            % transformation)
            
            if ~isempty(obj.transform)
                for tformMat = 1:length(obj.transform)
                    [xPos, yPos] = transformPointsInverse(obj.transform(tformMat), xPos, yPos);
                end
            end
            
            
            xVolts = (xPos - (obj.imSize(1)/2)) * obj.voltsPerPixel;
            yVolts = (yPos - (obj.imSize(2)/2)) * obj.voltsPerPixel;
            
            
            if obj.invertX
                xVolts = xVolts*-1;
            end
            if obj.invertY
                yVolts= yVolts*-1;
            end
            
            %             if ~isempty(varargin)
            %                 if varargin{1} == 1
            xVolts = xVolts + obj.xOffset;
            yVolts = yVolts + obj.yOffset;
            %                 end
            %             end
            
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
        
        
        
        function createNewTask3(obj)
            
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
            
            % Execute a cleanup function (below)
            cleanUpFunction;
            
            %% Create the inactivation task
            % taskName is defined in the previous function ('flashAreas')
            obj.hTask = dabs.ni.daqmx.Task('runTest');
            
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
        
        
        
        
        
        %% power-test methods
        % to test power, call obj.testPower, rest of instructions are in the program.
        % remember to update the bridge first before runnig the program
        
        function laserPower = testPower(obj)
            % start new task
            
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
                % the beamPointer
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
                    digitalAmplitude = 1.5; % fed into Arduino
                    
                    
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
