classdef controller < zapit.gui.main.view

    % Controller class for main Zapit GUI
    %
    % zapit.gui.main.controller
    %
    % Purpose
    % The "main" Zapit GUI is that which appears when the user runs "start_zapit".
    % This class runs this GUI by controlling the elements defined by zapit.gui.main.view, 
    % which it inherits. The view class is made in MATLAB AppDesigner and is not modified in
    % any way. All changes are made programatically by this class. The controller also 
    % interfaces with the Zapit API (the "model") which controls the hardware.
    % 
    %
    % Rob Campbell - SWC 2022


    properties
        % Note that handles for most plot elements are inherited from the view class

        hImLive              % The image
        plotOverlayHandles   % All plotted objects laid over the image should keep their handles here

        model     % The zapit.pointer object that runs the hardware
        atlasData % Brain atlas data for overlaying brain areas, etc
        recentLoadedConfigsMenu = {} % Contains the menu vector for recently loaded configs
        listeners = {}; % All go in this cell array
    end


    properties(Hidden)
        laserPowerBeforeCalib % Used to reset the laser power to the value it had before calibration
        nInd                  % A counter used by calibrateSample_Callback
        hStimConfigEditor     % The stim config editor (for making new stim config files)
        hLaserPowerGUI        % GUI for calibrating laser power
    end


    properties(Hidden,SetObservable=true)
        % The following are used to build the recently loaded stim config drop-down
        % A structure that contains names and paths to recently loaded stim config files.
        previouslyLoadedStimConfigs = struct('fname', '', 'pathToFname', '', 'timeAdded', []);
        maxPreviouslyLoadedStimConfigs = 10 % Max number to display. 
    end


    methods

        function obj = controller(hZP)
            % Constructor of zapit.gui.main.controller
            %
            % zapit.gui.main.controller.controller

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

            % Prepare the window and add listeners
            obj.prepareWindow
            obj.buildListeners

            % Load the cache file so the GUI returns to its previous state
            obj.loadGUIcache

            % Attempt to report when figure is open
            %getframe(obj.hImAx)
            %fprintf('DONE\n')
        end %close constructor


        function delete(obj,~,~)
            % Destructor zapit.gui.main.controller
            %
            % zapit.gui.main.controller.delete

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
    end % constructor/destructor end


    % Short hidden methods follow
    methods(Hidden)

        function fname = GUIcacheLocation(obj)
            % Return the location of the GUI cache file
            s=zapit.settings.findSettingsFile;
            fname = fullfile(fileparts(s),'zapitGUIcache.mat');
        end % GUIcacheLocation


        function closeZapit(obj,~,~)
            % Confirm and quit Zapit (also closing the model and so disconnecting from hardware)
            %
            % zapit.gui.main.controller.closeZapit
            %
            % Purpose
            % This method runs when the user presses the close.

            choice = questdlg('Are you sure you want to quit Zapit?', '', 'Yes', 'No', 'No');

            switch choice
                case 'No'
                    %pass
                case 'Yes'
                    obj.delete
            end
        end % closeZapit


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
            %
            % zapit.gui.main.controller.scannersCalibrateCallback
            %
            % Purpose
            % Set the scanner calibration light and enable/disable plot elements.

            obj.set_scannersLampCalibrated(obj.model.scannersCalibrated)

            if obj.model.scannersCalibrated
                obj.CheckCalibrationButton.Enable = 'on';
            else
                obj.CheckCalibrationButton.Enable = 'off';
            end
        end % scannersCalibrateCallback


        function sampleCalibrateCallback(obj,~,~)
            % Perform any actions needed upon change in sample calibration state
            %
            % zapit.gui.main.controller.sampleCalibrateCallback
            %
            % Purpose
            % Set the sample calibration light.

            obj.set_sampleLampCalibrated(obj.model.sampleCalibrated)
        end % sampleCalibrateCallback


        function set_scannersLampCalibrated(obj,calibrated)
            % Set lamp state for scanner calibration
            %
            % zapit.gui.main.controller.set_scannersLampCalibrated
            %
            % Purpose
            % Switch lamp between red and green based on calibration state.

            if calibrated
                obj.ScannersCalibratedLamp.Color = [0 1 0];
            else
                obj.ScannersCalibratedLamp.Color = [1 0 0];
            end
        end % set_scannersLampCalibrated


        function set_sampleLampCalibrated(obj,calibrated)
            % Set lamp state for sample calibration
            %
            % zapit.gui.main.controller.set_sampleLampCalibrated
            %
            % Purpose
            % Switch lamp between red and green based on calibration state.

            if calibrated
                obj.SampleCalibratedLamp.Color = [0 1 0];
            else
                obj.SampleCalibratedLamp.Color = [1 0 0];
            end
        end % set_sampleLampCalibrated


        function setLaserPower_Callback(obj,src,event)
            % Set laser to listed power when switch is set to On
            %
            % zapit.gui.main.controller.setLaserPower_Callback
            %
            % Purpose
            % Runs when the laser power slider is changed. If the laser calibration 
            % switch is On, the laser power is set to the power level listed in the 
            % laser slideer.

            if strcmp(obj.CalibLaserSwitch.Value,'On')
                obj.model.setLaserInMW(event.Value)
            end
        end % setLaserPower_Callback


        function switchLaser_Callback(obj,~,~)
            % Turn on the laser when the switch is turned on
            %
            % zapit.gui.main.controller.switchLaser_Callback
            %
            % Purpose
            % Turning on the laser power switch turns on the laser to the power listed
            % on the slider.

            if strcmp(obj.CalibLaserSwitch.Value,'On')
                obj.model.setLaserInMW(obj.LaserPowerScannerCalibSlider.Value);
            else
                obj.model.setLaserInMW(0)
            end
        end % switchLaser_Callback


        function setCalibLaserSwitch(obj,value)
            % Because changing the switch value programmaticaly does not
            % fire the callback. WHY DID TMW THEY DO THIS?!
            %
            % zapit.gui.main.controller.setCalibLaserSwitch
            if ~char(value)
                return
            end
            if ~strcmp(value,'On') && ~strcmp(value,'Off')
                return
            end
            obj.CalibLaserSwitch.Value = value;
            obj.switchLaser_Callback
        end % setCalibLaserSwitch


        function pointSpacing_CallBack(obj,~,~)
            %
            % zapit.gui.main.controller.pointSpacing_CallBack
            %
            % Purpose
            % Changing the spinnerbox writes to the corresponding value in the settings structure. 

            obj.model.settings.calibrateScanners.pointSpacingInPixels = obj.PointSpacingSpinner.Value;
        end % pointSpacing_CallBack


        function borderBuffer_CallBack(obj,~,~)
            %
            % zapit.gui.main.controller.borderBuffer_CallBack
            %
            % Purpose
            % Changing the spinnerbox writes to the corresponding value in the settings structure. 

            obj.model.settings.calibrateScanners.bufferPixels = obj.BorderBufferSpinner.Value;
        end % borderBuffer_CallBack


        function sizeThreshSpinner_CallBack(obj,~,~)
            %
            % zapit.gui.main.controller.sizeThreshSpinner_CallBack
            %
            % Purpose
            % Changing the spinnerbox writes to the corresponding value in the settings structure. 

            if obj.SizeThreshSpinner.Value < 1
                obj.SizeThreshSpinner.Value = 1;
            end
            obj.model.settings.calibrateScanners.areaThreshold = obj.SizeThreshSpinner.Value;
        end % sizeThreshSpinner_CallBack


        function calibExposureSpinner_CallBack(obj,~,~)
            %
            % zapit.gui.main.controller.calibExposureSpinner_CallBack
            %
            % Purpose
            % Changing the spinnerbox writes to the corresponding value in the settings structure. 

            if obj.CalibExposureSpinner.Value < 0
                obj.CalibExposureSpinner.Value = 0;
            end
            obj.model.settings.calibrateScanners.beam_calib_exposure = obj.CalibExposureSpinner.Value;
        end % calibExposureSpinner_CallBack

    end % methods


end % close classdef