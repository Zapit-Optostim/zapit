function storeLastFrame(obj,~,~)
    % This callback is run every time a frame has been acquired
    %
    %  function zapit.pointer.storeLastFrame(obj,~,~)
    %
    % Purpose
    % Stores the last acquired frame in an observable property

    if obj.cam.vid.FramesAvailable==0
        return
    end


    tmp = obj.cam.getLastFrame;
    if obj.settings.camera.flipImageUD == 1
        tmp = flipud(tmp);
    end

    if obj.settings.camera.flipImageLR == 1
        tmp = fliplr(tmp);
    end

    obj.lastAcquiredFrame = tmp;
    obj.cam.flushdata
end % storeLastFrame
