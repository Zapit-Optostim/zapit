function varargout = plotStimuli(stim)
    % Plot stimulus locations associated with a stim config file
    %
    % function zapit.utils.plotStimuli(stim)
    %
    % Purpose
    % Plot stimulus conditions as numbered points on a top-down 
    % atlas view. 
    %
    % Inputs
    % stim - Either: 1) Relative or absolute path to a stim config file
    %                2) An instance of a stimConfig object.
    %
    % Outputs
    % None
    %
    % Examples
    %
    % - To plot the currently loaded stim config in the GUI
    % >> zapit.utils.plotStimuli(hZP.stimConfig)
    %
    % - To plot a stim config file in the current directory
    % >> zapit.utils.plotStimuli('myStimuli.yml')
    %
    %
    % Rob Campbell - SWC, 2023


    if nargin<1
        fprintf('zapit.utils.%s requires an input argument defining stimulus details.\n', ...
                mfilename)
        return
    end

    if isempty(stim)
        return
    end

    % Load stimuli if needed
    if ischar(stim)
        if ~exist(stim,'file')
            fprintf('zapit.utils.%s can not find file "%s".\n', ...
                mfilename, stim)
            return
        end

        % Load the stimuli
        stim = zapit.stimConfig(stim);
    end % if

    %Load the data for making the brain plot
    load('atlas_data')


    % Make the figure window
    hFig = zapit.utils.focusNamedFig(mfilename);
    clf
    hFig.Color = 'w';
    hFig.ToolBar = 'none';
    hAx = cla;
    hold(hAx,'on')


    % Draw area boundaries
    brain_areas = atlas_data.dorsal_brain_areas; % For ease
    aBoundaries = cellfun(@(x) cellfun(@(x) plot(x(:,2),x(:,1),'color',[0.7,0.7,0.85]),x,'uni',false), ...
        {brain_areas.boundaries_stereotax},'uni', false);

    % Draw the brain boundary
    b = atlas_data.whole_brain.boundaries_stereotax{1};
    bBoundary = plot(b(:,2),b(:,1), 'color', [0.35,0.35,0.65], 'LineWidth', 1);


    % Prepare for adding the points and text labels
    sLoc = stim.stimLocations;
    ind = num2cell(1:length(sLoc));
    colors = lines(length(ind)); % The colormap
    [sLoc.ind] = ind{:};


    % Plot the stimulation points
    stimPoints = arrayfun(@(x) plot(x.ML, x.AP, 'ks','MarkerSize',16, 'MarkerFaceColor', colors(x.ind,:)), sLoc);

    % Add numbers to these points
    textLabels = arrayfun(@(x) text(x.ML, x.AP, num2str(x.ind), 'HorizontalAlignment','center' ,'color', 'w'), ...
            sLoc, 'uni', false);


    % Make the axes nice
    axis(hAx,'square')
    axis(hAx,'equal')
    axis(hAx,'tight')
    box(hAx,'on')
    grid(hAx,'on')
    hAx.XLim = [-5.3,5.3];
    hAx.XTick = -6:6;
    hAx.YLim = [-8,4.5];
    hAx.YTick = -8:4.5;
    xlabel(hAx,'ML (mm)')
    ylabel(hAx,'AP (mm)')
    hold(hAx,'off')

end % plotStimuli
