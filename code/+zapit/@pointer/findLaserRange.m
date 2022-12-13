function laserPower = findLaserRange(obj)
    ii = 0;
    condition = 1;
    while condition
        try
            ii = ii + 1;
            % press left (without waiting for right)
            figure(obj.hFig);
            waitforbuttonpress
            laserPower([1 2], ii) = obj.hImAx.CurrentPoint([1 3])';
            laserPower(3, ii) = input(char("what's the power (if you want to finish)"));
            
            if laserPower(3, ii) == -1
                condition = 0;
                obj.hTask.stop;
            else
                marker_color = [1 (1-(laserPower(3,ii)/3)) 1];
                hold on;
                plot(obj.hImAx, laserPower(1,ii), laserPower(2, ii), 'o', ...
                    'MarkerEdgeColor', marker_color, 'MarkerFaceColor', marker_color);
            end
        catch
            return
        end
    end
end
