classdef view < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        hFig                      matlab.ui.Figure
        GridLayout                matlab.ui.container.GridLayout
        Panel                     matlab.ui.container.Panel
        StimFreqHzSpinner         matlab.ui.control.Spinner
        StimFreqHzSpinnerLabel    matlab.ui.control.Label
        LaserPowermWSpinner       matlab.ui.control.Spinner
        LaserPowermWSpinnerLabel  matlab.ui.control.Label
        AddPointButtonGroup       matlab.ui.container.ButtonGroup
        BilateralButton           matlab.ui.control.RadioButton
        UnilateralButton          matlab.ui.control.RadioButton
        BottomLabel               matlab.ui.control.Label
        SaveButton                matlab.ui.control.Button
        LoadButton                matlab.ui.control.Button
        NewButton                 matlab.ui.control.Button
        hAx                       matlab.ui.control.UIAxes
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
            app.NewButton.Position = [6 60 71 23];
            app.NewButton.Text = 'New';

            % Create LoadButton
            app.LoadButton = uibutton(app.Panel, 'push');
            app.LoadButton.Position = [6 34 71 23];
            app.LoadButton.Text = 'Load';

            % Create SaveButton
            app.SaveButton = uibutton(app.Panel, 'push');
            app.SaveButton.Position = [6 8 71 23];
            app.SaveButton.Text = 'Save';

            % Create BottomLabel
            app.BottomLabel = uilabel(app.Panel);
            app.BottomLabel.BackgroundColor = [1 1 1];
            app.BottomLabel.Position = [85 6 487 16];

            % Create AddPointButtonGroup
            app.AddPointButtonGroup = uibuttongroup(app.Panel);
            app.AddPointButtonGroup.AutoResizeChildren = 'off';
            app.AddPointButtonGroup.BorderType = 'none';
            app.AddPointButtonGroup.Title = 'Point Type';
            app.AddPointButtonGroup.Position = [96 34 156 45];

            % Create UnilateralButton
            app.UnilateralButton = uiradiobutton(app.AddPointButtonGroup);
            app.UnilateralButton.Text = 'Unilateral';
            app.UnilateralButton.Position = [7 0 73 22];

            % Create BilateralButton
            app.BilateralButton = uiradiobutton(app.AddPointButtonGroup);
            app.BilateralButton.Text = 'Bilateral';
            app.BilateralButton.Position = [84 0 66 22];
            app.BilateralButton.Value = true;

            % Create LaserPowermWSpinnerLabel
            app.LaserPowermWSpinnerLabel = uilabel(app.Panel);
            app.LaserPowermWSpinnerLabel.HorizontalAlignment = 'right';
            app.LaserPowermWSpinnerLabel.Position = [314 57 107 22];
            app.LaserPowermWSpinnerLabel.Text = 'Laser  Power (mW)';

            % Create LaserPowermWSpinner
            app.LaserPowermWSpinner = uispinner(app.Panel);
            app.LaserPowermWSpinner.Limits = [0 100];
            app.LaserPowermWSpinner.Position = [430 57 70 22];
            app.LaserPowermWSpinner.Value = 5;

            % Create StimFreqHzSpinnerLabel
            app.StimFreqHzSpinnerLabel = uilabel(app.Panel);
            app.StimFreqHzSpinnerLabel.HorizontalAlignment = 'right';
            app.StimFreqHzSpinnerLabel.Position = [334 33 88 22];
            app.StimFreqHzSpinnerLabel.Text = 'Stim. Freq. (Hz)';

            % Create StimFreqHzSpinner
            app.StimFreqHzSpinner = uispinner(app.Panel);
            app.StimFreqHzSpinner.Limits = [1 1000];
            app.StimFreqHzSpinner.Position = [431 33 70 22];
            app.StimFreqHzSpinner.Value = 40;

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