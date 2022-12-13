classdef testCamera < handle
    % zapit.testCamera
    %
    % Barebones class to test the camera stream to be used in the optostim box
    %
    % e.g.
    % C = zapit.testCamera
    %
    % % Now stop and start the video
    % C.stopVideo
    % C.startVideo
    %
    %
    % Rob Campbell - SWC 2022



    % The following properties relate to settings the user can modify to alter the behavior of the class
    properties
        cam      % The camera class
        lastFrame  % Last acquired frame
    end

    properties (Hidden)
        hFig     % The handle of the figure window containing the camera stream
        hImAx    % The handle of the image axes
        hImLive  % The handle of the streaming camera image in the image axes
        hTitle   % Title of live image

        % The following are tag names for reusing figure windows
        figTagName = 'testCameraGUI'

    end



    % Constructor and destructor
    methods

        function obj = testCamera(camToStart)
            % testCamera constructor
            %
            % obj = zapit.testCamera(camToStart)
            %
            % Inputs
            % camToStart - Optional input argument defining which camera is to be connected to on startup
            %

            if nargin<1
                camToStart = [];
            end

            % Connect to the camera and bail out if this fails
            try
                obj.cam = zapit.camera(camToStart);

                % Build figure window: make a new one or clear an existing one and re-use it.
                obj.hFig = zapit.utils.focusNamedFig(obj.figTagName);
                obj.hFig.CloseRequestFcn = @obj.closeFig;
                clf(obj.hFig)
                obj.hImAx=axes(obj.hFig);
                rPos = obj.cam.vid.ROIPosition;


                % Populate the figure window for displaying preview images
                vidRes = obj.cam.vid.VideoResolution;
                obj.hImLive = image(zeros(size(vidRes)),'Parent',obj.hImAx);
                obj.hTitle = title('');
                colormap('gray')
                axis equal tight

                obj.cam.vid.FramesAcquiredFcn = @obj.dispImage;
                obj.cam.startVideo
            catch ME
                delete(obj)
                rethrow(ME)
            end
        end % Close constructor


        function delete(obj)
            % Destructor
            delete(obj.cam)
            delete(obj.hFig)
        end % Close destructor

    end % Close block containing constructor and destructor



    % Short methods
    methods

        function updateLiveImage(obj)
            % Plot last acquired frame in grayscale.
            obj.hImLive.CData = obj.lastFrame;
            obj.hTitle.String = sprintf('%d frames acquired',obj.cam.framesAcquired);
            drawnow
        end % Close updateLiveImage

    end % Close block containing short methods



    % Callback functions
    methods

        function closeFig(obj,~,~)
            obj.delete
        end

        function dispImage(obj,~,~)
            % This callback is run every time a given number of frames have been 
            % acquired by the video device
            if obj.cam.vid.FramesAvailable==0
                return
            end

            obj.lastFrame = obj.cam.getLastFrame;

            obj.cam.flushdata
            obj.updateLiveImage
        end % dispImage

    end % Close block containing callbacks


end % close diffusersensor
