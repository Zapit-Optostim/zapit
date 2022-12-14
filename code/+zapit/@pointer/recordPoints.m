function points = recordPoints(obj)
    % Record the location of two points on the head in order to determine orientation
    %
    % function points = zapit.pointer.recordPoints(obj)
    %
    % Purpose
    % The first calibration phase was to align the camera and scan system. The second
    % phase is to determine the orientation of head. This allows us to re-use previous
    % sets of stimulation coordinates on a new animal. This function performs the task.
    %
    % When run the user is prompted to point the beam at bregma with a left click then
    % confirm the location with a right click. After this, the user is prompted to click
    % on a reference point specified in the stimulation config file. Again, left click
    % then right-click to confirm. Once this is done, the orientation and scale of the
    % head is determined and the stimulation points are superimposed onto the image. 
    %
    % The left click then right click allows for the location to be tweaked.
    % 
    % Inputs
    % none
    %
    % Outputs
    % points - The coordinates of the clicked points. The first column is x coordinates
    %          and the second is y coordinates.
    %
    % Maja Skretowska - SWC 2021
    
    title(obj.hImAx, '** Please click on bregma **');
    figure(obj.hFig)  % call figure to make sure matlab is waiting for clicks in the right window
    waitforbuttonpress;
    while obj.hFig.SelectionType ~= "alt"             % 'alt' is right-click in the figure
        points(1,:) = obj.hImAx.CurrentPoint([1 3]);    
        figure(obj.hFig)
        waitforbuttonpress;
    end

    figureText = sprintf('** Bregma recorded! Please click on %d %d ** ', obj.config.refPoints(:,2));
    title(obj.hImAx,figureText);
    figure(obj.hFig)

    waitforbuttonpress;

    while obj.hFig.SelectionType ~= "alt"
        points(2,:) = obj.hImAx.CurrentPoint([1 3]);
        figure(obj.hFig)
        waitforbuttonpress;
    end
    
    title(obj.hImAx, 'Both points recorded');

    hold(obj.hImAx, 'on');
    obj.hRefCoords = plot(obj.hImAx, points(:,1), points(:,2));
    hold(obj.hImAx, 'off');

end % recordPoints
