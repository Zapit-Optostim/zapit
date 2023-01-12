function mouseClick_Callback(obj,~,~)

    % Allows for adding and deleting points


    C = get(obj.hAx, 'CurrentPoint');
    X = C(1,1);
    Y = C(1,2);

    % Do not run if we are out of bounds
    xl = obj.hAx.XLim;
    yl = obj.hAx.YLim;
    if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
        return
    end


    % Each time the user clicks we will add a new data point color and symbol.
    % Shift click and we delete it
    % Click and we add a point
    if obj.isShiftPressed && length(obj.pAddedPoints)>0
        % remove a point
        ind = obj.findIndexOfAddedPointNearestCursor;
        delete(obj.pAddedPoints(ind))
        obj.pAddedPoints(ind) = [];
    elseif ~obj.isShiftPressed
        % Add a point
        hold(obj.hAx,'on')
        obj.pAddedPoints(end+1) = plot(obj.pCurrentPoint.XData, ...
                                        obj.pCurrentPoint.YData, ...
                                        obj.pointCommonProps{:}, ...
                                        'Marker', obj.currentSymbol, ...
                                        'Color', obj.currentColor, ...
                                        'Parent', obj.hAx);
        hold(obj.hAx,'on')
    end


end