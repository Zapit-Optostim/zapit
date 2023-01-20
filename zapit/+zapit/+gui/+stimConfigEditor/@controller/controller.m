classdef controller < zapit.gui.stimConfigEditor.view

    % Graphical editor for stimulus configuration files.
    %
    % zapit.gui.stimConfigEditor.controller
    %
    % Purpose
    % This class controls a GUI that serves as an editor and creater of stimulus configuration
    % files. This class inherits zapit.gui.stimConfigEditor.view which is what actually makes
    % the GUI. This class controls the GUI and implements the logic that runs it. 
    %
    % The GUI itself is made in MATLAB AppDesigner and is never edited manually.
    %
    %
    % Rob Campbell - SWC 2023

    properties
        % Handles for most plot elements are inherited from the superclass

        mainGUI % Reference to a parent (running) zapit.gui.main.controller object

        atlasData % Brain atlas data for overlaying brain areas, etc

        % Handles of plot objects associated with the brain outline
        pBregma
        pMLtick
        pAPtick
        hAxTitle % The title that updates as the mouse cursor moves

        % Handles of plot objects associated with stimulation points
        pCurrentPoint % The current point that we are about to add
        pAddedPoints = matlab.graphics.chart.primitive.Line.empty % A list of all added poits
        pointCommonProps = {'ob', 'MarkerSize', 14, 'LineWidth', 2};

        fname % The name of the currently loaded file (if it has one)
    end

    properties(Hidden)
        settings % So the GUI relies less on being connected to zapit.pointer
    end


    methods

        function obj = controller(hZPview)
            % Constructor
            %
            % function zapit.gui.stimConfig.controller.controller
            %
            % Purpose
            % Constructor.
            %
            % Inputs
            % hZPview - optional. As above. Provided so this GUI can add saved files to the recently opened file list.
            %
            % 


            if nargin>0
                obj.mainGUI = hZPview;
            end

            % Load the atlas data so we can do things like overlay the brain boundaries
            load('atlas_data.mat')
            obj.atlasData = atlas_data;

            obj.settings = zapit.settings.readSettings;

            % Button callbacks
            obj.NewButton.ButtonPushedFcn = @(~,~) obj.resetPoints_Callback;
            obj.LoadButton.ButtonPushedFcn = @(~,~) obj.loadConfigYAML;
            obj.SaveButton.ButtonPushedFcn = @(~,~) obj.saveConfigYAML;

            % Set figure properties
            obj.hFig.Color = 'w';
            obj.hFig.ToolBar = 'none';
            obj.hFig.MenuBar = 'none';
            obj.hFig.Name = 'Stim config editor';
            obj.hAx.Toolbar.Visible = 'off';
            obj.BottomLabel.Text = ''; 
            
            % Apply default values to UI elements from settings
            obj.LaserPowermWSpinner.Value = obj.settings.experiment.defaultLaserPowerMW;
            obj.StimFreqHzSpinner.Value = obj.settings.experiment.defaultLaserFrequencyHz;
            obj.RampdownmsSpinner.Value = obj.settings.experiment.offRampDownDuration_ms;

            obj.LaserPowermWSpinner.Limits(2) = obj.settings.laser.laserMinMax_mW(2);

            % Set up callback functions for interactivity
            obj.hFig.WindowButtonMotionFcn = @obj.highlightArea_Callback;
            obj.hFig.WindowButtonDownFcn = @obj.mouseClick_Callback;
            obj.hFig.KeyPressFcn = @obj.keyboardPress_Callback;
            obj.hFig.KeyReleaseFcn = @obj.keyboardPress_Callback;

            % Call the class destructor when figure is closed. This ensures everything is tidied.
            obj.hFig.CloseRequestFcn = @obj.delete;

            obj.plotBrainBoundaries


            % Make blank plot objects
            hold(obj.hAx,'on')
            obj.pCurrentPoint = plot(nan,nan, obj.pointCommonProps{:},'Color','r','Parent',obj.hAx);
            hold(obj.hAx,'off')
        end %close constructor


        function delete(obj,~,~)
            % Destructor
            %
            % function zapit.gui.stimConfig.controller.delete
            %

            delete(obj.hFig);
        end %close destructor


        function isPressed = isShiftPressed(obj)
            % Return true if the user is pressing the shift key
            %
            % function zapit.gui.stimConfig.controller.isShiftPressed
            %
            % Purpose
            % Returns true if the user presses the shift key.
            %
            % Inputs
            % none
            %
            % Outputs
            % isPressed - True if shift is pressed. False otherwise.

            mod = get(gcbo,'currentModifier');
            isPressed = false;
            if length(mod)==1
                isPressed = strcmp(mod{1},'shift');
            end
        end % isShiftPressed


        function isPressed = isCtrlPressed(obj)
            % Return true if the user is pressing the control key
            %
            % function zapit.gui.stimConfig.controller.isCtrlPressed
            %
            % Purpose
            % Returns true if the user presses the control key.
            %
            % Inputs
            % none
            %
            % Outputs
            % isPressed - True if controle is pressed. False otherwise.

            mod = get(gcbo,'currentModifier');
            isPressed = false;
            if length(mod)==1
                isPressed = strcmp(mod{1},'control');
            end
        end % isShiftPressed


        function keyboardPress_Callback(obj,~,event)
            % Triggers events if shift or ctrl is pressed or released.
            %
            % function zapit.gui.stimConfig.controller.keyboardPress_Callback
            %
            % Purpose
            % Runs whenever a key is pressed or released. Used to cause the symbol that 
            % follows the mouse cursor to change size right away and not wait until it is moved. 

            if strcmp(event.Key,'ctrl') || strcmp(event.Key,'shift') 
                obj.highlightArea_Callback
            end
        end % keyboardPress_Callback


        function resetPoints_Callback(obj,~,~)
            % Wipes all points and the file name after presenting a confirm dialog. 
            %
            % function zapit.gui.stimConfig.controller.resetPoints_Callback
            %
            % Purpose
            % Allows the user to reset the GUI: removing the clicked points and wiping the
            % file name.
            %
            % 

            % TODO -- should we create a file name also to help with saving?

            if length(obj.pAddedPoints) == 0
                return
            end

            response = questdlg('Wipe points and start over?', ...
                         'Confirm', ...
                         'Yes', 'No', 'No');
            if isempty(response) || strcmp(response,'No')
                return
            end 
            arrayfun(@(x) delete(x), obj.pAddedPoints)
            obj.pAddedPoints = matlab.graphics.chart.primitive.Line.empty;
            obj.fname = '' ;
            obj.updateBottomLabel
        end % resetPoints_Callback


        function saveConfigYAML(obj)
            % Save config to a YAML
            %
            % function zapit.gui.stimConfig.controller.saveConfigYAML
            %
            % Purpose
            % Saves the stimulus config data to a YAML file. If the GUI was launched
            % from the main GUI, then saving a file will cause it to be added to the 
            % recently loaded menu.  

            % For some reason we need the video stopped or this locks up everything
            if ~isempty(obj.mainGUI)
                isCamRunning = obj.mainGUI.model.cam.isrunning;
                if isCamRunning
                    obj.mainGUI.model.cam.stopVideo;
                end
            end

            stimC = obj.returnStimConfigStructure;
            if isempty(stimC)
                return
            end

            [fname,fullPath] = uiputfile('*.yml');
            if fname == 0 | isempty(fname)
                return
            end
            zapit.yaml.WriteYaml(fullfile(fullPath,fname), stimC);

            obj.fname = fname;
            obj.updateBottomLabel

            % If the stim config editor was launched from the main GUI then we
            % can add this file to the recents.
            if ~isempty(obj.mainGUI)
                obj.mainGUI.addStimConfigToRecents(fname,fullPath)
            end

            if ~isempty(obj.mainGUI)
                isCamRunning = obj.mainGUI.model.cam.isrunning;
                if isCamRunning
                    obj.mainGUI.model.cam.startVideo;
                end            
            end
        end %saveConfigYAML


        function loadConfigYAML(obj)
            % Load a YAML containing a stimulus config
            %
            % function zapit.gui.stimConfig.controller.loadConfigYAML
            %
            % Purpose
            % Load a stimulus config YAML and display it. 


            % For some reason we need the video stopped or this locks up everything
            if ~isempty(obj.mainGUI)
                isCamRunning = obj.mainGUI.model.cam.isrunning;
                if isCamRunning
                    obj.mainGUI.model.cam.stopVideo;
                end
            end

            [fname,fullPath] = uigetfile('*.yml;*.yaml');
            if fname == 0 | isempty(fname)
                return
            end
            stimC = zapit.stimConfig(fullfile(fullPath,fname));

            % Wipe anything that is already there
            arrayfun(@(x) delete(x), obj.pAddedPoints)
            obj.pAddedPoints = matlab.graphics.chart.primitive.Line.empty;
            obj.BottomLabel.Text = '';

            hold(obj.hAx,'on')
            for ii=1:length(stimC.stimLocations)
                obj.pAddedPoints(ii) = plot(stimC.stimLocations(ii).ML, ...
                                            stimC.stimLocations(ii).AP, ...
                                            obj.pointCommonProps{:}, ...
                                            'Marker', obj.currentSymbol, ...
                                            'Color', obj.currentColor, ...
                                            'Parent', obj.hAx);
            end
            hold(obj.hAx,'off')

            obj.fname = fname;
            obj.updateBottomLabel

            if ~isempty(obj.mainGUI)
                isCamRunning = obj.mainGUI.model.cam.isrunning;
                if isCamRunning
                    obj.mainGUI.model.cam.startVideo;
                end            
            end

        end %saveConfigYAML


        function ind = findIndexOfAddedPointNearestCursor(obj)
            % Return the index of the point nearest the cursor
            %
            % function zapit.gui.stimConfig.controller.findIndexOfAddedPointNearestCursor
            %
            % Purpose
            % Obtain the point nearest the cursor. From this obtain the index of the stimulus
            % type (trial) that this is part of. 
            %


            % Get difference between each plotted point and the current position
            X = obj.pCurrentPoint.XData;
            Y = obj.pCurrentPoint.YData;

            % a. Get x/y differences of all points within each plot element
            differences = arrayfun(@(p) [p.XData-X; p.YData-Y], obj.pAddedPoints, 'uniformoutput', false)';

            % b. Calculate the minimum RMS of each plot element
            differences = cellfun(@(x) min(sqrt(sum(x.^2,1))), differences, 'uniformoutput',false);

            % c. Return the plot element that has the smallest difference to current position
            differences = cell2mat(differences);
            [~,ind] = min(differences);
        end % findIndexOfAddedPointNearestCursor



        function tCol = currentColor(obj)
            % Returns a new color for plotting based upon the number of added stimuli
            %
            % function zapit.gui.stimConfig.controller.currentColor
            %
            % Purpose
            % We want each stimulus group to be the same color. e.g. both symmetrical bilateral
            % points shold be matched. This function returns a different colour each time a point
            % is laid down. So points have different colours.

            colors = lines(20);
            nCol = mod(length(obj.pAddedPoints),length(colors));
            if nCol == 0
                nCol = length(colors);
            end
            tCol = colors(nCol,:);
        end


        function tSym = currentSymbol(obj)
            % Returns a new symbol for plotting based upon the number of added stimuli
            %
            % function zapit.gui.stimConfig.controller.currentSymbol
            %
            % Purpose
            % We want each stimulus group to be the same symbol. e.g. both symmetrical bilateral
            % points shold be matched. This function returns a different symbol each time a point
            % is laid down.

            symbols = 'osd^';
            nSym = mod(length(obj.pAddedPoints),length(symbols));
            if nSym == 0
                nSym = length(symbols);
            end
            tSym = symbols(nSym);
        end


        function updateBottomLabel(obj)
            % Update text along the bottom of the GUI
            %
            % function zapit.gui.stimConfig.controller.updateBottomLabel
            %
            % Purpose
            % The label text reflects the file name and number of stimuli. This
            % method updates it when changes take place. It is called manually.

            if isempty(obj.fname)
                t_fname = '';
            else
                t_fname = [obj.fname, ' - '];
            end

            obj.BottomLabel.Text = sprintf('%s%d stimulus conditions', t_fname, length(obj.pAddedPoints));
        end % updateBottomLabel

    end % methods


end % close classdef
