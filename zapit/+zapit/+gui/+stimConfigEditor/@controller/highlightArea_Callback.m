function highlightArea_Callback(obj,~,~)
    % Highlight the brain area under the mouse cursor
    %
    % zapit.gui.stimConfigEditor.controller.highlightArea_Callback
    %
    % Purpose
    % This callback highlights the brain area under the mouse cursor.


     % For ease
    brain_areas = obj.atlasData.dorsal_brain_areas;

    C = get (obj.hAx, 'CurrentPoint');
    X = C(1,1);
    Y = C(1,2);

    % Set the current point to follow the mouse
    if obj.BilateralButton.Value == 1
        obj.pCurrentPoint.XData = [-X,X];
        obj.pCurrentPoint.YData = [Y,Y];
    else
        obj.pCurrentPoint.XData = X;
        obj.pCurrentPoint.YData = Y;
    end


    % If shift is pressed we highlight points nearest the cursor and alter the current point shape
    set([obj.pAddedPoints],'MarkerSize', obj.standardMarkerSize)
    if obj.isCtrlPressed && length(obj.pAddedPoints)>0
        % We are in delete mode
        obj.pCurrentPoint.MarkerSize = obj.enlargedMarkerSize;
        obj.pCurrentPoint.Marker = 'x';
        obj.pCurrentPoint.Color = 'r';
        ind = obj.findIndexOfAddedPointNearestCursor;
        obj.pAddedPoints(ind).MarkerSize = obj.enlargedMarkerSize;
        % If this point is a single, we will make the point following the cursor a single too if needed
        if obj.BilateralButton.Value == 1 && length(obj.pAddedPoints(ind).XData)~=2
            obj.pCurrentPoint.XData = X;
            obj.pCurrentPoint.YData = Y;
        end
    else
        % Change the marker so it indicates what the next symbol to be placed will be.
        % This will be either a new symbol or the current one depending on the shift key
        % press state.
        if obj.isShiftPressed
            obj.pCurrentPoint.Marker = obj.pAddedPoints(end).Marker;
            obj.pCurrentPoint.Color = obj.pAddedPoints(end).Color;
            obj.pCurrentPoint.MarkerSize = obj.standardMarkerSize;
        else
            % Next symbol and color
            obj.pCurrentPoint.Marker = obj.currentSymbol;
            obj.pCurrentPoint.Color = obj.currentColor;
            obj.pCurrentPoint.MarkerSize = obj.standardMarkerSize;
        end
    end

    % Find brain area index. This is cheap arithmetic (no graphics) so it runs every move.
    [~,indX] = min(abs(obj.atlasData.top_down_annotation.xData-X));
    [~,indY] = min(abs(obj.atlasData.top_down_annotation.yData-Y));
    t_ind = obj.atlasData.top_down_annotation.data(indY,indX);
    f = find([brain_areas.area_index]==t_ind);

    if isempty(f)
        area_name = '';
        obj.hFig.Pointer = 'arrow'; % Return pointer to arrow when it's out of brain
        obj.pMLtick.Visible = 'off';
        obj.pAPtick.Visible = 'off';
    else
        area_name = [', ',brain_areas(f).names{1}];
        obj.pMLtick.XData = [X,X];
        obj.pAPtick.YData = [Y,Y];
        obj.pMLtick.Visible = 'on';
        obj.pAPtick.Visible = 'on';
    end


    % Highlight the area under the cursor with a translucent patch. This is the expensive
    % part: deleting and recreating patches on every mouse move floods the uifigure's
    % renderer and causes button-down (click) events to be dropped. We therefore rebuild
    % the patch(es) only when the highlighted area actually changes. The key captures the
    % area, the uni/bilateral mode, and (in unilateral mode) the hemisphere, since those
    % are what determine which patch(es) are drawn. Moving within an area costs no graphics.
    if obj.BilateralButton.Value == 0
        sideKey = sign(X);
    else
        sideKey = 0;
    end
    if isempty(f)
        areaKey = 0;
    else
        areaKey = t_ind;
    end
    highlightKey = [areaKey, obj.BilateralButton.Value, sideKey];

    if ~isequal(highlightKey, obj.lastHighlightKey)
        delete(obj.pAreaHighlight)
        obj.pAreaHighlight = matlab.graphics.primitive.Patch.empty;

        if ~isempty(f)
            bAreas = brain_areas(f).boundaries_stereotax;

            % Select the correct side or both sides depending on radio button state
            if obj.BilateralButton.Value == 0
                if X<0 || length(bAreas)==1
                    bAreas = bAreas(1);
                else
                    bAreas = bAreas(2);
                end
            end

            % Make the one or two patches. HitTest/PickableParts are off so the highlight
            % never intercepts a click meant for the axes.
            patchProps = {'FaceAlpha', 0.1, 'FaceColor', 'r', 'EdgeColor', 'r', ...
                          'Parent', obj.hAx, 'PickableParts', 'none', 'HitTest', 'off'};
            obj.pAreaHighlight = cellfun(@(x) patch(x(:,2), x(:,1), 1, patchProps{:}), ...
                                         bAreas);
        end

        obj.lastHighlightKey = highlightKey;
    end


    obj.hAxTitle.String = sprintf('ML=%0.2f mm, AP=%0.2f mm%s\n', X, Y, area_name);
end
