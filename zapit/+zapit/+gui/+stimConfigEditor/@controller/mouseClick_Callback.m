function mouseClick_Callback(obj,~,~)
    % Allows for adding and deleting points
    %
    % zapit.gui.stimConfig.controller.mouseClick_Callback
    %
    % Rob Campbell - SWC 2023

    verbose = false;

    if verbose
        fprintf('mouseClick_Callback executed\n')
    end
    
    C = get(obj.hAx, 'CurrentPoint');
    X = C(1,1);
    Y = C(1,2);

    % Do not run if we are out of bounds
    xl = obj.hAx.XLim;
    yl = obj.hAx.YLim;
    if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
        return
    end
    
    % TODO -- should we make it impossible to place points outside of the brain?

    % Each time the user clicks we will add a new data point color and symbol.
    % Shift click and we delete it
    % Click and we add a point
    if obj.isCtrlPressed && ~isempty(obj.pAddedPoints)
        % remove a point
        ind = obj.findIndexOfAddedPointNearestCursor;
        delete(obj.pAddedPoints(ind))
        obj.pAddedPoints(ind) = [];
    elseif ~obj.isCtrlPressed % We are not removing a point so must be adding one
        % Add a point
        hold(obj.hAx,'on')

        if ~obj.isShiftPressed
            % We add a point as a new condition
            obj.pAddedPoints(end+1) = plot(obj.pCurrentPoint.XData, ...
                                            obj.pCurrentPoint.YData, ...
                                            obj.pointCommonProps{:}, ...
                                            'Marker', obj.currentSymbol, ...
                                            'Color', obj.currentColor, ...
                                            'Parent', obj.hAx);
        elseif obj.isShiftPressed && obj.BilateralButton.Value == 0
            % Then we append a point
            maxPointsPerCondition = obj.settings.experiment.maxStimPointsPerCondition;

            if length(obj.pAddedPoints(end).XData) < maxPointsPerCondition
                obj.pAddedPoints(end).XData(end+1) = obj.pCurrentPoint.XData;
                obj.pAddedPoints(end).YData(end+1) = obj.pCurrentPoint.YData;

                % Note if this was a bilateral or a unilateral condition and singular or plural number
                if  obj.BilateralButton.Value
                    uniBi = 'bilateral';
                else
                    uniBi = 'unilateral';
                end

                typeString = [uniBi,'_point'];
                if length(obj.pAddedPoints(end).XData)>1
                    typeString = [typeString,'s'];
                end
                obj.pAddedPoints(end).UserData = struct('type',typeString);

            else
                % Otherwise two many point for this condition
                fprintf('Maximum number of allowed points per stimulus condition is %d.\n', ...
                        maxPointsPerCondition)
            end % if length

        end % if  ~obj.isShiftPressed

        hold(obj.hAx,'on')

    end % if obj.isCtrlPressed && ~isempty(obj.pAddedPoints)



    % Update the text along the bottom
    obj.updateBottomLabel

end % mouseClick_Callback
