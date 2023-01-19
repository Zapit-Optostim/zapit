function logStimulusParametersToFile(obj, filePath)
    % Write all relevant data associated with this set of stimuli to a YAML file
    %
    % function logStimulusParametersToFile(obj, filePath)
    %
    % Purpose
    % Create a log file so we know exactly under what conditions stimuli were
    % presented in an experiment. This includes not only stimulus locations and
    % parameters but also software version. It is critical to generate this file
    % or it may not be possible to analyse data afterwards.
     
    v = zapit.version;
    data.zapitVersion = v.message;

    v=ver('MATLAB');
    data.MATLAB = sprintf('%s %s version %s', v.Name, v.Release, v.Version);

    [~, hostname] = system('hostname');
    data.hostname = strip(hostname);

    data.laserPowerInMW = obj.laserPowerInMW;
    data.stimFreqInHz = obj.stimFreqInHz;
    data.offRampDownDuration_ms = obj.offRampDownDuration_ms;

    for ii = 1:length(obj.stimLocations)
        fieldName = sprintf('stimLocations%02d',ii);
        data.(fieldName) = obj.stimLocations(ii);
    end

    fname = sprintf('zapit_log_%s.yml', datestr(now,'yyyy_mm_dd__HH-MM'));

    zapit.yaml.WriteYaml(fullfile(filePath,fname), data);
end % logStimulusParametersToFile
