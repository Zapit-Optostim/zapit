function paintArea_Callback(obj)
    % Paint brain area
    %
    % zapit.gui.main.controller.paintArea_Callback
    %
    % Purpose
    % Paint brain area onto sample


    if isempty(obj.model.stimConfig)
        obj.PaintareaButton.Value = 0;
        return
    end

    if nargin>1
        % Only set GUI state if the *user* clicked the button
        % rather than than harmonizeGUIstate calling it.
        obj.GUIstate = mfilename;
    end

    if obj.PaintareaButton.Value == 1

        obj.setCalibLaserSwitch('On');

    else
        obj.model.DAQ.stopAndDeleteAOTask; %Stop
        obj.setCalibLaserSwitch('Off');
    end


end % paintArea_Callback
