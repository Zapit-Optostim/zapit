classdef controller < zapit.gui.main.view

    % zapit.gui.main.view is the main GUI window: that which first appears when the 
    % user starts the software.
    %
    % The GUI itself is made in MATLAB AppDesigner and is inherited by this class

    properties
        % Handles for some plot elements are inherited from the superclass

        hImLive  %The image
        plotOverlayHandles   % All plotted objects laid over the image should keep their handles here

        model % The ZP model object goes here
        atlasData % Brain atlas data for overlaying brain areas, etc
        recentLoadedConfigsMenu = {} % Contains the menu vector for recently loaded configs
        listeners = {}; % All go in this cell array
    end


    properties(Hidden)
        laserPowerBeforeCalib % Used to reset the laser power to the value it had before calibration
        nInd % a counter used by calibrateSample_Callback
        hStimConfigEditor
        hLaserPowerGUI
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

            % Load the cache file so the GUI returns to its previous state
            obj.loadGUIcache

            % Attempt to report when figure is open
            %getframe(obj.hImAx)
            %fprintf('DONE\n')
        end %close constructor


        function delete(obj,~,~)
            fprintf('zapit.gui.main.view is cleaning up\n')
            cellfun(@delete,obj.listeners)
            delete(obj.model);

            obj.model=[];

            delete(obj.hFig);
            delete(obj.hStimConfigEditor)
            delete(obj.hLaserPowerGUI)

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

            % Set the figure title to reflect the version number
            zv = zapit.version;
            obj.hFig.Name = ['Zapit v', zv.version.string];

            % Update elements from settings file
            % TODO: changing the settings spin boxes should change the settings file
            obj.CalibPowerSpinner.Value = obj.model.settings.calibrateScanners.calibration_power_mW;
            obj.LaserPowerScannerCalibSlider.Value = obj.CalibPowerSpinner.Value;
            obj.PointSpacingSpinner.Value = obj.model.settings.calibrateScanners.pointSpacingInPixels;
            obj.BorderBufferSpinner.Value = obj.model.settings.calibrateScanners.bufferPixels;
            obj.SizeThreshSpinner.Value = obj.model.settings.calibrateScanners.areaThreshold;
            obj.CalibExposureSpinner.Value = obj.model.settings.calibrateScanners.beam_calib_exposure;

            % Disable the reference AP dropdown
            obj.RefAPDropDown.Enable='off';

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

            obj.CalibrateSampleButton.ButtonPushedFcn = @(~,~) obj.calibrateSample_Callback;
            obj.ShowstimcoordsButton.ValueChangedFcn = @(~,~) obj.showStimulusCoords_Callback;
            obj.CycleBeamOverCoordsButton.ValueChangedFcn = @(~,~) obj.cycleBeamOverCoords_Callback;
            obj.ZapSiteButton.ValueChangedFcn = @(~,~) obj.zapSite_Callback;


            obj.PaintareaButton.Enable = 'off'; % DISABLE UNTIL THIS WORKS
            %obj.PaintareaButton.ValueChangedFcn = @(~,~) obj.paintArea_Callback;
            obj.PaintbrainborderButton.ValueChangedFcn = @(~,~) obj.paintBrainBorder_Callback;

            % This callback runs when the tab is changed. This is to ensure that the GUI is
            % tidied in any relevant ways when switching to a new tab
            obj.TabGroup.SelectionChangedFcn = @(src,~) obj.tabChange_Callback(src);

            % Menus
            obj.NewstimconfigMenu.MenuSelectedFcn = @(~,~) obj.createNewStimConfig_Callback;
            obj.LoadstimconfigMenu.MenuSelectedFcn = @(src,~) obj.loadStimConfig_Callback(src);
            obj.FileMenu.MenuSelectedFcn = @(~,~) obj.removeMissingRecentConfigs; % So menu updates if files change
            obj.FileGitHubissueMenu.MenuSelectedFcn = @(~,~) web('https://github.com/BaselLaserMouse/zapit/issues');
            obj.GeneratesupportreportMenu.MenuSelectedFcn = @(~,~) zapit.utils.generateSupportReport;


            % Set GUI state based on calibration state
            obj.scannersCalibrateCallback
            obj.sampleCalibrateCallback

            % If in simulated mode, disable UI elements that are not functional right now
            if obj.model.simulated
                obj.RunScannerCalibrationButton.Enable = 'off';
                obj.PointModeButton.Enable = 'off';
                obj.CatMouseButton.Enable = 'off';
                obj.PaintbrainborderButton.Enable = 'off';
                obj.CycleBeamOverCoordsButton.Enable = 'off';
                obj.ZapSiteButton.Enable = 'off';
            end
        end


        function addLastPointLocationMarker(obj)
            % Add marker showing last point location
            hold(obj.hImAx,'on')
            obj.plotOverlayHandles.hLastPoint = plot(nan, nan,'or','MarkerSize',10, ...
                'LineWidth', 2, 'Parent',obj.hImAx);
            hold(obj.hImAx,'off')
            % Set GUI state based on calibration state
            obj.scannersCalibrateCallback
            obj.sampleCalibrateCallback
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
            obj.refreshImage;
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


        function fname = GUIcacheLocation(obj)
            % Return the location of the GUI cache file
            s=zapit.settings.findSettingsFile;
            fname = fullfile(fileparts(s),'zapitGUIcache.mat');
        end



        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



        %The following methods are callbacks from the menu
        function copyAPItoBaseWorkSpace(obj,~,~)
            fprintf('\nCreating API access components in base workspace:\nmodel: hBT\nview: hBTview\n\n')
            assignin('base','hZPview',obj)
            assignin('base','hZP',obj.model)
        end %copyAPItoBaseWorkSpace

    end


end % close classdef
