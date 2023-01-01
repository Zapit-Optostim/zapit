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
        ROI
    end

    properties(Hidden)
        isCamRunning=false
    end


    methods
        function obj = camera(camToStart)
            if nargin<1 || isempty(camToStart)
                camToStart=[];
            end

            
            obj.vid.FramesAcquired=0;
            obj.vid.VideoResolution = [1900,1600]; %The camera default resolution
        end % close constructor


        function delete(obj)

        end % close destructor

    end % methods


    % The following methods are involved in starting and stopping the video feed
    methods

        function startVideo(obj)
            % TODO: this must do something
            obj.isCamRunning=true;
        end % startVideo


        function stopVideo(obj)
            % TODO: this must do something
            obj.isCamRunning=false;
        end % stopVideo


        function flushdata(obj)
        end % flushdata


        function lastFrame=getLastFrame(obj)
            % TODO: this must do something
        end % getLastFrame


        function vidRunning=isrunning(obj)
            vidRunning = obj.isCamRunning;
        end % isrunning


        function nFrm=framesAcquired(obj)
            nFrm=obj.vid.FramesAcquired;
        end % framesAcquired


        function resetROI(obj,~,~)
            obj.ROI = [0,0,obj.vid.VideoResolution];
        end % resetROI

    end % video feed methods

end % pointer

