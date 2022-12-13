function plotLaserRange(obj, laserPower)
    % 
    % function zapit.pointer.plotLaserRange(obj, laserPower)
    %
    % Maja Skretowska - SWC 2021


    dotNum = size(laserPower, 2);
    laserPower = laserPower(:, laserPower(3,:) ~= -1);
    powerMean = mean(laserPower(3,laserPower));
    laserPower(3,:) = and(laserPower(3,:)>(0.95*powerMean), laserPower(3,:)<(1.05*powerMean));
    for ii = 1:dotNum
        marker_color = [1 (laserPower/2) 1];
        hold on;
        plot(obj.hImAx, laserPower(1,ii), laserPower(2, ii), 'o', ...
            'MarkerEdgeColor', marker_color, 'MarkerFaceColor', marker_color, 'MarkerSize', 1);
    end
end
