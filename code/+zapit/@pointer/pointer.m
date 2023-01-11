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

        % The following are associated with hardware components
        cam % camera
        DAQ % instance of class that controls the DAQ (laser and scanners)


        % The following properties relate to settings or other similar state parameters
        % Properties related to where we stimulate
        settings % The settings read in from the YAML file
        stimConfig % Object of class zapit.stimConfig. This contains the locations to stimulate
        %Laser stuff. TODO -- this might move to a separate class but for now it stays here
        laserFit  % laserfits. See generateLaserCalibrationCurve
        transform % The transform describing the relationship between scanners and camera


        % The following relate to calibration of the sample
        calibratedBrainOutline % The outline of the brain calibrated to the sample
        refPointsStereotaxic = [0,0;0,3]  % Two reference points in stereotaxic space. By default bregma
                                          % (first line [ML,AP] and a point 3 mm in front (second line)
                                          % TODO -- in future this can be a setting in the GUI.
        refPointsSample  % The two reference points in sample space. User provides these via calibrateSample

        % TODO -- what is the difference between chanSamples and waveforms?
        chanSamples %Structure describing waveforms to send the scanners for each brain area
        waveforms % The last set of waveforms sent to the DAQ by sendSamples or stopInactivation

        numSamplesPerChannel % TODO - why is this here? We need a better solution
    end % properties


    properties (Hidden)
        buildFailed = true % Used during boostrap by start_zapit
        simulated = false % Tag to indicate whether it is in simulated mode
        listeners = {} % Cell array that holds listeners so they can be easily cleaned up in the destructor
    end % hidden properties


    properties (Hidden,SetObservable=true)
        lastAcquiredFrame % The last frame acquired by the camera
        calibrateScannersPosData % Used to plot data during scanner calibration
        scannersCalibrated = false % Gets set to true if the scanners are calibrated
        sampleCalibrated = false % Gets set to true if the sample is calibrated
    end


    % read-only properties that are associated with getters
    properties(SetAccess=protected, GetAccess=public)
       imSize
    end


    % Constructor and destructor
    methods
        function obj = pointer(varargin)
            % Constructor
            %
            % Inputs
            % 'simulated' - [false by default] If true does not connect to hardware but 
            %   runs in simulated mode.

            params = inputParser;
            params.CaseSensitive = false;
            params.addParameter('simulated', false, @(x) islogical(x) || x==0 || x==1);

            params.parse(varargin{:});

            obj.simulated=params.Results.simulated;

            obj.settings = zapit.settings.readSettings;

            % Connect to camera
            if obj.simulated
                obj.cam = zapit.simulated.camera;
            else
                obj.cam = zapit.hardware.camera(obj.settings.camera.connection_index);
            end
            obj.cam.exposure = obj.settings.camera.default_exposure;

            obj.cam.ROI = [300,100,1400,1000]; % TODO: hardcoded sensor crop
                                            % TODO : in future user will have ROI box to interactively
                                            %    crop and this will be saved in settings file
                                            %    the re-applied on startup each time.
                                            %    see also obj.cam.resetROI

            % Log camera frames to lastAcquiredFrame and start camera
            if ~obj.simulated
                obj.cam.vid.FramesAcquiredFcn = @obj.storeLastFrame;
                obj.cam.vid.FramesAcquiredFcnCount=1; %Run frame acq fun every N frames
            else
               obj.listeners{end+1} = ...
                    addlistener(obj.cam, 'lastAcquiredFrame', 'PostSet', @obj.storeLastFrame);
               % Make a listener instead of the FramesAcquiredFcn
               obj.cam.startVideo; pause(0.2), obj.cam.stopVideo; pause(0.2) % TODO -- for some reason we need to call this twice for it to start working properly
            end
            obj.cam.startVideo; 


            if obj.simulated
                obj.DAQ = zapit.simulated.DAQ;
            else
                fprintf('Connecting to DAQ\n')
                obj.DAQ = zapit.hardware.DAQ.NI.vidriowrapper;
            end

            obj.DAQ.parent = obj;

            obj.DAQ.connectUnclockedAO(true) % TODO -- In principle this should not be needed here. 
            obj.zeroScanners % TODO ... as this will do the connection. Try it.            

            obj.loadLaserFit

            obj.buildFailed = false; % signal to start_zapit that all went well

        end % Constructor
        
        
        function delete(obj,~,~)
            % Stop the camera and disconnect from hardware
            fprintf('Shutting down optostim software\n')
            cellfun(@delete,obj.listeners)
            if isvalid(obj.cam)
                obj.cam.vid.FramesAcquiredFcn = [];
                obj.cam.stopVideo;
            end
            delete(obj.cam)
            delete(obj.DAQ)


        end % Destructor
        
    end % end of constructor/destructor block


    % Getters and setters
    methods
        function imSize = get.imSize(obj)
            % Return size of image being acquired by camera
            %
            % imSize = pointer.imSize(obj)
            %
            % Purpose
            % Return size of image being acquired by camera. This could change after
            % the camera has been started so it must be handled dynamically.
            imSize = obj.cam.ROI;
            imSize = imSize(3:4);
        end % get.imsize

    end % getters and setters


    % Other short methods
    methods

        function zeroScanners(obj)
            % TODO -- does it really make sense for galvo control methods to be in the DAQ class?
            % TODO -- running this currently does not update the plot by there are properties
            %         corresponding to these values that we can pick off from the DAQ class.
            obj.DAQ.moveBeamXY([0,0]);
        end % zeroScanners


        function actualCoords = returnScannerCalibTargetCoords(obj)
            % Return the coordinates the beam is supposed to have gone to during
            % calibration. These are the coordinates for which we also got a location
            % for where the beam actually went

            if isempty(obj.calibrateScannersPosData)
                actualCoords = [];
            end

            actualCoords = cat(1,obj.calibrateScannersPosData(:).actualCoords);
        end


        function storeLastFrame(obj,~,~)
            % This callback is run every time a frame has been acquired
            %
            %  function zapit.pointer.storeLastFrame(obj,~,~)
            %
            % Purpose
            % Stores the last acquired frame in an observable property

            if obj.cam.vid.FramesAvailable==0
                return
            end

            obj.lastAcquiredFrame = obj.cam.getLastFrame;
            obj.cam.flushdata
        end % storeLastFrame


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

            % TODO -- this is really slow right now if nFrames > 1 (since refactoring 21/12/2022)
            if nargin<2
                nFrames = 1;
            end

            im = obj.lastAcquiredFrame;

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
                    im(:,:,indexToInsertFrameInto) = obj.lastAcquiredFrame;
                    lastFrameAcquired = currentFramesAcquired;
                    indexToInsertFrameInto = indexToInsertFrameInto +1;
                end
            end
        end % returnCurrentFrame

        % The calibratedPoints and coordsLibrary methods were previously properties.
        % Now they calculate the same information on the fly.
        % TODO -- there might be a better way of doing this, such as integrating this into the
        %        stimConfig class. But right now we leave like this to get everything working.
        %        then we will tidy later when it's clearer what makes sense.
        function cPoints = calibratedPoints(obj)
            % The stimulation locations after they have been calibrated to the sample
            cPoints = [];
            if isempty(obj.stimConfig)
                return
            end
            % TODO -- this is clearly not ideal
            cPoints(:,:,1) = zapit.utils.coordsRotation(...
                            obj.stimConfig.template(:,:,1), ...
                            obj.stimConfig.refPoints, ...
                            obj.refPointsSample);
            cPoints(:,:,2) = zapit.utils.coordsRotation(...
                            obj.stimConfig.template(:,:,2), ...
                            obj.stimConfig.refPoints, ...
                            obj.refPointsSample);

        end


        function cLibrary = coordsLibrary(obj)
            % TODO - I think this is where all computed waveforms are kept
            cLibrary = [];
            if isempty(obj.stimConfig)
                return
            end

            calibratedPoints = obj.calibratedPoints;

            % Certainly this is a non-idiomatic way of doing this
            [xVolt, yVolt] = obj.mmToVolt(calibratedPoints(1,:,1), calibratedPoints(2,:,1)); % calibratedPoints should have an n-by-2 dimension
            [xVolt2, yVolt2] = obj.mmToVolt(calibratedPoints(1,:,2), calibratedPoints(2,:,2));

            cLibrary = [xVolt' yVolt'];
            cLibrary(:,:,2) = [xVolt2' yVolt2'];

            % TODO:??
            % should now run makeChanSamples and should also run this again if laser power changes.

        end

    end % methods

end % classdef
