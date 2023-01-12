function plotBrainBoundaries(obj)
    % Plot the brain boundaries and set up figure
    %
    % zapit.gui.stimConfigEditor.controller.plotBrain
    %
    % Purpose
    % Plot brain boundaries and set up figure


    % Plot settings
    brain_color = 'k';
    grid_color = [0.5,0.5,0.5];
    bregma_color = 'b';
    grid_spacing = 0.5; % in mm


    hold(obj.hAx,'on')
    grid(obj.hAx,'on')
    box(obj.hAx,'on')
    axis(obj.hAx,'equal')

    obj.hAx.GridColor = grid_color;

    obj.hAx.XLabel.String = 'ML [mm from bregma]';
    obj.hAx.YLabel.String = 'AP [mm from bregma]';

    obj.hAx.XLim = [-5.5,5.5];
    obj.hAx.YLim = [-8,4];

    xticks(obj.hAx, -5:grid_spacing:5);
    yticks(obj.hAx, -8:grid_spacing:5);

    obj.hAxTitle = title('','Parent',obj.hAx);

    % Draw cortical boundaries
    brain_areas = obj.atlasData.dorsal_brain_areas; % For ease

    cellfun(@(x) cellfun(@(x) plot(x(:,2),x(:,1),'color',brain_color,'Parent',obj.hAx),x,'uni',false), ...
        {brain_areas.boundaries_stereotax},'uni', false);

    % Plot bregma
    obj.pBregma = plot(0, 0, 'ok', 'MarkerFaceColor', bregma_color, 'MarkerSize', 9, 'Parent', obj.hAx);

    % Plot ticks along axes that will move with mouse cursor
    obj.pMLtick = plot([0,0],[-8,-7.5],'-r','LineWidth',3,'Parent',obj.hAx);
    obj.pAPtick = plot([-5.5,-5],[0,0],'-r','LineWidth',3,'Parent',obj.hAx);
    obj.pMLtick.Visible='off';
    obj.pAPtick.Visible='off';



    pan(obj.hAx,'off')
    zoom(obj.hAx,'off')
    obj.hAx.XLimMode = 'manual';
    obj.hAx.YLimMode = 'manual';
    hold(obj.hAx,'off')
end