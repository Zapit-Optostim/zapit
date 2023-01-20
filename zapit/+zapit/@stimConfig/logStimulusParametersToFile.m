function varargout = logStimulusParametersToFile(obj, filePath)
    % Write all relevant data associated with this set of stimuli to a YAML file
    %
    % function fname = logStimulusParametersToFile(obj, filePath)
    %
    % Purpose
    % Create a log file so we know exactly under what conditions stimuli were
    % presented in an experiment. This includes not only stimulus locations and
    % parameters but also software version. It is critical to generate this file
    % or it may not be possible to analyse data afterwards.
    %
    % Inputs
    % filePath - the path to the file to write.
    %
    % Outputs
    % fname - the fname of the file that was written.
    %
    % Rob Campbell - SWC 2023
     
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

    fname = sprintf('%s%s.yml', obj.logFileStem, datestr(now,'yyyy_mm_dd__HH-MM'));

    zapit.yaml.WriteYaml(fullfile(filePath,fname), data);

    if nargin>1
        varargout{1}=fname;
    end

end % logStimulusParametersToFile
