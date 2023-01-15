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

    for ii=1:length(obj.pAddedPoints)
        fieldName = sprintf('stimLocations%02d',ii);
        stimC.(fieldName).ML = round(obj.pAddedPoints(ii).XData,2);
        stimC.(fieldName).AP = round(obj.pAddedPoints(ii).YData,2);
    end
    
    stimC.laserPowerInMW = obj.LaserPowermWSpinner.Value;
    stimC.stimFreqInHz = obj.StimFreqHzSpinner.Value;

end % returnStimConfigStructure