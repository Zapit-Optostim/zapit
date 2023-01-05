function dispFrame(obj,~,~)
    % This callback is run every time a frame has been acquired
    %
    %  function zapit.gui.main.controller(obj,~,~)
    %
    % Purpose
    % This callback listens to the lastAcuireFrame property on the model
    % and runs whenever it is modified.


    obj.hImLive.CData = obj.model.lastAcquiredFrame;

    % Set axis limits
    imSize = obj.model.imSize;
    obj.hImAx.XLim = [0,imSize(1)];
    obj.hImAx.YLim = [0,imSize(2)];

end % dispFrame
