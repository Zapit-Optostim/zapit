function points = recordPoints(obj)
    % TODO -- remove & refactor
    % choose a point by left-click in the figure, and report
    % the choice by right-click (then proceed to next step)
    
    % left-click automatically sends the beam to the location
    % by the callback pointBeamToLocationInImage function
    
    title(obj.hImAx, 'click bregma');
    figure(obj.hFig)                                  % call figure to make sure matlab is waiting for clicks in the right window
    waitforbuttonpress;
    while obj.hFig.SelectionType ~= "alt"             % 'alt' is right-click in the figure
        points(1,:) = obj.hImAx.CurrentPoint([1 3]);    % so until left-click choice is confirmed with right click, you can change location of the beam until precise enough
        figure(obj.hFig)
        waitforbuttonpress;
    end

    figureText = sprintf('bregma recorded, click %d %d ', obj.config.refPoints(:,2));
    title(obj.hImAx,figureText);
    figure(obj.hFig)

    waitforbuttonpress;

    while obj.hFig.SelectionType ~= "alt"
        points(2,:) = obj.hImAx.CurrentPoint([1 3]);
        figure(obj.hFig)
        waitforbuttonpress;
    end
    
    title(obj.hImAx, 'both points recorded');

    hold(obj.hImAx, 'on');
    obj.hRefCoords = plot(obj.hImAx, points(:,1), points(:,2));
    hold(obj.hImAx, 'off');

end
