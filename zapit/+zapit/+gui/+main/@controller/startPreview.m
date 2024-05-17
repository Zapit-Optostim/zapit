function startPreview(obj)
    % Starts the preview of the camera feed
    %
    %  function zapit.gui.main.controller.startPreview()
    %
    % Purpose
    % Start the camera preview.

    % TODO-- stop the preview warning about 8 bit images
    preview(obj.model.cam.vid,obj.hImLive)

end % startPreview
