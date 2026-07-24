function loadConfig(obj,fname)
    % Load a YAML config file
    %
    % zaptit.stimConfig.loadConfig(fname)

    if ~exist(fname)
        fprintf('No config file found at "%s"\n', fname)
        return
    end

    data = zapit.yaml.ReadYaml(fname);

    ind = 1;

    obj.stimLocations = struct(...
                        'ML', [], ...
                        'AP', [], ...
                        'Class', [], ...
                        'Type', [], ...
                        'Attributes',[]);

    while true
        fieldName = sprintf('stimLocations%02d',ind);
        if isfield(data,fieldName)
            tmp = data.(fieldName);
            if length(tmp.ML)>1
                tmp.ML = cell2mat(tmp.ML);
                tmp.AP = cell2mat(tmp.AP);
            end
            obj.stimLocations(ind) = tmp;
        else
            break
        end
        ind = ind + 1;
    end

    % laserPowerInMW and offRampDownDuration_ms are genuinely per-condition (they are
    % re-read for each trial in zapit.pointer.sendSamples). The root properties here just
    % seed a default from the first condition.
    obj.laserPowerInMW = obj.stimLocations(1).Attributes.laserPowerInMW;
    obj.offRampDownDuration_ms = obj.stimLocations(1).Attributes.offRampDownDuration_ms;

    % stimModulationFreqHz is global to the whole config (all conditions share one
    % waveform length), so it is stored as a single top-level field. Older config files
    % stored a copy inside every condition's Attributes; for those we fall back to the
    % first condition's value and warn the user to re-save so the file is migrated.
    if isfield(data,'stimModulationFreqHz')
        obj.stimModulationFreqHz = data.stimModulationFreqHz;
    elseif isstruct(obj.stimLocations(1).Attributes) && ...
            isfield(obj.stimLocations(1).Attributes,'stimModulationFreqHz')
        obj.stimModulationFreqHz = obj.stimLocations(1).Attributes.stimModulationFreqHz;
        fprintf(['\n ** Note: %s stores stimModulationFreqHz per condition, which is ', ...
            'deprecated.\n    It is now a single setting for the whole config. Using the ', ...
            'first condition''s value (%g Hz).\n    Re-save the config to update the file.\n\n'], ...
            fname, obj.stimModulationFreqHz)
    else
        fprintf(' ** Warning: no stimModulationFreqHz found in %s\n', fname)
    end

    % Drop any deprecated per-condition copy so it cannot be edited misleadingly and so a
    % re-save (writeConfig) does not re-emit it inside each condition.
    for ii = 1:length(obj.stimLocations)
        if isstruct(obj.stimLocations(ii).Attributes) && ...
                isfield(obj.stimLocations(ii).Attributes,'stimModulationFreqHz')
            obj.stimLocations(ii).Attributes = ...
                rmfield(obj.stimLocations(ii).Attributes,'stimModulationFreqHz');
        end
    end


    obj.configFileName = fname;
end % loadConfig
