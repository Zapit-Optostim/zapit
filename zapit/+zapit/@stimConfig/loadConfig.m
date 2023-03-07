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

    % Fill in these values with whatever is in the first condition for now.
    % TODO -- might change this in future but for some things, like stim freq,
    % changing on a trial by trial basis might be a little more work so we
    % do not implement for now. SO HIDE FROM USER THAT THIS CAN BE DONE!
    obj.laserPowerInMW = obj.stimLocations(1).Attributes.laserPowerInMW;
    obj.stimModulationFreqHz = obj.stimLocations(1).Attributes.stimModulationFreqHz;
    obj.offRampDownDuration_ms = obj.stimLocations(1).Attributes.offRampDownDuration_ms;


    obj.configFileName = fname;
end % loadConfig
