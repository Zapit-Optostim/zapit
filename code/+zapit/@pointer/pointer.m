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
        chanSamples %Structure describing waveforms to send the scanners for each brain area
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

        hAreaCoords % locations where the beam will be sent. see getAreaCoords
        hRefCoords  % The two reference coords

        axRange
        imSize % Size of the displayed image

        % NI DAQmx
        hTask
        AIrange = 10 % +/- this many volts

        % Camera and image related
        cam % camera object goes here


    end
    
    
    methods
        function obj = pointer(fname)
            % Constructor

            if nargin < 1
                fname = [];
            end

            disp('STARTING BEAMPOINTER')
            obj.cam = zapit.camera(2); % TODO -  Hard-coded selection of camera ID
            
            % Connect to camera
            imSize = obj.cam.vid.ROIPosition;
            obj.imSize = imSize(3:4);

            obj.cam.exposure = 3000; % TODO - HARDCODED
            

            obj.setUpFigure

            % TODO - Put connection to DAQ in a method
            obj.hTask = dabs.ni.daqmx.Task('beamplacer'); % create a task that lives in the plot axes
            obj.hTask.createAOVoltageChan('Dev2', 0:2, [], -obj.AIrange, obj.AIrange); % # TODO -- hardcoded!
            
            
            % TODO -- we should presumbably implement the following again?
            % When window closes we disconnect from the DAQ
            % obj.hFig.CloseRequestFcn = @obj.figClose;
            
            
            obj.zeroScanners

            % load configuration files
            if isempty(fname)
                [fname,fpath] = uigetfile('*.yaml','Pick a config file');
                pathToConfig = fullfile(fpath,fname);
            else
                pathToConfig = fname;
            end
            obj.config = zapit.config(pathToConfig);
        end
        
        
        
        function delete(obj,~,~)
            fprintf('Shutting down optostim software\n')
            obj.cam.stopVideo;
            delete(obj.hFig)
            delete(obj.cam)

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
                obj.createNewTask(taskName);
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

            % TODO the task is continuing to run, which is wrong. It should play out the finite
            % samples then it stops.
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
            
            % Execute a cleanup function (TODO -- WHY?)
            obj.cleanUpFunction;
            
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
            

        end

        %% cleanup function
        function cleanUpFunction(obj)
            if exist('obj.hTask')
                fprintf('Cleaning up DAQ task\n');
                obj.hTask.stop;    % Calls DAQmxStopTask
                delete(obj.hTask); % The destructor (dabs.ni.daqmx.Task.delete) calls DAQmxClearTask
            else
                fprintf('this task is not available for cleanup\n')
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

        function testCoordsLibray(obj)
            % move laser into each position as a check
            for xx = 1:length(obj.newpoint)
                for yy = 1:2
                    fprintf('Testing coordinate %0.2f %0.2f\n', ...
                     obj.coordsLibrary(xx, 1, yy), ...
                     obj.coordsLibrary(xx, 2, yy))
                    obj.hTask.writeAnalogData([obj.coordsLibrary(xx, 1, yy), obj.coordsLibrary(xx, 2, yy),2]);
                    pause(0.25)
                end
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
        


    end
end
