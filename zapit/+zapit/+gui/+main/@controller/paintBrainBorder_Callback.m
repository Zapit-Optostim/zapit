    function paintBrainBorder_Callback(obj,~,~)
    % Use the laser to draw the brain outline onto the sample
    %
    %    function zapit.gui.main.controller.checkScannerCalib(obj)
    %

    % This is a callback from a state button so it will run the scanners until unchecked

    if nargin>1
        % Only set GUI state if the *user* clicked the button
        % rather than than harmonizeGUIstate calling it.
        obj.GUIstate = mfilename;
    end

    if obj.PaintbrainborderButton.Value == 1

        if isempty(obj.model.calibratedBrainOutline)
            obj.PaintbrainborderButton.Value = 0;
            return
        end

        % TODO-- this code appears elsewhere in similar buttons on first tab.
        % Can we refactor it? See also paintArea_Callback, amongst others.
        if obj.CatMouseButton.Value == 1
            obj.CatMouseButton.Value = 0; % Both can not be activate at the the same time
            obj.catAndMouseButton_Callback;
        end

        if obj.PointModeButton.Value == 1
            obj.PointModeButton.Value = 0;
            obj.pointButton_Callback
        end
        obj.setCalibLaserSwitch('On');



        % Begin to run through the calibration coords
        obj.model.drawBrainOutlineOnSample

    elseif obj.PaintbrainborderButton.Value == 0

        obj.model.DAQ.stopAndDeleteAOTask; %Stop
        obj.setCalibLaserSwitch('Off');

    end

end % paintBrainBorder_Callback
