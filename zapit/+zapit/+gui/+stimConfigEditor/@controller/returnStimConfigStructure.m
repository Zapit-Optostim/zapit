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

    % All will share the same values right now but this can be changed in the file.
    % NOTE (TODO) the rep rate will always be whatever the first stim loc is:
    %  https://github.com/Zapit-Optostim/zapit/issues/9

    pointAttributes.laserPowerInMW = obj.LaserPowermWSpinner.Value;
    pointAttributes.stimDutyCycleHz = obj.StimFreqHzSpinner.Value;
    pointAttributes.offRampDownDuration_ms = obj.RampdownmsSpinner.Value;

    for ii=1:length(obj.pAddedPoints)
        fieldName = sprintf('stimLocations%02d',ii);
        stimC.(fieldName) = zapit.stimConfig.stimLocations; %create a template
        stimC.(fieldName).ML = round(obj.pAddedPoints(ii).XData,2);
        stimC.(fieldName).AP = round(obj.pAddedPoints(ii).YData,2);
        stimC.(fieldName).Type = obj.pAddedPoints(ii).UserData.type;

        % The attributes for each point can be different in theory even if at
        % the moment we make them all the same.
        stimC.(fieldName).Attributes = pointAttributes;


    end

end % returnStimConfigStructure
