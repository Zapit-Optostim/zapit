function stopPreview(obj)
    % Stop the preview of the camera feed
    %
    %  function zapit.gui.main.controller.stopPreview()
    %
    % Purpose
    % Stop the camera preview.

    stoppreview(obj.model.cam.vid)

end % stopPreview
