classdef controller < zapit.gui.main.view

    % zapit.gui.view is the main GUI window: that which first appears when the 
    % user starts the software.
    %
    % The GUI itself is made in MATLAB AppDesigner and is inherited by this class

    properties
        % Handles for some plot elements are inherited from the superclass

        hImLive  %The image
        hLastPoint % plot handle with location of the last clicked point. TODO-- do we leave this here? It's a unique one. 
        plotOverlayHandles   % All plotted objects laid over the image should keep their handles here

        model % The ZP model object goes here

        listeners = {}; % All go in this cell array
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

            % Add a listener to the sampleSavePath property of the BT model
            %% obj.listeners{end+1} = addlistener(obj.model, 'sampleSavePath', 'PostSet', @obj.updateSampleSavePathBox); % FOR EXAMPLE
            obj.prepareWindow
            obj.buildListeners

            % Call the class destructor when figure is closed. This ensures all
            % the hardware tasks are stopped.
            obj.hFig.CloseRequestFcn = @obj.delete;
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

            % Insert and empty image into axes
            obj.hImLive = image(zeros(obj.model.imSize),'Parent',obj.hImAx);
            obj.hImAx.XTick = [];
            obj.hImAx.YTick = [];
            obj.hImAx.DataAspectRatio = [1,1,1]; % Make axis aspect ratio square

            % Set axis limits
            imSize = obj.model.imSize;
            obj.hImAx.XLim = [0,imSize(1)];
            obj.hImAx.YLim = [0,imSize(2)];

            hold(obj.hImAx,'on')
            obj.hLastPoint = plot(obj.hImAx,nan,nan,'or','MarkerSize',8,'LineWidth',1);
            hold(obj.hImAx,'off')

            % Run method on mouse click
            obj.hImLive.ButtonDownFcn = @obj.pointBeamToLocationInImage;

            obj.ResetROIButton.ButtonPushedFcn = @(~,~) obj.model.cam.resetROI;
            obj.RunScannerCalibrationButton.ButtonPushedFcn = @(~,~) obj.calibrateScanners_Callback;
            obj.TestCalibrationButton.ButtonPushedFcn = @(~,~) obj.checkScannerCalib_Callback;

            % Set GUI state baseon calibration
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


        end


        function scannersCalibrateCallback(obj,~,~)
            % Perform any actions needed upon change in scanner calibration state
            obj.set_scannersLampCalibrated(obj.model.scannersCalibrated)

            if obj.model.scannersCalibrated
                obj.TestCalibrationButton.Enable = 'on';
            else
                obj.TestCalibrationButton.Enable = 'off';
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
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



        %The following methods are callbacks from the menu TODO -- MAKE MENU
        function copyAPItoBaseWorkSpace(obj,~,~)
            fprintf('\nCreating API access components in base workspace:\nmodel: hBT\nview: hBTview\n\n')
            assignin('base','hZPview',obj)
            assignin('base','hZP',obj.model)
        end %copyAPItoBaseWorkSpace

    end


end % close classdef
