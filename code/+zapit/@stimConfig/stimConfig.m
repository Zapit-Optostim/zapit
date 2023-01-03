classdef stimConfig < handle

    % class for handling the configuration files used to
    % determine where the laser stim locations are
    %
    % Rob Campbell - SWC 2022

    properties

        configFileName % file name of the loaded stimConfig file

        % powerOption -  if 1 send 2 mW, if 2 send 4 mW (mean)
        powerOption % TODO - likely to be changed. This isn't a value in mW right now
        refPoints % Reference points
        template % I think this where we stimulate
    end % properties

    methods
        function obj = stimConfig(fname)
            % Construct a stimConfig file object and load data
            obj.loadConfig(fname)
        end % Constructor


        function delete(obj)
        end % Destructor


        function loadConfig(obj,fname)
            % Load a YAML config file
            %
            % zaptit.stimConfig.loadConfig(fname)

            if ~exist(fname)
                fprintf('No config file found at "%s"\n', fname)
                return
            end

            data = zapit.yaml.ReadYaml(fname);

            obj.powerOption = data.powerOption;
            obj.refPoints = cell2mat(data.refPoints);


            % template is 2 by n (by n?) array
            template = [];
            ind = 1;
            while true
                fieldName = sprintf('template_%02d',ind);
                if isfield(data,fieldName)
                    template(:,:,ind) = cell2mat(data.(fieldName));
                else
                    break
                end
                ind = ind + 1;
            end
            obj.template = template;
            obj.configFileName = fname;
        end % loadConfig


        function writeConfig(obj,fname)
            % Write a YAML config file
            %
            % zapit.stimConfig(fname)
            %
            data.powerOption = obj.powerOption;
            data.refPoints = obj.refPoints;


            for ii = 1:size(obj.template,3)
                fieldName = sprintf('template_%02d',ii);
                data.(fieldName) = obj.template(:,:,ii);
            end

            zapit.yaml.WriteYaml(fname,data);
        end % writeConfig
    end % methods


end % config
