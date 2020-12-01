classdef beamPointer < handle
    
    % beamPointer
    %
    % Drives a galvo-based photo-stimulator. Scan lens doubles as an
    % objective to scan the beam over the sample and also to form an 
    % image via a camera.

    properties
        
        % Handles for plot elements
        hFig
        hImAx
        hImLive
        hLastPoint % plot handle with location of the last clicked point
        
        axRange
        
        % NI DAQmx 
        hTask
        AIrange = 2 % +/- this many volts
        
        % Camera and image related
        cam % camera object goes here
        imSize
       
        % 0/0 volts on DAQ corresponds to the middle of the image
        invertX = true
        invertY = false
        xOffset = 0.08;
        yOffset = 0.01;
        voltsPerPixel = 2.2E-3
        
        micsPix = 19.3 %Measured this 
    end
    
    
    methods
        function obj = beamPointer
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
            % HARD-CODED DEVICE NAME
            obj.hTask.createAOVoltageChan('Dev1', 0:1, [], -obj.AIrange, obj.AIrange);


            % When window closes we disconnect from the DAQ
            obj.hFig.CloseRequestFcn = @obj.figClose;

            
            obj.zeroScanners
        end
        
        function delete(obj)
            fprintf('Cleaning up object\n')
            obj.cam.stopVideo;
            delete(obj.cam)
            delete(obj.hFig)
            delete(obj.hTask)
        end
        
        function zeroScanners(obj)
            obj.hTask.writeAnalogData([0,0])
        end
        
        function varargout=getLaserPosAccuracy(obj)
            % Find the coords of the beam location and compare to 
            % the desired location. Returns results to screen if no
            % outputs. Otherwise returns a structure and does not
            % print to screen.
            
            % The folowing has been tested with a fluoro card and
            % in a scenario where the beam is by far the brightest thing.
            
            % Get the image
            im=obj.hImLive.CData;
            
            % Find the beam centre
            BW=im>(max(im(:))*0.5);
            BWc = regionprops(BW,'Centroid');
            
            % TODO -- a better approach might be to take one image with the
            % beam off. One with the beam on. Subtract and use this difference
            % image to get the beam centre. We will need to make the camera
            % class has a "snap" function to take one frame. An order of
            % events that would be nice is:
            % 1. Take last frame. Now we have the beam on.
            % 2. Disable image updates to screen
            % 3. Stop camera stream
            % 4. Turn off beam
            % 5. Acquire image silently (not updating screen)
            % 6. Turn back on the image stream and updating to screen. 
            %
            % This way the user doesn't even realise what happened. 
            
            % Bail out if we find no or multiple points
            if length(BWc) ~= 1
                fprintf('Expected to find one point. Found %d points\n', length(BWc))
                return
            end
            
            % report to screen or return as a structure
            if nargout==0
                fprintf('Laser at x = %d y = %d\n', round(BWc.Centroid))
                fprintf('User point at x = %d y = %d\n', ...
                    round(obj.hLastPoint.XData), round(obj.hLastPoint.YData))

                fprintf('Error: x = %0.2f um  y = %0.1f um\n', ...
                    abs(obj.hLastPoint.XData-BWc.Centroid(1)) * obj.micsPix, ...
                    abs(obj.hLastPoint.YData-BWc.Centroid(2)) * obj.micsPix)
            elseif nargout>0
                out.targetPixelCoords = [obj.hLastPoint.XData, obj.hLastPoint.YData];
                out.actualPixelCoords = BWc.Centroid;
                out.error = out.targetPixelCoords-out.actualPixelCoords;
                out.absErrorMicrons = abs(out.error) * obj.micsPix;
                varargout{1} = out;
            end
                
        end

        function figClose(obj,~,~)
            obj.delete
        end
        
        function pointBeamToLocationInImage(obj,~,~)
            % This callback function obtains the mouse position in the
            % image and uses this to point the scanners to this location. 
            %
            %
            % Get the current mouse position (at the clicked location) and use it
            % to place a point there and display coords to the axes title.
            pos = obj.hImAx.CurrentPoint;
            xPos = pos(1,1);
            yPos = pos(1,2);
            
           
            % convert to voltage values to send to scanners
            xVolts = (xPos - (obj.imSize(1)/2)) * obj.voltsPerPixel;
            yVolts = (yPos - (obj.imSize(2)/2)) * obj.voltsPerPixel;
            
            if obj.invertX
                xVolts = xVolts*-1;
            end

            if obj.invertY
                yVolts= yVolts*-1;
            end
            
            xVolts = xVolts + obj.xOffset;
            yVolts = yVolts + obj.yOffset;
            
            obj.hLastPoint.XData = xPos;
            obj.hLastPoint.YData = yPos;

            obj.hTask.writeAnalogData([xVolts, yVolts]);
            
            msg = sprintf('X=%0.2f (%0.1f V) Y=%0.2f (%0.1f V)',...
                xPos, xVolts, yPos, yVolts);
            set(get( obj.hImAx,'Title'),'String',msg)
            
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
    