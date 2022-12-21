classdef view < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        hFig                         matlab.ui.Figure
        ToolsMenu                    matlab.ui.container.Menu
        CalibratelaserMenu           matlab.ui.container.Menu
        ReloadsettingsMenu           matlab.ui.container.Menu
        HelpMenu                     matlab.ui.container.Menu
        FileGitHubissueMenu          matlab.ui.container.Menu
        GeneratesupportreportMenu    matlab.ui.container.Menu
        GridLayout                   matlab.ui.container.GridLayout
        Panel                        matlab.ui.container.Panel
        SampleCalibratedLamp         matlab.ui.control.Lamp
        SampleCalibratedLampLabel    matlab.ui.control.Label
        ScannersCalibratedLamp       matlab.ui.control.Lamp
        ScannersCalibratedLampLabel  matlab.ui.control.Label
        TabGroup                     matlab.ui.container.TabGroup
        CalibrateScannersTab         matlab.ui.container.Tab
        SizeThreshSpinner            matlab.ui.control.Spinner
        SizeThreshSpinnerLabel       matlab.ui.control.Label
        CalibExposureSpinner         matlab.ui.control.Spinner
        CalibExposureSpinnerLabel    matlab.ui.control.Label
        LaserPowerSlider             matlab.ui.control.Slider
        LaserPowerSliderLabel        matlab.ui.control.Label
        CatMouseButton               matlab.ui.control.StateButton
        PointModeButton              matlab.ui.control.StateButton
        TestCalibrationButton        matlab.ui.control.Button
        RunScannerCalibrationButton  matlab.ui.control.Button
        ResetROIButton               matlab.ui.control.Button
        ROIButton                    matlab.ui.control.Button
        CalibrateSampleTab           matlab.ui.container.Tab
        RunTab                       matlab.ui.container.Tab
        hImAx                        matlab.ui.control.UIAxes
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create hFig and hide until all components are created
            app.hFig = uifigure('Visible', 'off');
            app.hFig.Position = [100 100 771 820];
            app.hFig.Name = 'Zapit';
            app.hFig.Resize = 'off';

            % Create ToolsMenu
            app.ToolsMenu = uimenu(app.hFig);
            app.ToolsMenu.Text = 'Tools';

            % Create CalibratelaserMenu
            app.CalibratelaserMenu = uimenu(app.ToolsMenu);
            app.CalibratelaserMenu.Text = 'Calibrate laser';

            % Create ReloadsettingsMenu
            app.ReloadsettingsMenu = uimenu(app.ToolsMenu);
            app.ReloadsettingsMenu.Text = 'Reload settings';

            % Create HelpMenu
            app.HelpMenu = uimenu(app.hFig);
            app.HelpMenu.Text = 'Help';

            % Create FileGitHubissueMenu
            app.FileGitHubissueMenu = uimenu(app.HelpMenu);
            app.FileGitHubissueMenu.Text = 'File GitHub issue';

            % Create GeneratesupportreportMenu
            app.GeneratesupportreportMenu = uimenu(app.HelpMenu);
            app.GeneratesupportreportMenu.Text = 'Generate support report';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.hFig);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'4x', '1x', '0.25x'};

            % Create hImAx
            app.hImAx = uiaxes(app.GridLayout);
            app.hImAx.Toolbar.Visible = 'off';
            app.hImAx.Box = 'on';
            app.hImAx.Layout.Row = 1;
            app.hImAx.Layout.Column = 1;
            colormap(app.hImAx, 'gray')

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 2;
            app.TabGroup.Layout.Column = 1;

            % Create CalibrateScannersTab
            app.CalibrateScannersTab = uitab(app.TabGroup);
            app.CalibrateScannersTab.Title = 'Calibrate Scanners';

            % Create ROIButton
            app.ROIButton = uibutton(app.CalibrateScannersTab, 'push');
            app.ROIButton.Icon = fullfile(pathToMLAPP, 'Icons', 'icon-mat-zoom-in.png');
            app.ROIButton.Position = [15 69 105 41];
            app.ROIButton.Text = 'ROI';

            % Create ResetROIButton
            app.ResetROIButton = uibutton(app.CalibrateScannersTab, 'push');
            app.ResetROIButton.Icon = fullfile(pathToMLAPP, 'Icons', 'icon-mat-zoom-out-map.png');
            app.ResetROIButton.Position = [15 16 105 41];
            app.ResetROIButton.Text = 'Reset ROI';

            % Create RunScannerCalibrationButton
            app.RunScannerCalibrationButton = uibutton(app.CalibrateScannersTab, 'push');
            app.RunScannerCalibrationButton.Position = [149 69 100 41];
            app.RunScannerCalibrationButton.Text = 'Run Calibration';

            % Create TestCalibrationButton
            app.TestCalibrationButton = uibutton(app.CalibrateScannersTab, 'push');
            app.TestCalibrationButton.Position = [149 16 101 41];
            app.TestCalibrationButton.Text = ' Test Calibration';

            % Create PointModeButton
            app.PointModeButton = uibutton(app.CalibrateScannersTab, 'state');
            app.PointModeButton.Text = 'Point Mode';
            app.PointModeButton.Position = [274 69 100 41];

            % Create CatMouseButton
            app.CatMouseButton = uibutton(app.CalibrateScannersTab, 'state');
            app.CatMouseButton.Text = 'Cat & Mouse';
            app.CatMouseButton.Position = [274 16 100 41];

            % Create LaserPowerSliderLabel
            app.LaserPowerSliderLabel = uilabel(app.CalibrateScannersTab);
            app.LaserPowerSliderLabel.HorizontalAlignment = 'center';
            app.LaserPowerSliderLabel.Position = [405 88 150 22];
            app.LaserPowerSliderLabel.Text = 'Laser Power';

            % Create LaserPowerSlider
            app.LaserPowerSlider = uislider(app.CalibrateScannersTab);
            app.LaserPowerSlider.Position = [405 87 150 3];

            % Create CalibExposureSpinnerLabel
            app.CalibExposureSpinnerLabel = uilabel(app.CalibrateScannersTab);
            app.CalibExposureSpinnerLabel.HorizontalAlignment = 'right';
            app.CalibExposureSpinnerLabel.Position = [392 16 87 22];
            app.CalibExposureSpinnerLabel.Text = 'Calib Exposure';

            % Create CalibExposureSpinner
            app.CalibExposureSpinner = uispinner(app.CalibrateScannersTab);
            app.CalibExposureSpinner.Position = [491 16 75 22];

            % Create SizeThreshSpinnerLabel
            app.SizeThreshSpinnerLabel = uilabel(app.CalibrateScannersTab);
            app.SizeThreshSpinnerLabel.HorizontalAlignment = 'right';
            app.SizeThreshSpinnerLabel.Position = [594 16 69 22];
            app.SizeThreshSpinnerLabel.Text = 'Size Thresh';

            % Create SizeThreshSpinner
            app.SizeThreshSpinner = uispinner(app.CalibrateScannersTab);
            app.SizeThreshSpinner.Position = [670 16 62 22];

            % Create CalibrateSampleTab
            app.CalibrateSampleTab = uitab(app.TabGroup);
            app.CalibrateSampleTab.Title = 'Calibrate Sample';

            % Create RunTab
            app.RunTab = uitab(app.TabGroup);
            app.RunTab.Title = 'Run!';

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.Layout.Row = 3;
            app.Panel.Layout.Column = 1;

            % Create ScannersCalibratedLampLabel
            app.ScannersCalibratedLampLabel = uilabel(app.Panel);
            app.ScannersCalibratedLampLabel.HorizontalAlignment = 'right';
            app.ScannersCalibratedLampLabel.Position = [1 7 114 22];
            app.ScannersCalibratedLampLabel.Text = 'Scanners Calibrated';

            % Create ScannersCalibratedLamp
            app.ScannersCalibratedLamp = uilamp(app.Panel);
            app.ScannersCalibratedLamp.Position = [130 7 20 20];
            app.ScannersCalibratedLamp.Color = [1 0 0];

            % Create SampleCalibratedLampLabel
            app.SampleCalibratedLampLabel = uilabel(app.Panel);
            app.SampleCalibratedLampLabel.HorizontalAlignment = 'right';
            app.SampleCalibratedLampLabel.Position = [171 7 104 22];
            app.SampleCalibratedLampLabel.Text = 'Sample Calibrated';

            % Create SampleCalibratedLamp
            app.SampleCalibratedLamp = uilamp(app.Panel);
            app.SampleCalibratedLamp.Position = [290 7 20 20];
            app.SampleCalibratedLamp.Color = [1 0 0];

            % Show the figure after all components are created
            app.hFig.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = view

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.hFig)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.hFig)
        end
    end
end