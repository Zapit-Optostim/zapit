classdef view < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        hFig                          matlab.ui.Figure
        FileMenu                      matlab.ui.container.Menu
        NewstimconfigMenu             matlab.ui.container.Menu
        LoadstimconfigMenu            matlab.ui.container.Menu
        LoadrecentMenu                matlab.ui.container.Menu
        ToolsMenu                     matlab.ui.container.Menu
        CalibratelaserMenu            matlab.ui.container.Menu
        ReloadsettingsMenu            matlab.ui.container.Menu
        HelpMenu                      matlab.ui.container.Menu
        FileGitHubissueMenu           matlab.ui.container.Menu
        GeneratesupportreportMenu     matlab.ui.container.Menu
        GridLayout                    matlab.ui.container.GridLayout
        Panel                         matlab.ui.container.Panel
        SampleCalibratedLamp          matlab.ui.control.Lamp
        SampleCalibratedLampLabel     matlab.ui.control.Label
        ScannersCalibratedLamp        matlab.ui.control.Lamp
        ScannersCalibratedLampLabel   matlab.ui.control.Label
        TabGroup                      matlab.ui.container.TabGroup
        CalibrateScannersTab          matlab.ui.container.Tab
        CheckCalibrationButton        matlab.ui.control.StateButton
        BorderBufferSpinner           matlab.ui.control.Spinner
        PointBorderBufferLabel        matlab.ui.control.Label
        PointSpacingSpinner           matlab.ui.control.Spinner
        PointSpacingLabel             matlab.ui.control.Label
        CalibLaserSwitch              matlab.ui.control.Switch
        CalibPowerSpinner             matlab.ui.control.Spinner
        CalibPowerLabel               matlab.ui.control.Label
        SizeThreshSpinner             matlab.ui.control.Spinner
        SizeThreshSpinnerLabel        matlab.ui.control.Label
        CalibExposureSpinner          matlab.ui.control.Spinner
        CalibExposureSpinnerLabel     matlab.ui.control.Label
        LaserPowerScannerCalibSlider  matlab.ui.control.Slider
        LaserPowerSliderLabel         matlab.ui.control.Label
        CatMouseButton                matlab.ui.control.StateButton
        PointModeButton               matlab.ui.control.StateButton
        RunScannerCalibrationButton   matlab.ui.control.Button
        ResetROIButton                matlab.ui.control.Button
        ROIButton                     matlab.ui.control.Button
        CalibrateSampleTab            matlab.ui.container.Tab
        PaintareaButton               matlab.ui.control.StateButton
        ZapSiteButton                 matlab.ui.control.StateButton
        ConfigLoadedNONELabel         matlab.ui.control.Label
        ShowstimcoordsButton          matlab.ui.control.StateButton
        PaintbrainborderButton        matlab.ui.control.StateButton
        CalibrateSampleButton         matlab.ui.control.Button
        TestSiteDropDown              matlab.ui.control.DropDown
        TestSiteDropDownLabel         matlab.ui.control.Label
        CycleBeamOverCoordsButton     matlab.ui.control.StateButton
        RunTab                        matlab.ui.container.Tab
        hImAx                         matlab.ui.control.UIAxes
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
            app.hFig.Tag = 'zapit_gui';

            % Create FileMenu
            app.FileMenu = uimenu(app.hFig);
            app.FileMenu.Text = 'File';

            % Create NewstimconfigMenu
            app.NewstimconfigMenu = uimenu(app.FileMenu);
            app.NewstimconfigMenu.Text = 'New stim config';

            % Create LoadstimconfigMenu
            app.LoadstimconfigMenu = uimenu(app.FileMenu);
            app.LoadstimconfigMenu.Text = 'Load stim config';

            % Create LoadrecentMenu
            app.LoadrecentMenu = uimenu(app.FileMenu);
            app.LoadrecentMenu.Text = 'Load recent';

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
            app.ROIButton.Tooltip = {'Draw a ROI and '};
            app.ROIButton.Position = [15 69 73 41];
            app.ROIButton.Text = 'ROI';

            % Create ResetROIButton
            app.ResetROIButton = uibutton(app.CalibrateScannersTab, 'push');
            app.ResetROIButton.Icon = fullfile(pathToMLAPP, 'Icons', 'icon-mat-zoom-out-map.png');
            app.ResetROIButton.Position = [15 16 73 41];
            app.ResetROIButton.Text = 'Reset';

            % Create RunScannerCalibrationButton
            app.RunScannerCalibrationButton = uibutton(app.CalibrateScannersTab, 'push');
            app.RunScannerCalibrationButton.Position = [99 69 73 41];
            app.RunScannerCalibrationButton.Text = {'Run'; 'Calibration'};

            % Create PointModeButton
            app.PointModeButton = uibutton(app.CalibrateScannersTab, 'state');
            app.PointModeButton.Text = {'Point'; 'Mode'};
            app.PointModeButton.Position = [186 69 73 41];

            % Create CatMouseButton
            app.CatMouseButton = uibutton(app.CalibrateScannersTab, 'state');
            app.CatMouseButton.Text = {'Cat &'; 'Mouse'};
            app.CatMouseButton.Position = [186 17 73 41];

            % Create LaserPowerSliderLabel
            app.LaserPowerSliderLabel = uilabel(app.CalibrateScannersTab);
            app.LaserPowerSliderLabel.HorizontalAlignment = 'center';
            app.LaserPowerSliderLabel.Position = [279 93 150 22];
            app.LaserPowerSliderLabel.Text = 'Laser Power';

            % Create LaserPowerScannerCalibSlider
            app.LaserPowerScannerCalibSlider = uislider(app.CalibrateScannersTab);
            app.LaserPowerScannerCalibSlider.Position = [279 92 150 3];

            % Create CalibExposureSpinnerLabel
            app.CalibExposureSpinnerLabel = uilabel(app.CalibrateScannersTab);
            app.CalibExposureSpinnerLabel.HorizontalAlignment = 'right';
            app.CalibExposureSpinnerLabel.Position = [266 5 87 22];
            app.CalibExposureSpinnerLabel.Text = 'Calib Exposure';

            % Create CalibExposureSpinner
            app.CalibExposureSpinner = uispinner(app.CalibrateScannersTab);
            app.CalibExposureSpinner.Position = [364 5 76 22];

            % Create SizeThreshSpinnerLabel
            app.SizeThreshSpinnerLabel = uilabel(app.CalibrateScannersTab);
            app.SizeThreshSpinnerLabel.HorizontalAlignment = 'right';
            app.SizeThreshSpinnerLabel.Position = [594 16 69 22];
            app.SizeThreshSpinnerLabel.Text = 'Size Thresh';

            % Create SizeThreshSpinner
            app.SizeThreshSpinner = uispinner(app.CalibrateScannersTab);
            app.SizeThreshSpinner.Position = [670 16 62 22];

            % Create CalibPowerLabel
            app.CalibPowerLabel = uilabel(app.CalibrateScannersTab);
            app.CalibPowerLabel.HorizontalAlignment = 'right';
            app.CalibPowerLabel.Position = [283 36 70 22];
            app.CalibPowerLabel.Text = 'Calib Power';

            % Create CalibPowerSpinner
            app.CalibPowerSpinner = uispinner(app.CalibrateScannersTab);
            app.CalibPowerSpinner.Position = [364 36 49 22];

            % Create CalibLaserSwitch
            app.CalibLaserSwitch = uiswitch(app.CalibrateScannersTab, 'slider');
            app.CalibLaserSwitch.Position = [471 83 45 20];

            % Create PointSpacingLabel
            app.PointSpacingLabel = uilabel(app.CalibrateScannersTab);
            app.PointSpacingLabel.HorizontalAlignment = 'right';
            app.PointSpacingLabel.Position = [583 88 80 22];
            app.PointSpacingLabel.Text = 'Point Spacing';

            % Create PointSpacingSpinner
            app.PointSpacingSpinner = uispinner(app.CalibrateScannersTab);
            app.PointSpacingSpinner.Position = [670 88 62 22];

            % Create PointBorderBufferLabel
            app.PointBorderBufferLabel = uilabel(app.CalibrateScannersTab);
            app.PointBorderBufferLabel.HorizontalAlignment = 'right';
            app.PointBorderBufferLabel.Position = [586 52 77 22];
            app.PointBorderBufferLabel.Text = 'Border Buffer';

            % Create BorderBufferSpinner
            app.BorderBufferSpinner = uispinner(app.CalibrateScannersTab);
            app.BorderBufferSpinner.Position = [670 52 62 22];

            % Create CheckCalibrationButton
            app.CheckCalibrationButton = uibutton(app.CalibrateScannersTab, 'state');
            app.CheckCalibrationButton.Text = {'Check'; 'Calibration'};
            app.CheckCalibrationButton.Position = [99 16 73 41];

            % Create CalibrateSampleTab
            app.CalibrateSampleTab = uitab(app.TabGroup);
            app.CalibrateSampleTab.Title = 'Calibrate Sample';

            % Create CycleBeamOverCoordsButton
            app.CycleBeamOverCoordsButton = uibutton(app.CalibrateSampleTab, 'state');
            app.CycleBeamOverCoordsButton.Text = {'Cycle Beam'; 'Over Coords'};
            app.CycleBeamOverCoordsButton.Position = [151 45 112 36];

            % Create TestSiteDropDownLabel
            app.TestSiteDropDownLabel = uilabel(app.CalibrateSampleTab);
            app.TestSiteDropDownLabel.HorizontalAlignment = 'right';
            app.TestSiteDropDownLabel.Position = [291 88 52 22];
            app.TestSiteDropDownLabel.Text = 'Test Site';

            % Create TestSiteDropDown
            app.TestSiteDropDown = uidropdown(app.CalibrateSampleTab);
            app.TestSiteDropDown.Position = [358 88 100 22];

            % Create CalibrateSampleButton
            app.CalibrateSampleButton = uibutton(app.CalibrateSampleTab, 'push');
            app.CalibrateSampleButton.Position = [15 88 112 22];
            app.CalibrateSampleButton.Text = 'Calibrate Sample';

            % Create PaintbrainborderButton
            app.PaintbrainborderButton = uibutton(app.CalibrateSampleTab, 'state');
            app.PaintbrainborderButton.Text = 'Paint brain border';
            app.PaintbrainborderButton.Position = [15 60 112 22];

            % Create ShowstimcoordsButton
            app.ShowstimcoordsButton = uibutton(app.CalibrateSampleTab, 'state');
            app.ShowstimcoordsButton.Text = 'Show stim coords';
            app.ShowstimcoordsButton.Position = [151 88 112 22];

            % Create ConfigLoadedNONELabel
            app.ConfigLoadedNONELabel = uilabel(app.CalibrateSampleTab);
            app.ConfigLoadedNONELabel.Position = [17 5 396 22];
            app.ConfigLoadedNONELabel.Text = 'Config Loaded: NONE';

            % Create ZapSiteButton
            app.ZapSiteButton = uibutton(app.CalibrateSampleTab, 'state');
            app.ZapSiteButton.Text = 'Zap Site';
            app.ZapSiteButton.Position = [461 88 69 22];

            % Create PaintareaButton
            app.PaintareaButton = uibutton(app.CalibrateSampleTab, 'state');
            app.PaintareaButton.Text = 'Paint area';
            app.PaintareaButton.Position = [533 88 70 22];

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