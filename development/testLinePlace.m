function [uF,uA] = testPointPlace
    % Test adding a line that follows the cursor as it goes down.
    %
    % Clicking adds points. Shift-clicking removes them.

    uF = uifigure;
    uA = uiaxes('Parent',uF);



    uA.DataAspectRatio = [1,1,1]; % Make axis aspect ratio square
    pan(uA,'off')
    zoom(uA,'off')
    grid(uA,'on')
    uA.XLim = [0,1];
    uA.YLim = [0,1];
    uA.Box = 'on';



    p = plot(nan,nan,'ok-', 'markerfacecolor',[1,1,1]*0.5,'parent',uA);

    uF.WindowButtonDownFcn = @down_callback;
    uF.WindowButtonMotionFcn = @line_extender;
    currentLineLength = 1;
    function down_callback(sr,evt)
        % Returns control to the user if they double-click on the ROI

        C = get (uA, 'CurrentPoint');
        X = C(1,1);
        Y = C(1,2);

        xl = uA.XLim;
        yl = uA.YLim;
        if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
            return
        end

        if ~isShiftPressed
            p.XData(currentLineLength+1) = X;
            p.YData(currentLineLength+1) = Y;
        else
            delta = [p.XData;p.YData]' - [X,Y];
            err = sum(sqrt(delta.^2),2);

            if isempty(err)
                return
            end
            [mm,ind] = min(err);
            p.XData(ind)=[];
            p.YData(ind)=[];
        end

        currentLineLength = length(p.YData);
    end

    function line_extender(~,evt)
        if isShiftPressed
            p.XData = p.XData(1:currentLineLength);
            p.YData = p.YData(1:currentLineLength);
            return
        end

        C = get (uA, 'CurrentPoint');
        X = C(1,1);
        Y = C(1,2);

        xl = uA.XLim;
        yl = uA.YLim;
        if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
            return
        end

        n = currentLineLength+1;
        p.XData(n) = X;
        p.YData(n) = Y;
    end

    function isPressed = isShiftPressed
        mod = get(gcbo,'currentModifier');
        isPressed = false;
        if length(mod)==1
            isPressed = strcmp(mod{1},'shift');
        end
    end

end


