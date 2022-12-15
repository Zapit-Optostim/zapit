classdef pointer < handle
    
    % pointer
    %
    % Drives a galvo-based photo-stimulator. Scan lens doubles as an
    % objective to scan the beam over the sample and also to form an
    % image via a camera.
    %
    %
    % Maja Skretowska - SWC 2020-2022
    % Rob Campbell - SWC 2020...


    
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
        coordsLibrary % TODO - I think this is where all computed waveforms are kept
        newpoint % TODO - ??
        topUpCall % TODO - ??
        rampDown % Not used (yet?)
        chanSamples %Structure describing waveforms to send the scanners for each brain area
        topCall = 1; % TODO - ??
        freqLaser % TODO - ??
        numSamplesPerChannel % TODO - why is this here? We need a better solution
        sampleRate % TODO - This is now elsewhere but keep for the moment

        DAQ % instance of class that controls the DAQ will be attached here
    end % properties


    properties (Hidden)
        % Handles for plot elements
        hFig
        hImAx
        hImLive
        hLastPoint % plot handle with location of the last clicked point

        hAreaCoords % locations where the beam will be sent. see getAreaCoords
        hRefCoords  % The two reference coords

        axRange

        % NI DAQmx TODO -- these will all go as they are being integrated into a new class
        hTask
        devName = 'Dev2' % HARD-CODED -- TODO
        AIrange = 10 % +/- this many volts

        % Camera and image related
        cam % camera object goes here

    end % hidden properties

    % read-only properties that are associated with getters
    properties(SetAccess=protected, GetAccess=public)
       imSize
    end
    
    % Constructor and destructor
    methods
        function obj = pointer(fname)
            % Constructor

            if nargin < 1
                fname = [];
            end

            disp('STARTING BEAMPOINTER')

            % Connect to camera
            obj.cam = zapit.camera(2); % TODO -  Hard-coded selection of camera ID
            obj.cam.exposure = 3000; % TODO - HARDCODED
            obj.cam.ROI = [300,100,1400,1000]; % TODO: hardcoded sensor crop
                                            % TODO : in future user will have ROI box to interactively
                                            %    crop and this will be saved in settings file
                                            %    the re-applied on startup each time.
                                            %    see also obj.can.resetROI

            obj.setUpFigure


            % Attach the DAQ (TODO: for now we hard-code the class as it's the only one)
            obj.DAQ = zapit.hardware.DAQ.NI.vidriowrapper;
            obj.DAQ.parent = obj;

            % TODO - Put connection to DAQ in a method
            obj.DAQ.connectUnclocked(true)
            
            
            % TODO -- we should presumbably implement the following again?
            % When window closes we disconnect from the DAQ
            % obj.hFig.CloseRequestFcn = @obj.figClose;
            
            obj.zeroScanners

            % TODO -- we evenually want to be setting laser power in mW with a laser class.
            % so we will need the laser class to talk to the DAQ. Therefore it might make
            % sense to have a scanner class that talks to the DAQ (see above)
            obj.DAQ.setLaserPowerControlVoltage(1) % TODO -- we will need

            % load configuration files
            if isempty(fname)
                [fname,fpath] = uigetfile('*.yaml','Pick a config file');
                pathToConfig = fullfile(fpath,fname);
            else
                pathToConfig = fname;
            end
            obj.config = zapit.config(pathToConfig);
        end % Constructor
        
        
        
        function delete(obj,~,~)
            fprintf('Shutting down optostim software\n')
            obj.cam.stopVideo;
            delete(obj.hFig)
            delete(obj.cam)

            delete(obj.hTask)
            delete(obj.DAQ)
        end % Destructor
        
    end % end of constructor/destructor block


    % Getters and setters
    methods
        function imSize = get.imSize(obj)
            % Return size of image being acquired by camera
            %
            % iSize = pointer(obj)
            %
            % Purpose
            % Return size of image being acquired by camera. This could change after
            % the camera has been started so it must be handled dynamically.
            imSize = obj.cam.ROI;
            imSize = imSize(3:4);

        end % imsize
    end % getters and setters


    % Other short methods
    methods
        function zeroScanners(obj)
            % TODO -- does it really make sense for galvo control methods to be in the DAQ class?
            % TODO -- running this currently does not update the plot by there are properties
            %         corresponding to these values that we can pick off from the DAQ class.
            obj.DAQ.moveBeamXY([0,0]);
        end % zeroScanners
        
        
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
        end % runAffineTransform


        function createUnclockedTask(obj)
            obj.hTask = dabs.ni.daqmx.Task('unclocked');
            obj.hTask.createAOVoltageChan(obj.devName, 0:2, [], -obj.AIrange, obj.AIrange);
        end % createUnclockedTask

        



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
        end % sendSamples
        
        
        function createNewTask(obj, taskName)
            
            devName = 'Dev2';

            % channel 0 = x Axis
            % channel 1 = y Axis
            % channel 2 = analog laser
            % channel 3 = masking light %TODO -- can probably be a clocked digital line?
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
        end % stopInactivation
        
        
        function topUpBuffer(obj)
            % NOT USED FOR NOW (TODO -- really? topCall is true by default)
            if logical(obj.topCall)
                disp('Top Up')
                obj.hTask.writeAnalogData(obj.voltChannel);
            end
        end % topUpBuffer

        function testCoordsLibrary(obj)
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
        end  % testCoordsLibrary


        
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
        end % pixelToVolt
        
        
        function dispFrame(obj,~,~)
            % This callback is run every time a frame has been acquired
            if obj.cam.vid.FramesAvailable==0
                return
            end
            
            tmp = obj.cam.getLastFrame;
            
            obj.hImLive.CData = tmp;
            drawnow
            obj.cam.flushdata
        end % dispFrame


    end % methods

end % classdef
