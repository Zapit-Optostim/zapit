function pasteBrainAtClick(atlas_data)
    % Test adding the brain border with bregma on the mouse click location


    uF = uifigure;
    uA = uiaxes('Parent',uF);

    b = atlas_data.whole_brain.boundaries_stereotax{1};

    uA.DataAspectRatio = [1,1,1]; % Make axis aspect ratio square
    pan(uA,'off')
    zoom(uA,'off')
    grid(uA,'on')
    uA.XLim = [-12,12];
    uA.YLim = [-14,10];
    uA.Box = 'on';
    title('Click to add brain with bregma on clicked point','parent',uA)


    p = plot(nan,nan,'-','parent',uA);

    uF.WindowButtonDownFcn = @down_callback;



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

        p.XData = b(:,2)+X;
        p.YData = b(:,1)+Y;
    end

end % testROI



