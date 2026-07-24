function stimC = returnStimConfigStructure(obj)
    % Return a structure that can be written as a stim config file based on the current plotted data
    %
    % zapit.gui.stimConfig.controller.returnStimConfigStructure
    %
    % Purpose
    % Extract data from plotted points and return these as a structure that can be save
    % to disk and so used to create a stimConfig YAML file. 
    %
    % Rob Campbell - SWC 2023


    stimC = [];
    if length(obj.pAddedPoints)<1
        return
    end

    % laserPowerInMW and offRampDownDuration_ms are per-condition. When the corresponding
    % control is enabled all conditions share the value it shows (the normal case). When
    % it is disabled the loaded config had different values per condition, which a single
    % control cannot represent, so we write each point's own stored value. This is what
    % lets per-condition values survive a load -> save round-trip.
    laserSpinnerEnabled = strcmp(char(obj.LaserPowermWSpinner.Enable),'on');
    rampSpinnerEnabled  = strcmp(char(obj.RampdownmsSpinner.Enable),'on');

    for ii=1:length(obj.pAddedPoints)
        fieldName = sprintf('stimLocations%02d',ii);
        ud = obj.pAddedPoints(ii).UserData;

        stimC.(fieldName) = zapit.stimConfig.stimLocations; %create a template
        stimC.(fieldName).ML = round(obj.pAddedPoints(ii).XData,2);
        stimC.(fieldName).AP = round(obj.pAddedPoints(ii).YData,2);
        stimC.(fieldName).Type = ud.type;

        if laserSpinnerEnabled || ~isfield(ud,'laserPowerInMW')
            attributes.laserPowerInMW = obj.LaserPowermWSpinner.Value;
        else
            attributes.laserPowerInMW = ud.laserPowerInMW;
        end

        if rampSpinnerEnabled || ~isfield(ud,'offRampDownDuration_ms')
            attributes.offRampDownDuration_ms = obj.RampdownmsSpinner.Value;
        else
            attributes.offRampDownDuration_ms = ud.offRampDownDuration_ms;
        end

        stimC.(fieldName).Attributes = attributes;
    end

    % stimModulationFreqHz is global to the whole config, so it is a single top-level
    % field rather than a per-condition attribute.
    stimC.stimModulationFreqHz = obj.StimFreqHzSpinner.Value;

end % returnStimConfigStructure
