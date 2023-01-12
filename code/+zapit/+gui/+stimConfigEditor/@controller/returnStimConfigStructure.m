function stimC = returnStimConfigStructure(obj)
    % Return a structure that can be written as a stim config file based on the current plotted data

    stimC = [];
    if length(obj.pAddedPoints)<1
        return 
    end

    for ii=1:length(obj.pAddedPoints)
        fieldName = sprintf('stimLocations%02d',ii);
        stimC.(fieldName).ML = obj.pAddedPoints(ii).XData;
        stimC.(fieldName).AP = obj.pAddedPoints(ii).YData;
    end

    % TODO -- do we need to handle single points in some special retway?

    stimC.laserPowerInMW = obj.LaserPowermWSpinner.Value;
    stimC.stimFreqInHz = obj.StimFreqHzSpinner.Value;

end % returnStimConfigStructure