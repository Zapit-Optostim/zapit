function dispFrame(obj,~,~)
    % This callback is run every time a frame has been acquired
    %
    %  function zapit.gui.main.controller()
    %
    % Purpose
    % This callback listens to the lastAcuireFrame property on the model
    % and runs whenever it is modified.


    obj.hImLive.CData = obj.model.lastAcquiredFrame;

end % dispFrame
