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
        voltsPerPixel = 2.2E-3 %TODO -- HARDCODED. MOVE TO SETTINGS
        micsPix = 19.3 %Measured this %TODO -- HARDCODED
        
        % Properties related to where we stimulate
        transform
        config % Object of class zapit.config

        
        % behavioural task properties
        coordsLibrary % TODO - I think this is where all computed waveforms are kept
        newpoint % TODO - ??
        chanSamples %Structure describing waveforms to send the scanners for each brain area
        freqLaser % TODO - ??
        numSamplesPerChannel % TODO - why is this here? We need a better solution


        waveforms % The last set of waveforms sent to the DAQ by sendSamples or stopInactivation
        DAQ % instance of class that controls the DAQ will be attached here
    end % properties


    properties (Hidden)
        % Handles for plot elements

        hFig
        hImAx
        hImLive

        % TODO: these plot elements should have a system like BT acq window, where we delete and create without a property for each.
        hLastPoint % plot handle with location of the last clicked point
        hAreaCoords % locations where the beam will be sent. see getAreaCoords
        hRefCoords  % The two reference coords

        axRange

        % Camera and image related
        cam % camera object goes here

        %Laser stuff. TODO -- this might move to a separate class but for now it stays here
        laserFit  % laserfits. See generateLaserCalibrationCurve
        laserMinMaxControl = [1.5,3.5]; %TODO - must go to settings. Max and min control values
        laserMinMax_mW = [0,100]; % TODO can not be here! number of mW at the control min/max


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

            % Connect to camera
            obj.cam = zapit.camera(2); % TODO -  Hard-coded selection of camera ID
            obj.cam.exposure = 3000; % TODO - HARDCODED
            obj.cam.ROI = [300,100,1400,1000]; % TODO: hardcoded sensor crop
                                            % TODO : in future user will have ROI box to interactively
                                            %    crop and this will be saved in settings file
                                            %    the re-applied on startup each time.
                                            %    see also obj.can.resetROI

            obj.setUpFigure

            fprintf('Connecting to DAQ\n')
            obj.DAQ = zapit.hardware.DAQ.NI.vidriowrapper;
            obj.DAQ.parent = obj;

            obj.DAQ.connectUnclockedAO(true)
            
            
            obj.zeroScanners


            obj.setLaserInMW(20) % TODO -- temporary


            % TODO -- this does not have to be here. We can calibrate camera without this. It should be elsewhere. 
            % Load configuration files
            if isempty(fname)
                [fname,fpath] = uigetfile('*.yaml','Pick a config file');
                pathToConfig = fullfile(fpath,fname);
            else
                pathToConfig = fname;
            end
            obj.config = zapit.config(pathToConfig);
        end % Constructor
        
        
        
        function delete(obj,~,~)
            % Stop the camera and disconnect from hardware
            fprintf('Shutting down optostim software\n')
            obj.cam.stopVideo;
            delete(obj.hFig) % close figure
            delete(obj.cam)
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


        function im = returnCurrentFrame(obj,nFrames)
            % Return the last recorded camera image and optionally the last n frames
            %
            % function im = returnCurrentFrame(obj,nFrames)
            %
            % Purpose
            % Return the last frame and, if requested, the last n frames.
            %
            % Inputs
            % nFrames - [optional] 1 by default. If >1 this many frames are returned.
            %
            % Outputs
            % im - the image
            %
            %

            if nargin<2
                nFrames = 1;
            end

            im = obj.hImLive.CData;

            if nFrames==1
                return
            end

            im = repmat(im,[1,1,nFrames]);
            lastFrameAcquired = obj.cam.vid.FramesAcquired; % The frame number

            indexToInsertFrameInto = 2;
            while indexToInsertFrameInto < nFrames
                % If statment adds a new frame once the counter of number of frames
                % has incrememted
                currentFramesAcquired = obj.cam.vid.FramesAcquired;
                if currentFramesAcquired > lastFrameAcquired
                    im(:,:,indexToInsertFrameInto) = obj.hImLive.CData;
                    lastFrameAcquired = currentFramesAcquired;
                    indexToInsertFrameInto = indexToInsertFrameInto +1;
                end
            end
        end % returnCurrentFrame


        function dispFrame(obj,~,~)
            % This callback is run every time a frame has been acquired
            %
            %  function zapit.pointer.dispFrame(obj,~,~)
            %
            % Purpose
            % Callback function that gets the last frame from the camera then displays it.

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
