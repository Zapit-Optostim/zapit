classdef view < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        hFig                           matlab.ui.Figure
        FileMenu                       matlab.ui.container.Menu
        NewstimconfigMenu              matlab.ui.container.Menu
        LoadstimconfigMenu             matlab.ui.container.Menu
        LoadrecentMenu                 matlab.ui.container.Menu
        ToolsMenu                      matlab.ui.container.Menu
        CalibratelaserMenu             matlab.ui.container.Menu
        ReloadsettingsMenu             matlab.ui.container.Menu
        HelpMenu                       matlab.ui.container.Menu
        FileGitHubissueMenu            matlab.ui.container.Menu
        GeneratesupportreportMenu      matlab.ui.container.Menu
        GridLayout                     matlab.ui.container.GridLayout
        Panel                          matlab.ui.container.Panel
        ConfigLoadedTextLabel          matlab.ui.control.Label
        SampleCalibratedLamp           matlab.ui.control.Lamp
        SampleCalibratedLampLabel      matlab.ui.control.Label
        ScannersCalibratedLamp         matlab.ui.control.Lamp
        ScannersCalibratedLampLabel    matlab.ui.control.Label
        TabGroup                       matlab.ui.container.TabGroup
        CalibrateScannersTab           matlab.ui.container.Tab
        CalibratePanel                 matlab.ui.container.Panel
        CheckCalibrationButton         matlab.ui.control.StateButton
        CatMouseButton                 matlab.ui.control.StateButton
        PointModeButton                matlab.ui.control.StateButton
        RunScannerCalibrationButton    matlab.ui.control.Button
        CameraPanel                    matlab.ui.container.Panel
        ResetROIButton                 matlab.ui.control.Button
        ROIButton                      matlab.ui.control.Button
        LaserpowerPanel                matlab.ui.container.Panel
        CalibLaserSwitch               matlab.ui.control.Switch
        LaserPowerScannerCalibSlider   matlab.ui.control.Slider
        CalibrationpowerexposurePanel  matlab.ui.container.Panel
        CalibExposureSpinner           matlab.ui.control.Spinner
        ExposureSpinnerLabel           matlab.ui.control.Label
        CalibPowerSpinner              matlab.ui.control.Spinner
        CalibPowerLabel                matlab.ui.control.Label
        CalibrationgridsettingsPanel   matlab.ui.container.Panel
        SizeThreshSpinner              matlab.ui.control.Spinner
        SizeThreshSpinnerLabel         matlab.ui.control.Label
        BorderBufferSpinner            matlab.ui.control.Spinner
        PointBorderBufferLabel         matlab.ui.control.Label
        PointSpacingSpinner            matlab.ui.control.Spinner
        PointSpacingLabel              matlab.ui.control.Label
        CalibrateSampleTab             matlab.ui.container.Tab
        RunPanel                       matlab.ui.container.Panel
        ClearpathButton                matlab.ui.control.Button
        ExperimentPathTextArea         matlab.ui.control.TextArea
        ExportwaveformsButton          matlab.ui.control.Button
        SetexperimentpathButton        matlab.ui.control.Button
        ConfirmstimuluslocationsPanel  matlab.ui.container.Panel
        PlotstimcoordsButton           matlab.ui.control.Button
        PaintareaButton                matlab.ui.control.StateButton
        ZapSiteButton                  matlab.ui.control.StateButton
        TestSiteDropDown               matlab.ui.control.DropDown
        OverlaystimsitesButton         matlab.ui.control.StateButton
        ZapallcoordsButton             matlab.ui.control.StateButton
        CalibrationPanel               matlab.ui.container.Panel
        PaintbrainborderButton         matlab.ui.control.StateButton
        CalibrateSampleButton          matlab.ui.control.Button
        RefAPDropDown                  matlab.ui.control.DropDown
        RefAPDropDownLabel             matlab.ui.control.Label
        hImAx                          matlab.ui.control.UIAxes
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

            % Create CalibrationgridsettingsPanel
            app.CalibrationgridsettingsPanel = uipanel(app.CalibrateScannersTab);
            app.CalibrationgridsettingsPanel.BorderType = 'none';
            app.CalibrationgridsettingsPanel.Title = 'Calibration grid settings';
            app.CalibrationgridsettingsPanel.Position = [592 16 151 108];

            % Create PointSpacingLabel
            app.PointSpacingLabel = uilabel(app.CalibrationgridsettingsPanel);
            app.PointSpacingLabel.HorizontalAlignment = 'right';
            app.PointSpacingLabel.Position = [2 59 80 22];
            app.PointSpacingLabel.Text = 'Point Spacing';

            % Create PointSpacingSpinner
            app.PointSpacingSpinner = uispinner(app.CalibrationgridsettingsPanel);
            app.PointSpacingSpinner.Position = [88 59 62 22];

            % Create PointBorderBufferLabel
            app.PointBorderBufferLabel = uilabel(app.CalibrationgridsettingsPanel);
            app.PointBorderBufferLabel.HorizontalAlignment = 'right';
            app.PointBorderBufferLabel.Position = [5 31 77 22];
            app.PointBorderBufferLabel.Text = 'Border Buffer';

            % Create BorderBufferSpinner
            app.BorderBufferSpinner = uispinner(app.CalibrationgridsettingsPanel);
            app.BorderBufferSpinner.Position = [88 31 62 22];

            % Create SizeThreshSpinnerLabel
            app.SizeThreshSpinnerLabel = uilabel(app.CalibrationgridsettingsPanel);
            app.SizeThreshSpinnerLabel.HorizontalAlignment = 'right';
            app.SizeThreshSpinnerLabel.Position = [13 3 69 22];
            app.SizeThreshSpinnerLabel.Text = 'Size Thresh';

            % Create SizeThreshSpinner
            app.SizeThreshSpinner = uispinner(app.CalibrationgridsettingsPanel);
            app.SizeThreshSpinner.Position = [88 3 62 22];

            % Create CalibrationpowerexposurePanel
            app.CalibrationpowerexposurePanel = uipanel(app.CalibrateScannersTab);
            app.CalibrationpowerexposurePanel.BorderType = 'none';
            app.CalibrationpowerexposurePanel.Title = 'Calibration power & exposure';
            app.CalibrationpowerexposurePanel.Position = [301 67 281 57];

            % Create CalibPowerLabel
            app.CalibPowerLabel = uilabel(app.CalibrationpowerexposurePanel);
            app.CalibPowerLabel.HorizontalAlignment = 'right';
            app.CalibPowerLabel.Position = [14 10 39 22];
            app.CalibPowerLabel.Text = 'Power';

            % Create CalibPowerSpinner
            app.CalibPowerSpinner = uispinner(app.CalibrationpowerexposurePanel);
            app.CalibPowerSpinner.Position = [61 10 49 22];

            % Create ExposureSpinnerLabel
            app.ExposureSpinnerLabel = uilabel(app.CalibrationpowerexposurePanel);
            app.ExposureSpinnerLabel.HorizontalAlignment = 'right';
            app.ExposureSpinnerLabel.Position = [125 11 56 22];
            app.ExposureSpinnerLabel.Text = 'Exposure';

            % Create CalibExposureSpinner
            app.CalibExposureSpinner = uispinner(app.CalibrationpowerexposurePanel);
            app.CalibExposureSpinner.Position = [186 10 76 22];

            % Create LaserpowerPanel
            app.LaserpowerPanel = uipanel(app.CalibrateScannersTab);
            app.LaserpowerPanel.BorderType = 'none';
            app.LaserpowerPanel.Title = 'Laser power';
            app.LaserpowerPanel.Position = [301 1 281 66];

            % Create LaserPowerScannerCalibSlider
            app.LaserPowerScannerCalibSlider = uislider(app.LaserpowerPanel);
            app.LaserPowerScannerCalibSlider.Position = [11 37 150 3];

            % Create CalibLaserSwitch
            app.CalibLaserSwitch = uiswitch(app.LaserpowerPanel, 'slider');
            app.CalibLaserSwitch.Position = [204 16 45 20];

            % Create CameraPanel
            app.CameraPanel = uipanel(app.CalibrateScannersTab);
            app.CameraPanel.BorderType = 'none';
            app.CameraPanel.Title = 'Camera';
            app.CameraPanel.Position = [6 4 100 120];

            % Create ROIButton
            app.ROIButton = uibutton(app.CameraPanel, 'push');
            app.ROIButton.Icon = fullfile(pathToMLAPP, 'Icons', 'icon-mat-zoom-in.png');
            app.ROIButton.Tooltip = {'Draw a ROI and '};
            app.ROIButton.Position = [8 54 73 41];
            app.ROIButton.Text = 'ROI';

            % Create ResetROIButton
            app.ResetROIButton = uibutton(app.CameraPanel, 'push');
            app.ResetROIButton.Icon = fullfile(pathToMLAPP, 'Icons', 'icon-mat-zoom-out-map.png');
            app.ResetROIButton.Position = [8 6 73 41];
            app.ResetROIButton.Text = 'Reset';

            % Create CalibratePanel
            app.CalibratePanel = uipanel(app.CalibrateScannersTab);
            app.CalibratePanel.BorderType = 'none';
            app.CalibratePanel.Title = 'Calibrate';
            app.CalibratePanel.Position = [114 4 176 120];

            % Create RunScannerCalibrationButton
            app.RunScannerCalibrationButton = uibutton(app.CalibratePanel, 'push');
            app.RunScannerCalibrationButton.Position = [13 53 73 41];
            app.RunScannerCalibrationButton.Text = {'Run'; 'Calibration'};

            % Create PointModeButton
            app.PointModeButton = uibutton(app.CalibratePanel, 'state');
            app.PointModeButton.Text = {'Point'; 'Mode'};
            app.PointModeButton.Position = [89 53 73 41];

            % Create CatMouseButton
            app.CatMouseButton = uibutton(app.CalibratePanel, 'state');
            app.CatMouseButton.Text = {'Cat &'; 'Mouse'};
            app.CatMouseButton.Position = [89 2 73 41];

            % Create CheckCalibrationButton
            app.CheckCalibrationButton = uibutton(app.CalibratePanel, 'state');
            app.CheckCalibrationButton.Text = {'Check'; 'Calibration'};
            app.CheckCalibrationButton.Position = [13 2 73 41];

            % Create CalibrateSampleTab
            app.CalibrateSampleTab = uitab(app.TabGroup);
            app.CalibrateSampleTab.Title = 'Calibrate Sample';

            % Create CalibrationPanel
            app.CalibrationPanel = uipanel(app.CalibrateSampleTab);
            app.CalibrationPanel.ForegroundColor = [0.149 0.149 0.149];
            app.CalibrationPanel.BorderType = 'none';
            app.CalibrationPanel.Title = 'Calibration';
            app.CalibrationPanel.Position = [8 4 152 118];

            % Create RefAPDropDownLabel
            app.RefAPDropDownLabel = uilabel(app.CalibrationPanel);
            app.RefAPDropDownLabel.HorizontalAlignment = 'right';
            app.RefAPDropDownLabel.Position = [11 69 43 22];
            app.RefAPDropDownLabel.Text = 'Ref AP';

            % Create RefAPDropDown
            app.RefAPDropDown = uidropdown(app.CalibrationPanel);
            app.RefAPDropDown.Items = {'1 mm', '2 mm', '3 mm', '4 mm', '5 mm', '6 mm'};
            app.RefAPDropDown.Tooltip = {'Which reference point to use after bregma.'};
            app.RefAPDropDown.Position = [69 69 64 22];
            app.RefAPDropDown.Value = '3 mm';

            % Create CalibrateSampleButton
            app.CalibrateSampleButton = uibutton(app.CalibrationPanel, 'push');
            app.CalibrateSampleButton.Tooltip = {'Calibrate the sample: camera to stereotaxic coordinates.'};
            app.CalibrateSampleButton.Position = [14 41 112 22];
            app.CalibrateSampleButton.Text = 'Calibrate Sample';

            % Create PaintbrainborderButton
            app.PaintbrainborderButton = uibutton(app.CalibrationPanel, 'state');
            app.PaintbrainborderButton.Tooltip = {'Draw the perimeter of the brain on the sample using the laser beam.'};
            app.PaintbrainborderButton.Text = 'Paint brain border';
            app.PaintbrainborderButton.Position = [14 13 112 22];

            % Create ConfirmstimuluslocationsPanel
            app.ConfirmstimuluslocationsPanel = uipanel(app.CalibrateSampleTab);
            app.ConfirmstimuluslocationsPanel.BorderType = 'none';
            app.ConfirmstimuluslocationsPanel.Title = 'Confirm stimulus locations';
            app.ConfirmstimuluslocationsPanel.Position = [177 4 330 118];

            % Create ZapallcoordsButton
            app.ZapallcoordsButton = uibutton(app.ConfirmstimuluslocationsPanel, 'state');
            app.ZapallcoordsButton.Tooltip = {'Move the beam rapidly through the sample coordinates. '};
            app.ZapallcoordsButton.Text = 'Zap all coords';
            app.ZapallcoordsButton.Position = [6 41 122 22];

            % Create OverlaystimsitesButton
            app.OverlaystimsitesButton = uibutton(app.ConfirmstimuluslocationsPanel, 'state');
            app.OverlaystimsitesButton.Tooltip = {'Plot the sample locations onto the live image feed.'};
            app.OverlaystimsitesButton.Text = 'Overlay stim sites';
            app.OverlaystimsitesButton.Position = [6 66 122 23];

            % Create TestSiteDropDown
            app.TestSiteDropDown = uidropdown(app.ConfirmstimuluslocationsPanel);
            app.TestSiteDropDown.Position = [150 53 100 23];

            % Create ZapSiteButton
            app.ZapSiteButton = uibutton(app.ConfirmstimuluslocationsPanel, 'state');
            app.ZapSiteButton.Tooltip = {'Run the named stimulus condition.'};
            app.ZapSiteButton.Text = 'Zap Site';
            app.ZapSiteButton.Position = [255 53 69 22];

            % Create PaintareaButton
            app.PaintareaButton = uibutton(app.ConfirmstimuluslocationsPanel, 'state');
            app.PaintareaButton.Tooltip = {'Draw the brain area associated with the current stimulus condition onto the brain using the laser.'};
            app.PaintareaButton.Text = 'Paint area';
            app.PaintareaButton.Position = [255 27 70 22];

            % Create PlotstimcoordsButton
            app.PlotstimcoordsButton = uibutton(app.ConfirmstimuluslocationsPanel, 'push');
            app.PlotstimcoordsButton.Tooltip = {'Make a summary plot showing where the stimuli are located. '};
            app.PlotstimcoordsButton.Position = [6 14 122 23];
            app.PlotstimcoordsButton.Text = 'Plot stim coords';

            % Create RunPanel
            app.RunPanel = uipanel(app.CalibrateSampleTab);
            app.RunPanel.BorderType = 'none';
            app.RunPanel.Title = 'Run';
            app.RunPanel.Position = [524 4 219 118];

            % Create SetexperimentpathButton
            app.SetexperimentpathButton = uibutton(app.RunPanel, 'push');
            app.SetexperimentpathButton.Tooltip = {'Set the experiment path for logging.'};
            app.SetexperimentpathButton.Position = [7 46 124 23];
            app.SetexperimentpathButton.Text = 'Set experiment path';

            % Create ExportwaveformsButton
            app.ExportwaveformsButton = uibutton(app.RunPanel, 'push');
            app.ExportwaveformsButton.Tooltip = {'Export all waveforms as a file called zapit_waveforms.mat. This allows external software to present stimuli generated by Zapit.'};
            app.ExportwaveformsButton.Position = [7 72 122 23];
            app.ExportwaveformsButton.Text = 'Export waveforms';

            % Create ExperimentPathTextArea
            app.ExperimentPathTextArea = uitextarea(app.RunPanel);
            app.ExperimentPathTextArea.Editable = 'off';
            app.ExperimentPathTextArea.Position = [7 0 213 45];

            % Create ClearpathButton
            app.ClearpathButton = uibutton(app.RunPanel, 'push');
            app.ClearpathButton.Tooltip = {'Clear the experiment path for logging.'};
            app.ClearpathButton.Position = [136 46 81 23];
            app.ClearpathButton.Text = 'Clear path';

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.Layout.Row = 3;
            app.Panel.Layout.Column = 1;

            % Create ScannersCalibratedLampLabel
            app.ScannersCalibratedLampLabel = uilabel(app.Panel);
            app.ScannersCalibratedLampLabel.HorizontalAlignment = 'right';
            app.ScannersCalibratedLampLabel.Position = [5 7 114 22];
            app.ScannersCalibratedLampLabel.Text = 'Scanners Calibrated';

            % Create ScannersCalibratedLamp
            app.ScannersCalibratedLamp = uilamp(app.Panel);
            app.ScannersCalibratedLamp.Position = [123 7 20 20];
            app.ScannersCalibratedLamp.Color = [1 0 0];

            % Create SampleCalibratedLampLabel
            app.SampleCalibratedLampLabel = uilabel(app.Panel);
            app.SampleCalibratedLampLabel.HorizontalAlignment = 'right';
            app.SampleCalibratedLampLabel.Position = [156 7 104 22];
            app.SampleCalibratedLampLabel.Text = 'Sample Calibrated';

            % Create SampleCalibratedLamp
            app.SampleCalibratedLamp = uilamp(app.Panel);
            app.SampleCalibratedLamp.Position = [264 7 20 20];
            app.SampleCalibratedLamp.Color = [1 0 0];

            % Create ConfigLoadedTextLabel
            app.ConfigLoadedTextLabel = uilabel(app.Panel);
            app.ConfigLoadedTextLabel.Position = [315 7 419 22];
            app.ConfigLoadedTextLabel.Text = 'Config Loaded: NONE';

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