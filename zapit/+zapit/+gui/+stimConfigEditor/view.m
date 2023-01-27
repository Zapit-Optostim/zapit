classdef view < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        hFig                    matlab.ui.Figure
        GridLayout              matlab.ui.container.GridLayout
        Panel                   matlab.ui.container.Panel
        RampdownmsSpinner       matlab.ui.control.Spinner
        RampdownmsLabel         matlab.ui.control.Label
        StimFreqHzSpinner       matlab.ui.control.Spinner
        StimFreqHzSpinnerLabel  matlab.ui.control.Label
        LaserPowermWSpinner     matlab.ui.control.Spinner
        LaserPowermWLabel       matlab.ui.control.Label
        AddPointButtonGroup     matlab.ui.container.ButtonGroup
        BilateralButton         matlab.ui.control.RadioButton
        UnilateralButton        matlab.ui.control.RadioButton
        BottomLabel             matlab.ui.control.Label
        SaveButton              matlab.ui.control.Button
        LoadButton              matlab.ui.control.Button
        NewButton               matlab.ui.control.Button
        hAx                     matlab.ui.control.UIAxes
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create hFig and hide until all components are created
            app.hFig = uifigure('Visible', 'off');
            app.hFig.AutoResizeChildren = 'off';
            app.hFig.Position = [100 100 601 750];
            app.hFig.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.hFig);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'14x', '2x'};

            % Create hAx
            app.hAx = uiaxes(app.GridLayout);
            app.hAx.XTick = [];
            app.hAx.YTick = [];
            app.hAx.Layout.Row = 1;
            app.hAx.Layout.Column = 1;

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.AutoResizeChildren = 'off';
            app.Panel.Layout.Row = 2;
            app.Panel.Layout.Column = 1;

            % Create NewButton
            app.NewButton = uibutton(app.Panel, 'push');
            app.NewButton.Tooltip = {'Wipe any existing points and start over.'};
            app.NewButton.Position = [6 60 50 23];
            app.NewButton.Text = 'New';

            % Create LoadButton
            app.LoadButton = uibutton(app.Panel, 'push');
            app.LoadButton.Tooltip = {'Load existing stim config file from disk.'};
            app.LoadButton.Position = [6 34 50 23];
            app.LoadButton.Text = 'Load';

            % Create SaveButton
            app.SaveButton = uibutton(app.Panel, 'push');
            app.SaveButton.Tooltip = {'Save current points to a stim config file. This will also add the fle to the Zapit recently loaded files menu.'};
            app.SaveButton.Position = [6 8 50 23];
            app.SaveButton.Text = 'Save';

            % Create BottomLabel
            app.BottomLabel = uilabel(app.Panel);
            app.BottomLabel.BackgroundColor = [1 1 1];
            app.BottomLabel.Position = [62 6 510 16];

            % Create AddPointButtonGroup
            app.AddPointButtonGroup = uibuttongroup(app.Panel);
            app.AddPointButtonGroup.AutoResizeChildren = 'off';
            app.AddPointButtonGroup.BorderType = 'none';
            app.AddPointButtonGroup.Title = 'Point Type';
            app.AddPointButtonGroup.Position = [62 34 156 45];

            % Create UnilateralButton
            app.UnilateralButton = uiradiobutton(app.AddPointButtonGroup);
            app.UnilateralButton.Text = 'Unilateral';
            app.UnilateralButton.Position = [7 0 73 22];

            % Create BilateralButton
            app.BilateralButton = uiradiobutton(app.AddPointButtonGroup);
            app.BilateralButton.Tooltip = {'Adds two symmetric points on the left and right hemispheres. Ctrl and click to delete the condition.'};
            app.BilateralButton.Text = 'Bilateral';
            app.BilateralButton.Position = [84 0 66 22];
            app.BilateralButton.Value = true;

            % Create LaserPowermWLabel
            app.LaserPowermWLabel = uilabel(app.Panel);
            app.LaserPowermWLabel.HorizontalAlignment = 'right';
            app.LaserPowermWLabel.Position = [408 58 103 22];
            app.LaserPowermWLabel.Text = 'Laser Power (mW)';

            % Create LaserPowermWSpinner
            app.LaserPowermWSpinner = uispinner(app.Panel);
            app.LaserPowermWSpinner.Limits = [0 100];
            app.LaserPowermWSpinner.Tooltip = {'Laser power in mW.'};
            app.LaserPowermWSpinner.Position = [517 58 55 22];
            app.LaserPowermWSpinner.Value = 5;

            % Create StimFreqHzSpinnerLabel
            app.StimFreqHzSpinnerLabel = uilabel(app.Panel);
            app.StimFreqHzSpinnerLabel.HorizontalAlignment = 'right';
            app.StimFreqHzSpinnerLabel.Position = [424 29 88 22];
            app.StimFreqHzSpinnerLabel.Text = 'Stim. Freq. (Hz)';

            % Create StimFreqHzSpinner
            app.StimFreqHzSpinner = uispinner(app.Panel);
            app.StimFreqHzSpinner.Limits = [1 1000];
            app.StimFreqHzSpinner.Tooltip = {'The frequency with which the laser switches between points or switches on and off.'};
            app.StimFreqHzSpinner.Position = [517 29 56 22];
            app.StimFreqHzSpinner.Value = 40;

            % Create RampdownmsLabel
            app.RampdownmsLabel = uilabel(app.Panel);
            app.RampdownmsLabel.HorizontalAlignment = 'right';
            app.RampdownmsLabel.Position = [244 29 93 22];
            app.RampdownmsLabel.Text = 'Rampdown (ms)';

            % Create RampdownmsSpinner
            app.RampdownmsSpinner = uispinner(app.Panel);
            app.RampdownmsSpinner.Step = 10;
            app.RampdownmsSpinner.Limits = [0 1000];
            app.RampdownmsSpinner.Tooltip = {'The duration of the ramp down in laser power in ms at the end of a trial.'};
            app.RampdownmsSpinner.Position = [342 29 62 22];
            app.RampdownmsSpinner.Value = 250;

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