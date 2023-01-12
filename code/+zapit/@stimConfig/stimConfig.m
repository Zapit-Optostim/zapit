classdef stimConfig < handle

    % class for handling the configuration files used to
    % determine where the laser stim locations are
    %
    % Rob Campbell - SWC 2022

    properties

        configFileName % file name of the loaded stimConfig file

        % powerOption -  if 1 send 2 mW, if 2 send 4 mW (mean)
        powerOption % TODO - likely to be changed. This isn't a value in mW right now
        template % I think this where we stimulate
        chanSamples % The waveforms to be sent to the scanners
    end % properties

    properties (Hidden)
        parent  % the zapit.pointer to which this is attached
        numSamplesPerChannel
    end

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

            for ii = 1:size(obj.template,3)
                fieldName = sprintf('template_%02d',ii);
                data.(fieldName) = obj.template(:,:,ii);
            end

            zapit.yaml.WriteYaml(fname,data);
        end % writeConfig


        function n = numStimLocations(obj)
            % Return the number of stim locations as an integer
            n = size(obj.template,2);
        end % numStimLocations


        function cPoints = calibratedPoints(obj)
            % The stimulation locations after they have been calibrated to the sample
            cPoints = [];

            % TODO -- this is clearly not ideal
            cPoints(:,:,1) = zapit.utils.coordsRotation(...
                            obj.template(:,:,1), ...
                            obj.parent.refPointsStereotaxic, ...
                            obj.parent.refPointsSample);
            cPoints(:,:,2) = zapit.utils.coordsRotation(...
                            obj.template(:,:,2), ...
                            obj.parent.refPointsStereotaxic, ...
                            obj.parent.refPointsSample);
        end


        function cLibrary = coordsLibrary(obj)
            % Translate the obtained points into volts

            % TODO - I think this is where all computed waveforms are kept

            cLibrary = [];


            calibratedPoints = obj.calibratedPoints;

            % Certainly this is a non-idiomatic way of doing this
            [xVolt, yVolt] = obj.parent.mmToVolt(calibratedPoints(1,:,1), calibratedPoints(2,:,1)); % calibratedPoints should have an n-by-2 dimension
            [xVolt2, yVolt2] = obj.parent.mmToVolt(calibratedPoints(1,:,2), calibratedPoints(2,:,2));

            cLibrary = [xVolt' yVolt'];
            cLibrary(:,:,2) = [xVolt2' yVolt2'];

            % TODO:??
            % should now run makeChanSamples and should also run this again if laser power changes.
        end

    end % methods


end % config
