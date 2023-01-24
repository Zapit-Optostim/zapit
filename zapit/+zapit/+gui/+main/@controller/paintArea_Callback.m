function obj.paintArea_Callback(obj,~,~)
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

    if obj.PaintareaButton.Value == 1

        % TODO-- this code appears elsewhere in similar buttons on first tab.
        % Can we refactor it? See also paintBrainBorder_Callback, amongst others.
        if obj.CatMouseButton.Value == 1
            obj.CatMouseButton.Value = 0; % Both can not be activate at the the same time
            obj.catAndMouseButton_Callback;
        end

        if obj.PointModeButton.Value == 1
            obj.PointModeButton.Value = 0;
            obj.pointButton_Callback
        end
        obj.setCalibLaserSwitch('On');

    else
        obj.model.DAQ.stopAndDeleteAOTask; %Stop
        obj.setCalibLaserSwitch('Off');
    end


end % paintArea_Callback
