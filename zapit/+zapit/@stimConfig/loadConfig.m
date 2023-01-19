function loadConfig(obj,fname)
    % Load a YAML config file
    %
    % zaptit.stimConfig.loadConfig(fname)

    if ~exist(fname)
        fprintf('No config file found at "%s"\n', fname)
        return
    end

    data = zapit.yaml.ReadYaml(fname);

    obj.laserPowerInMW = data.laserPowerInMW;
    obj.stimFreqInHz = data.stimFreqInHz;
    obj.offRampDownDuration_ms = data.offRampDownDuration_ms;

    % Loop through a import all stimLocations
    obj.stimLocations = struct('ML',[],'AP',[]);
    ind = 1;
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
    obj.configFileName = fname;
end % loadConfig
