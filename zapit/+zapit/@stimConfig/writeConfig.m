function writeConfig(obj,fname)
    % Write a YAML config file
    %
    % zapit.stimConfig.writeConfig(fname)
    %
    % Purpose
    % Write properties into a stim config YAML file that can be re-read.

    data.laserPowerInMW = obj.laserPowerInMW;
    data.stimFreqInHz = obj.stimFreqInHz;
    data.offRampDownDuration_ms = obj.offRampDownDuration_ms;

    for ii = 1:length(obj.stimLocations)
        fieldName = sprintf('stimLocations%02d',ii);
        data.(fieldName) = obj.stimLocations(ii);
    end

    zapit.yaml.WriteYaml(fname,data);
end % writeConfig