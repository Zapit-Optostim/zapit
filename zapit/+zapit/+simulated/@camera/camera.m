classdef camera < handle
    % zapit.simulated.camera
    %
    % Purpose
    % This class simulates a zapit.hardware.camera to allow development and testing without
    % hardware present.
    %
    % Rob Campbell - 2022 SWC


    properties
        vid   % Normally holds the camera object
        src   % Normally holds the camera-specific properties
    end


    properties
        exposure
    end

    properties(SetObservable=true)
        ROI
    end

    properties(Hidden)
        isCamRunning=false
        frameTimer   % Timer to simulate frames being produce
        frameInterval = 0.05 % frame interval in seconds

    end


    properties(Hidden,SetObservable=true)
        lastAcquiredFrame = []; % A frame of noise will go here
        simulatedLaserSpot = []; % This is used to display the laser spot on top of the last acquired frame
    end


    methods
        function obj = camera(camToStart)
            if nargin<1 || isempty(camToStart)
                camToStart=[];
            end

            obj.vid.FramesAcquired = 0;
            obj.vid.FramesAcquiredFcnCount=1; % Not used
            obj.vid.VideoResolution = [1900,1600]; %Default ROI
            obj.ROI = [1,1,obj.vid.VideoResolution]; %Current ROI
            obj.generateFrame

            obj.vid.FramesAvailable = 0; % Set to 1 if the timer is running (see below

            % Set up the timer
            obj.frameTimer = timer;
            obj.frameTimer.Name = 'Simulated camera frame timer';
            obj.frameTimer.Period = obj.frameInterval;
            obj.frameTimer.TimerFcn = @obj.updateFrameCounter_Callback;
            obj.frameTimer.ExecutionMode = 'fixedDelay';

        end % close constructor


        function delete(obj)
            obj.stopVideo
            if isa(obj.frameTimer,'timer')
                stop(obj.frameTimer)
                delete(obj.frameTimer)
            end
        end % close destructor

    end % methods


    % The following methods are involved in starting and stopping the video feed
    methods


        function updateFrameCounter_Callback(obj,~,~)
            obj.generateFrame
            obj.vid.FramesAcquired = obj.vid.FramesAcquired + 1;
        end
    
        function varargout  = generateFrame(obj)
            im = round(rand(obj.ROI(3:4))*100);

            % Set the simulated laser spot to an image of zeros if it is not the same
            % size as the image
            if ~isequal(size(im),size(obj.simulatedLaserSpot))
                obj.simulatedLaserSpot = zeros(size(im));
            end
            im = im + obj.simulatedLaserSpot;

            obj.lastAcquiredFrame = im;

            if nargout>0
                varargout{1} = im;
            end
        end

        function startVideo(obj)
            if strcmp(obj.frameTimer.Running,'on')
                return
            end
            obj.isCamRunning=true;
            obj.vid.FramesAvailable = 1;
            start(obj.frameTimer)
        end % startVideo


        function stopVideo(obj)
            if strcmp(obj.frameTimer.Running,'off')
                return
            end
            obj.isCamRunning=false;
            obj.vid.FramesAvailable = 0;
            stop(obj.frameTimer)
        end % stopVideo


        function flushdata(obj)
        end % flushdata


        function lastFrame=getLastFrame(obj)
            lastFrame = obj.generateFrame;
        end % getLastFrame


        function vidRunning=isrunning(obj)
            vidRunning = obj.isCamRunning;
        end % isrunning


        function nFrm=framesAcquired(obj)
            nFrm=obj.vid.FramesAcquired;
        end % framesAcquired


        function resetROI(obj,~,~)
            obj.stopVideo
            obj.ROI = [0,0,obj.vid.VideoResolution];
            obj.startVideo
        end % resetROI

    end % video feed methods

end % pointer

