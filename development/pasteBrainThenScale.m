function pasteBrainThenScale(atlas_data)
    % First click places bregma of border brain at clicked location
    % Mouse motion: brain scales and rotates to follow cursor
    % Second click places second ref point and brain stops moving

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
    hold(uA,'on')
    p_bregma = plot(nan,nan,'or','markerfacecolor','r','parent',uA);
    hold(uA,'off')

    refPoints = zeros(2);
    atlasRef = [0,0;0,3];

    nInd = 1;

    uF.WindowButtonDownFcn = @down_callback;
    uF.WindowButtonMotionFcn = @line_extender;



    function down_callback(sr,evt)

        if strcmp(uF.SelectionType,'alt')
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


        % Paste
        if nInd == 1
            p.XData = b(:,2)+X;
            p.YData = b(:,1)+Y;

            refPoints(nInd,:) = [X,Y];
            nInd = nInd + 1;
            p_bregma.XData=X;
            p_bregma.YData=Y;
        elseif nInd==2
            if isShiftPressed
                nInd = 1;
                refPoints(:,2) = 0;
                p_bregma.XData=nan;
                p_bregma.YData=nan;
            else
                disp('ADDING AGAIN')
                nInd = nInd + 1;
            end
        elseif nInd==3 & isShiftPressed
            nInd = nInd-1;
        end


    end


    function line_extender(~,evt)

        C = get (uA, 'CurrentPoint');
        X = C(1,1);
        Y = C(1,2);

        xl = uA.XLim;
        yl = uA.YLim;
        if X<xl(1) || X>xl(2) || Y<yl(1) || Y>yl(2)
            return
        end

        if nInd==1
            % follow mouse
            p.XData = b(:,2)+X;
            p.YData = b(:,1)+Y;
        end

        if nInd==2
            % Rotate and scale only if mouse cursor is over 1 mm from bregma
            err = refPoints(1,:)-[X,Y];
            if sum(sqrt(err.^2))<1.5
                return
            end
            refPoints(nInd,:) = [X,Y];

            newpoint = zapit.utils.coordsRotation(fliplr(b)',atlasRef, refPoints)';
            newpoint = fliplr(newpoint);
            p.XData = newpoint(:,2);
            p.YData = newpoint(:,1);
        end
    end

    function isPressed = isShiftPressed
        mod = get(gcbo,'currentModifier');
        isPressed = false;
        if length(mod)==1
            isPressed = strcmp(mod{1},'shift');
        end
    end

end

