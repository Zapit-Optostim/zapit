function writeConfig(obj,fname)
    % Write a YAML config file
    %
    % zapit.stimConfig.writeConfig(fname)
    %
    % Purpose
    % Write properties into a stim config YAML file that can be re-read.

    % stimModulationFreqHz is global to the whole config so it is written once at the
    % top level. laserPowerInMW and offRampDownDuration_ms are per-condition and live
    % inside each condition's Attributes (written with the stimLocations below); they are
    % NOT written at the top level because loadConfig reads them per-condition and a
    % top-level copy would be dead, misleading data.
    data.stimModulationFreqHz = obj.stimModulationFreqHz;

    for ii = 1:obj.numConditions
        fieldName = sprintf('stimLocations%02d',ii);
        data.(fieldName) = obj.stimLocations(ii);
    end

    zapit.yaml.WriteYaml(fname,data);
end % writeConfig
