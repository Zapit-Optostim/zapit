classdef controller < zapit.gui.stimConfigEditor.view

    % zapit.gui.stimConfigEditor.view is the main GUI window: that which first appears when the 
    % user starts the software.
    %
    % The GUI itself is made in MATLAB AppDesigner and is inherited by this class

    properties
        % Handles for some plot elements are inherited from the superclass

        hImLive  %The image
        plotOverlayHandles   % All plotted objects laid over the image should keep their handles here

        model % The ZP model object goes here
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

    end



    methods

        function obj = controller(hZP)
            if nargin>0
                obj.model = hZP;
            end

            % Load the atlas data so we can do things like overlay the brain boundaries
            load('atlas_data.mat')
            obj.atlasData = atlas_data;


            % Button callbacks
            obj.NewButton.ButtonPushedFcn = @(~,~) obj.resetROI_Callback;
            obj.LoadButton.ButtonPushedFcn = @(~,~) obj.drawROI_Callback;
            obj.SaveButton.ButtonPushedFcn = @(~,~) obj.drawROI_Callback;

            % Set figure properties
            obj.hFig.Color = 'w';
            obj.hFig.ToolBar = 'none';
            obj.hFig.MenuBar = 'none';
            obj.hFig.Name = 'Stim config editor';
            obj.hAx.Toolbar.Visible = 'off';
            obj.BottomLabel.Text = ''; 
            
            % Apply default values to UI elements from settings
            if ~isempty(obj.model)
                obj.LaserPowermWSpinner.Value = obj.model.settings.experiment.defaultLaserPowerMW;
                obj.StimFreqHzSpinner.Value = obj.model.settings.experiment.defaultLaserFrequencyHz;
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

    end % methods




end % close classdef
