classdef stimConfig < handle

    % class for handling the configuration files used to
    % determine where the laser stim locations are
    %
    % Rob Campbell - SWC 2022

    properties

        configFileName % file name of the loaded stimConfig file


        laserPowerInMW
        stimFreqInHz
        stimLocations
        % powerOption -  if 1 send 2 mW, if 2 send 4 mW (mean)
        powerOption = 1 % TODO leave for now but delete as soon as possible

    end % properties

    properties (Hidden)
        parent  % the zapit.pointer to which this is attached
        numSamplesPerChannel
    end

    % read-only properties that are associated with getters
    properties(SetAccess=protected, GetAccess=public)
        chanSamples % The waveforms to be sent to the scanners
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

            obj.laserPowerInMW = data.laserPowerInMW;
            obj.stimFreqInHz = data.stimFreqInHz;


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


        function writeConfig(obj,fname)
            % Write a YAML config file
            %
            % zapit.stimConfig(fname)
            %


            for ii = 1:length(obj.stimLocations)
                fieldName = sprintf('stimLocations%02d',ii);
                data.(fieldName) = obj.stimLocations(ii);
            end

            data.laserPowerInMW = obj.laserPowerInMW;
            data.stimFreqInHz = obj.stimFreqInHz;

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
            cPoints(:,:,1) = zapit.utils.rotateAndScaleCoords(...
                            obj.template(:,:,1), ...
                            obj.parent.refPointsStereotaxic, ...
                            obj.parent.refPointsSample);
            cPoints(:,:,2) = zapit.utils.rotateAndScaleCoords(...
                            obj.template(:,:,2), ...
                            obj.parent.refPointsStereotaxic, ...
                            obj.parent.refPointsSample);
        end % calibratedPoints


        function cLibrary = coordsLibrary(obj)
            % Translate the obtained points into volts
            %
            % coordsLibrary
            %
            % Purpose
            % Returns the compute waveforms. 

            cLibrary = [];


            calibratedPoints = obj.calibratedPoints;

            % Certainly this is a non-idiomatic way of doing this
            [xVolt, yVolt] = obj.parent.mmToVolt(calibratedPoints(1,:,1), calibratedPoints(2,:,1)); % calibratedPoints should have an n-by-2 dimension
            [xVolt2, yVolt2] = obj.parent.mmToVolt(calibratedPoints(1,:,2), calibratedPoints(2,:,2));

            cLibrary = [xVolt' yVolt'];
            cLibrary(:,:,2) = [xVolt2' yVolt2'];

        end % coordsLibrary



        function chanSamples = get.chanSamples(obj)
            % Prepares voltages for each photostimulation site
            %
            % zapit.stimConfig.makeChanSamples(laserPowerInMW)
            %
            %
            % Inputs
            % laserPowerInMW - Desired laser power in mW. Optional. If missing the
            %    value in the object property is used.
            %
            % Outputs
            % None but the chanSamples property is updated.
            %
            % Maja Skretowska - 2021

            coordsLibrary = obj.coordsLibrary;
            numHalfCycles = 4; % arbitrary, no of half cycles to buffer

            % TODO: defaultLaserFrequency will probably be used to make the brain area config file and from there that will be the relevant value
            obj.numSamplesPerChannel = obj.parent.DAQ.samplesPerSecond/obj.parent.settings.experiment.defaultLaserFrequency*(numHalfCycles/2);

            % find edges of half cycles
            cycleEdges = linspace(1, obj.numSamplesPerChannel, numHalfCycles+1);
            edgeSamples = ceil(cycleEdges(1,:));


            % make up samples for scanner channels
            % (coordsLibrary is already in a volt format)
            scanChnl = zeros(obj.numSamplesPerChannel,2,size(coordsLibrary,2)); % matrix for each channel
            %             lghtChnl = zeros(obj.numSamplesPerChannel,2,2);                         % 1st dim is samples, 2nd dim is channel, 3rd dim is conditions

            %% make up scanner volts to switch between two areas
            for inactSite = 1:size(coordsLibrary, 1)    % CHECK if it really is the first dim

                % inactSite gets column from the coordinates library
                xVolts = coordsLibrary(inactSite,1,:);
                yVolts = coordsLibrary(inactSite,2,:);
                for cycleNum = 1:(length(edgeSamples)-1)
                    segStart = edgeSamples(cycleNum);
                    segStop = edgeSamples(cycleNum+1);
                    siteIndx = rem(cycleNum+1,2)+1;         % check whether it's an odd (rem = 1) or even (rem = 0) number and then add 1 to get an index
                    scanChnl(segStart:segStop,1,inactSite) = xVolts(siteIndx);
                    scanChnl(segStart:segStop,2,inactSite) = yVolts(siteIndx);
                end

            end

            %% make up samples for laser and masking light channels
            anlgOut = ones(1,obj.numSamplesPerChannel) * obj.parent.laser_mW_to_control(obj.laserPowerInMW); %Write the correct control voltage
            digitalAmplitude = 4;
            digOut = ones(1,obj.numSamplesPerChannel) * digitalAmplitude;

            % allow 1 ms around halfcycle change to be 0 (in case scanners are not in the right spot
            % TODO -- this should be based on empirical values
            MASK = ones(1,obj.numSamplesPerChannel);
            sampleInterval = 1/obj.parent.DAQ.samplesPerSecond;
            nSamplesInOneMS = 1E-3 / sampleInterval;

            for ii=1:nSamplesInOneMS
                MASK(edgeSamples(1:end-1)+(ii-1))=0;
            end

            anlgOut = anlgOut.*MASK;
            digOut = digOut.*MASK;

            % Can probabky make
            lghtChnl(:,1) = anlgOut;              % analog laser output
            lghtChnl(:,2) = digOut*(5/digitalAmplitude);    % analog masking light output
            lghtChnl(:,3) = digOut;               % digital laser gate


            %% save all samples in a structure to access as object property
            chanSamples.scan = scanChnl;
            % x-by-2-by-6, where rows are samples, columns are channels, and 3rd dim
            % is which area is selected

            chanSamples.light = lghtChnl;
            % x-by-3-by-2, where rows are samples, columns are channels, and 3rd dim
            % is whether laser is off or on


        end % get.chanSamples

    end % methods


end % config
