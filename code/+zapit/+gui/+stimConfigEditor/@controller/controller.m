classdef controller < zapit.gui.stimConfigEditor.view

    % zapit.gui.stimConfigEditor.view is the main GUI window: that which first appears when the 
    % user starts the software.
    %
    % The GUI itself is made in MATLAB AppDesigner and is inherited by this class
    %
    %
    % Rob Campbell - SWC 2023

    properties
        % Handles for some plot elements are inherited from the superclass

        hImLive  %The image
        plotOverlayHandles   % All plotted objects laid over the image should keep their handles here

        zapitPointer % Reference to a parent (running) zapit.pointer object
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



    methods

        function obj = controller(hZP,hZPview)

            if nargin>0
                obj.zapitPointer = hZP;
            end

            if nargin>1
                obj.mainGUI = hZPview;
            end

            % Load the atlas data so we can do things like overlay the brain boundaries
            load('atlas_data.mat')
            obj.atlasData = atlas_data;


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
            if ~isempty(obj.zapitPointer)
                obj.LaserPowermWSpinner.Value = obj.zapitPointer.settings.experiment.defaultLaserPowerMW;
                obj.StimFreqHzSpinner.Value = obj.zapitPointer.settings.experiment.defaultLaserFrequencyHz;
            end
            

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
            delete(obj.hFig);
        end %close destructor


        function isPressed = isShiftPressed(obj)
            % Return true if the user is pressing the shift key
            mod = get(gcbo,'currentModifier');
            isPressed = false;
            if length(mod)==1
                isPressed = strcmp(mod{1},'shift');
            end
        end % isShiftPressed


        function isPressed = isCtrlPressed(obj)
            % Return true if the user is pressing the ctrl key
            mod = get(gcbo,'currentModifier');
            isPressed = false;
            if length(mod)==1
                isPressed = strcmp(mod{1},'control');
            end
        end % isShiftPressed


        function keyboardPress_Callback(obj,~,event)
            % Runs whenever a key is pressed or released.
            % Used to cause the symbol that follows the mouse cursor to change
            % size right away and not wait until it is moved. 

            if strcmp(event.Key,'ctrl') || strcmp(event.Key,'shift') 
                obj.highlightArea_Callback
            end
        end % keyboardPress_Callback


        function resetPoints_Callback(obj,~,~)
            % TODO -- should we create a file name also to help with saving?
            % Allows the user to wipe the GUI and start over with a new file name

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
            % Save to YAML
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

        end %saveConfigYAML


        function loadConfigYAML(obj)
            % Load to YAML
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
        end %saveConfigYAML


        function ind = findIndexOfAddedPointNearestCursor(obj)
            % Return the index of the point nearest the cursor

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
            colors = lines(20);
            nCol = mod(length(obj.pAddedPoints),length(colors));
            if nCol == 0
                nCol = length(colors);
            end
            tCol = colors(nCol,:);
        end


        function tSym = currentSymbol(obj)
            % Returns a new symbol for plotting based upon the number of added stimuli
            symbols = 'osd^';
            nSym = mod(length(obj.pAddedPoints),length(symbols));
            if nSym == 0
                nSym = length(symbols);
            end
            tSym = symbols(nSym);
        end

        function updateBottomLabel(obj)
            % Update text along the bottom of the GUI
            if isempty(obj.fname)
                t_fname = '';
            else
                t_fname = [obj.fname, ' - '];
            end

            obj.BottomLabel.Text = sprintf('%s%d stimulus conditions', t_fname, length(obj.pAddedPoints));
        end % updateBottomLabel
    end % methods




end % close classdef
