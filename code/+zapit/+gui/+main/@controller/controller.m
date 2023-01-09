classdef controller < zapit.gui.main.view

    % zapit.gui.view is the main GUI window: that which first appears when the 
    % user starts the software.
    %
    % The GUI itself is made in MATLAB AppDesigner and is inherited by this class

    properties
        % Handles for some plot elements are inherited from the superclass

        hImLive  %The image
        plotOverlayHandles   % All plotted objects laid over the image should keep their handles here

        model % The ZP model object goes here
        atlasData % Brain atlas data for overlaying brain areas, etc
        listeners = {}; % All go in this cell array
    end


    properties(Hidden)
        laserPowerBeforeCalib % Used to reset the laser power to the value it had before calibration
        nInd % a counter used by calibrateSample_Callback
    end


    properties(Hidden,SetObservable=true)
        % The following are used to build the recently loaded stim config drop-down
        % A structure that contains names and paths to recently loaded stim config files.
        previouslyLoadedStimConfigs = struct('fname', '', 'pathToFname', '', 'timeAdded', []);
        maxPreviouslyLoadedStimConfigs = 10 % Max number to display. 
    end


    methods

        function obj = controller(hZP)
            if nargin>0
                obj.model = hZP;
            else
                fprintf('Can''t build zapit.gui.view please supply ZP model as input argument\n');
                obj.delete
                return
            end

            % Load the atlas data so we can do things like overlay the brain boundaries
            load('atlas_data.mat')
            obj.atlasData = atlas_data;

            % Add a listener to the sampleSavePath property of the BT model
            %% obj.listeners{end+1} = addlistener(obj.model, 'sampleSavePath', 'PostSet', @obj.updateSampleSavePathBox); % FOR EXAMPLE
            obj.prepareWindow
            obj.buildListeners

            % Call the class destructor when figure is closed. This ensures all
            % the hardware tasks are stopped.
            obj.hFig.CloseRequestFcn = @obj.delete;

            % Attempt to report when figure is open
            %getframe(obj.hImAx)
            %fprintf('DONE\n')
        end %close constructor


        function delete(obj,~,~)
            fprintf('zapit.gui.view is cleaning up\n')
            cellfun(@delete,obj.listeners)
            delete(obj.model);

            obj.model=[];

            delete(obj.hFig);

            %clear from base workspace if present
            evalin('base','clear hZP hZPview')
        end %close destructor


        function closeZapit(obj,~,~)
            %Confirm and quit Zapit (also closing the model and so disconnecting from hardware)
            %This method runs when the user presses the close 
            choice = questdlg('Are you sure you want to quit Zapit?', '', 'Yes', 'No', 'No');

            switch choice
                case 'No'
                    %pass
                case 'Yes'
                    obj.delete
            end
        end


        function prepareWindow(obj)
            % Prepare the window

            % Insert and empty image into axes.
            obj.refreshImage


            %Make the GUI resizable on small screens
            sSize = get(0,'ScreenSize');
            if sSize(4)<=900
                obj.hFig.Resize='on';
            end


            % Update elements from settings file
            % TODO: changing the settings spin boxes should change the settings file
            obj.CalibPowerSpinner.Value = obj.model.settings.calibrateScanners.calibration_power_mW;
            obj.LaserPowerScannerCalibSlider.Value = obj.CalibPowerSpinner.Value;
            obj.PointSpacingSpinner.Value = obj.model.settings.calibrateScanners.pointSpacingInPixels;
            obj.BorderBufferSpinner.Value = obj.model.settings.calibrateScanners.bufferPixels;
            obj.SizeThreshSpinner.Value = obj.model.settings.calibrateScanners.areaThreshold;
            obj.CalibExposureSpinner.Value = obj.model.settings.calibrateScanners.beam_calib_exposure;

            obj.LoadRecentDropDown.Items={};
            obj.TestSiteDropDown.Items={}; % Nothing loaded yet...

            % Run method on mouse click


            obj.ResetROIButton.ButtonPushedFcn = @(~,~) obj.resetROI_Callback;
            obj.ROIButton.ButtonPushedFcn = @(~,~) obj.drawROI_Callback;
            obj.RunScannerCalibrationButton.ButtonPushedFcn = @(~,~) obj.calibrateScanners_Callback;
            obj.CheckCalibrationButton.ValueChangedFcn = @(~,~) obj.checkScannerCalib_Callback;
            obj.PointModeButton.ValueChangedFcn = @(~,~) obj.pointButton_Callback;
            obj.CatMouseButton.ValueChangedFcn = @(~,~) obj.catAndMouseButton_Callback;
            obj.LaserPowerScannerCalibSlider.ValueChangedFcn = @(src,evt) obj.setLaserPower_Callback(src,evt);
            obj.CalibLaserSwitch.ValueChangedFcn = @(~,~) obj.switchLaser_Callback;
            obj.PointSpacingSpinner.ValueChangedFcn = @(~,~) obj.pointSpacing_CallBack;
            obj.BorderBufferSpinner.ValueChangedFcn = @(~,~) obj.borderBuffer_CallBack;
            obj.SizeThreshSpinner.ValueChangedFcn = @(~,~) obj.sizeThreshSpinner_CallBack;
            obj.CalibExposureSpinner.ValueChangedFcn = @(~,~) obj.calibExposureSpinner_CallBack;
            obj.CycleBeamOverCoordsButton.ValueChangedFcn = @(~,~) obj.CycleBeamOverCoords_Callback;
            obj.LoadStimConfigButton.ButtonPushedFcn = @(~,~) obj.loadStimConfig_Callback;
            obj.ZapSiteButton.ButtonPushedFcn = @(~,~) obj.zapSite_Callback;
            obj.CalibrateSampleButton.ButtonPushedFcn = @(~,~) obj.calibrateSample_Callback;
            %% TODO -- is this R2022b? obj.LoadRecentDropDown.ClickedFcn = @(~,~) obj.loadRecentConfig_Callback;
            % Set GUI state based on calibration state
            obj.scannersCalibrateCallback
            obj.sampleCalibrateCallback
        end


        function refreshImage(obj)
            % Add an image to empty axes or re-plot an image with new XData and YData
            %
            % zapit.gui.main.controller.refreshImage
            %
            % Purpose
            % Insert and empty image into axes. Calling this method with no image in hImAx or an 
            % image with empty CData will cause a new image to be produced. The image will be the
            % size specified by the camera ROI and will be plotted in mm using the XData and YData 
            % input args to the plotting function. This is to ensure that all plotted images have
            % axes that remain in mm.


            imSize = obj.model.imSize;
            mixPix = obj.model.settings.camera.micronsPerPixel;

            % These variables are the X and Y axis data that allow us to
            % plot the image in units of mm rather pixels.
            xD = (1:imSize(1)) * mixPix * 1E-3;
            yD = (1:imSize(2)) * mixPix * 1E-3;

            xD = xD - mean(xD);
            yD = yD - mean(yD);

            obj.hImLive = image(zeros(imSize), 'XData',xD, 'YData', yD, 'Parent',obj.hImAx);

            % Set axis limits
            obj.hImAx.XLim = [xD(1), xD(end)];
            obj.hImAx.YLim = [yD(1), yD(end)];

            pan(obj.hImAx,'off')
            zoom(obj.hImAx,'off')


            % TODO -- for now we leave the axes on as they help for debugging
            hideAxes = false;

            if hideAxes
                obj.hImAx.XTick = [];
                obj.hImAx.YTick = [];
            else
                obj.hImAx.XTick = round(xD(1):1:xD(end));
                obj.hImAx.YTick = round(yD(1):1:yD(end));
                grid(obj.hImAx,'on')
            end
            obj.hImAx.YDir = 'normal';
            obj.hImAx.DataAspectRatio = [1,1,1]; % Make axis aspect ratio square
        end


        function buildListeners(obj)
            obj.listeners{end+1} = ...
                addlistener(obj.model, 'lastAcquiredFrame', 'PostSet', @obj.dispFrame);
            obj.listeners{end+1} = ...
                addlistener(obj.model, 'scannersCalibrated', 'PostSet', @obj.scannersCalibrateCallback);
            obj.listeners{end+1} = ...
                addlistener(obj.model, 'sampleCalibrated', 'PostSet', @obj.sampleCalibrateCallback);
            obj.listeners{end+1} = ...
                addlistener(obj, 'previouslyLoadedStimConfigs', 'PostSet', @obj.updatePreviouslyLoadedStimConfigList_Callback);
        end


        function resetROI_Callback(obj,~,~)
            % Reset ROI to full sensor size
            %
            % zapit.gui.main.controller.resetROI_Callback
            %
            % Purpose
            % Right now just calls the resetROI method of the camera object but in 
            % future might do more stuff. 

            obj.model.cam.resetROI;

        end % resetROI_Callback


        function scannersCalibrateCallback(obj,~,~)
            % Perform any actions needed upon change in scanner calibration state
            obj.set_scannersLampCalibrated(obj.model.scannersCalibrated)

            if obj.model.scannersCalibrated
                obj.CheckCalibrationButton.Enable = 'on';
            else
                obj.CheckCalibrationButton.Enable = 'off';
            end
        end

        function sampleCalibrateCallback(obj,~,~)
            % Perform any actions needed upon change in sample calibration state
            obj.set_sampleLampCalibrated(obj.model.sampleCalibrated)
        end


        function set_scannersLampCalibrated(obj,calibrated)
            % Set lamp state for scanner calibration
            if calibrated
                obj.ScannersCalibratedLamp.Color = [0 1 0];
            else
                obj.ScannersCalibratedLamp.Color = [1 0 0];
            end
        end

        function set_sampleLampCalibrated(obj,calibrated)
            % Set lamp state for sample calibration
            if calibrated
                obj.SampleCalibratedLamp.Color = [0 1 0];
            else
                obj.SampleCalibratedLamp.Color = [1 0 0];
            end
        end

        function setLaserPower_Callback(obj,src,event)
            % Should be able to recieve from any UI
            if strcmp(obj.CalibLaserSwitch.Value,'On')
                obj.model.setLaserInMW(event.Value)
            end
        end

        function switchLaser_Callback(obj,~,~)
            if strcmp(obj.CalibLaserSwitch.Value,'On')
                obj.model.setLaserInMW(obj.LaserPowerScannerCalibSlider.Value);
            else
                obj.model.setLaserInMW(0)
            end
        end

        function setCalibLaserSwitch(obj,value)
            % Because changing the switch value programmaticaly does not
            % fire the callback. WHY DID TMW THEY DO THIS?!
            if ~char(value)
                return
            end
            if ~strcmp(value,'On') && ~strcmp(value,'Off')
                return
            end
            obj.CalibLaserSwitch.Value = value;
            obj.switchLaser_Callback
        end


        function pointSpacing_CallBack(obj,~,~)
            obj.model.settings.calibrateScanners.pointSpacingInPixels = obj.PointSpacingSpinner.Value;
        end


        function borderBuffer_CallBack(obj,~,~)
            obj.model.settings.calibrateScanners.bufferPixels = obj.BorderBufferSpinner.Value;
        end



        function sizeThreshSpinner_CallBack(obj,~,~)
            if obj.SizeThreshSpinner.Value < 1
                obj.SizeThreshSpinner.Value = 1;
            end
            obj.model.settings.calibrateScanners.areaThreshold = obj.SizeThreshSpinner.Value;
        end


        function calibExposureSpinner_CallBack(obj,~,~)
            if obj.CalibExposureSpinner.Value < 0
                obj.CalibExposureSpinner.Value = 0;
            end
            obj.model.settings.calibrateScanners.beam_calib_exposure = obj.CalibExposureSpinner.Value;
        end


        %TODO The following two from calibrate sample should be moved out when it all works
        function calibrateSampleClick_Callback(obj,sr,evt)
            % TODO -- move out to own file
            % this is a callback that responds to mouse clicks during sample calibration

            if strcmp(obj.hFig.SelectionType,'alt')
                return
            end
            C = get (obj.hImAx, 'CurrentPoint');
            X = C(1,1);
            Y = C(1,2);

            xl = obj.hImAx.XLim;
            yl = obj.hImAx.YLim;
            if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
                return
            end

            % Paste
            if obj.nInd == 1
                % The boundaries of the brain in mm
                b = obj.atlasData.whole_brain.boundaries_stereotax{1};

                obj.plotOverlayHandles.brainOutline.XData = b(:,2)+X;
                obj.plotOverlayHandles.brainOutline.YData = b(:,1)+Y;

                obj.model.refPointsSample(obj.nInd,:) = [X,Y];
                obj.nInd = obj.nInd + 1;
                obj.plotOverlayHandles.bregma.XData=X;
                obj.plotOverlayHandles.bregma.YData=Y;
            elseif obj.nInd==2
                if zapit.utils.isShiftPressed
                    obj.nInd = 1;
                    refPoints(:,2) = 0;
                    obj.plotOverlayHandles.bregma.XData=nan;
                    obj.plotOverlayHandles.bregma.YData=nan;
                else
                    obj.nInd = obj.nInd + 1;
                end %if isShiftPressed
            end %if nInd


        end %


        function calibrateSampleRescaleOutline_Callback(obj,~,evt)
            % TODO -- move out to own file
            % this is a callback that scales and rotates the ARA outline.
            C = get(obj.hImAx, 'CurrentPoint');
            X = C(1,1);
            Y = C(1,2);

            xl = obj.hImAx.XLim;
            yl = obj.hImAx.YLim;
            if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
                return
            end
        
            % The boundaries of the brain in mm
            b = obj.atlasData.whole_brain.boundaries_stereotax{1};

            if obj.nInd==1
                % follow mouse
                obj.plotOverlayHandles.brainOutline.XData = b(:,2)+X;
                obj.plotOverlayHandles.brainOutline.YData = b(:,1)+Y;
            end

            if obj.nInd==2
                % Rotate and scale only if mouse cursor is over 1 mm from bregma
                err = obj.model.refPointsSample(1,:)-[X,Y];
                if sum(sqrt(err.^2))<1.5
                    return
                end
                obj.model.refPointsSample(obj.nInd,:) = [X,Y];
                newpoint = zapit.utils.coordsRotation(fliplr(b)', obj.model.refPointsStereotaxic, obj.model.refPointsSample)';
                newpoint = fliplr(newpoint);
                obj.plotOverlayHandles.brainOutline.XData = newpoint(:,2);
                obj.plotOverlayHandles.brainOutline.YData = newpoint(:,1);
            end
        end

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



        %The following methods are callbacks from the menu TODO -- MAKE MENU
        function copyAPItoBaseWorkSpace(obj,~,~)
            fprintf('\nCreating API access components in base workspace:\nmodel: hBT\nview: hBTview\n\n')
            assignin('base','hZPview',obj)
            assignin('base','hZP',obj.model)
        end %copyAPItoBaseWorkSpace

    end


end % close classdef
