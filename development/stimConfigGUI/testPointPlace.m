function [uF,uA] = testPointPlace
    % Test adding points to a figure window by clicking on the plot

    uF = uifigure;
    uA = uiaxes('Parent',uF);



    uA.DataAspectRatio = [1,1,1]; % Make axis aspect ratio square
    pan(uA,'off')
    zoom(uA,'off')
    grid(uA,'on')
    uA.XLim = [0,1];
    uA.YLim = [0,1];
    uA.Box = 'on';



    p = plot(nan,nan,'ok','parent',uA);

    uF.WindowButtonDownFcn = @down_callback;


    function down_callback(~,evt)
        % Returns control to the user if they double-click on the ROI

        C = get (uA, 'CurrentPoint');
        X = C(1,1);
        Y = C(1,2);

        xl = uA.XLim;
        yl = uA.YLim;
        if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
            return
        end


        switch get(uF,'SelectionType')
        case 'normal'
            % Click and we add a point
            p.XData(end+1) = X;
            p.YData(end+1) = Y;
        case 'alt'
            % Right click and we delete the nearest point
            delta = [p.XData;p.YData]' - [X,Y];
            err = sum(sqrt(delta.^2),2);
            if isempty(err)
                return
            end
            [~,ind] = min(err);
            p.XData(ind)=[];
            p.YData(ind)=[];
        end
    end

end


