function paintArea_Callback(obj,~,~)
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

        % Get stimulus index and from that the locations we will be stimulating
        stimIndex = find(cellfun(@(x) strcmp(x, obj.TestSiteDropDown.Value), obj.TestSiteDropDown.Items));
        locs = obj.model.stimConfig.stimLocations(stimIndex);
        [~,areaIndex] = obj.model.stimConfig.getAreaNameFromCoords(locs.ML,locs.AP);
        areaIndex = unique(areaIndex);
        obj.setCalibLaserSwitch('On');
        obj.model.drawBrainAreasOnSample(areaIndex);

    else
        obj.model.DAQ.stopAndDeleteAOTask; %Stop
        obj.setCalibLaserSwitch('Off');
    end


end % paintArea_Callback
