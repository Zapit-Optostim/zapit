function testCoordsLibrary(obj, verbose)
    % move laser into each stimulation position to confirm accuracy
    %
    % function testCoordsLibrary(obj)
    %
    % Purpose
    % Plots the stimulation locations then cycles the laser between them to confirm it is able to
    % go to all the requested positiopns.
    %
    % Inputs
    % verbose - [optional] prints to screen diagnostic info. false by default.
    %
    % Outputs
    % none
    %
    %
    % Maja Skretowska - SWC 2021
    % Rob Campbell - SWC 2022

    if nargin<2
        verbose = false;
    end

    obj.hLastPoint.Visible = 'off';
    obj.setLaserInMW(20) 
    hold(obj.hImAx, 'on');

    % Plot points to stimulate in different colors for each brain area on the two sides of the brain
    % TODO: certainly not everyone will do things this way. So this needs to be optional. Some might
    % want unilateral only, for instance.
    colors = lines(size(obj.newpoint(1,:,1),2));
    for ii = 1:size(obj.newpoint(1,:,1),2)
        prop = {'MarkerSize',12,'MarkerEdgeColor', colors(ii,:), 'LineWidth',2};
        % Left hemisphere
        obj.plotOverlayHandles.(mfilename).hAreaCoords(ii,1) = ...
           plot(obj.hImAx, obj.newpoint(1,ii,1), obj.newpoint(2,ii,1), 'o', prop{:});

        % Right hemisphere
        obj.plotOverlayHandles.(mfilename).hAreaCoords(ii,2) = ...
            plot(obj.hImAx, obj.newpoint(1,ii,2), obj.newpoint(2,ii,2), 'o', prop{:});
    end
    hold(obj.hImAx, 'off');

    % TODO - run fast and cycle until user quits. This will have to wait until we have a full GUI.
    for xx = 1:length(obj.newpoint)
        for yy = 1:2
            if verbose
                fprintf('Testing coordinate %0.2f %0.2f\n', ...
                 obj.coordsLibrary(xx, 1, yy), ...
                 obj.coordsLibrary(xx, 2, yy))
            end
            obj.DAQ.moveBeamXY([obj.coordsLibrary(xx, 1, yy), obj.coordsLibrary(xx, 2, yy)]);
            pause(0.25)
        end
    end

    obj.removeOverlays(mfilename)


    obj.hLastPoint.Visible = 'on';
    obj.setLaserInMW(0)
end  % testCoordsLibrary

