classdef pointer < handle
    % Main API class for the Zapit optostim system
    %
    % zapit.pointer
    %
    % Purpose
    % Drives a galvo-based photo-stimulator. The scan-lens doubles as an objective to 
    % scan the beam over the sample and also to form an image via a camera.
    %
    %
    % Maja Skretowska - SWC 2020-2022
    % Rob Campbell - SWC 2023


    
    properties

        %%
        % The following are associated with hardware components
        cam % camera
        DAQ % instance of class that controls the DAQ (laser and scanners)

        %%
        % The following properties relate to settings or other similar state parameters
        % Properties related to where we stimulate
        stimConfig % Object of class zapit.stimConfig. This contains the locations to stimulate
        laserFit  % laserfits. See generateLaserCalibrationCurve
        transform % The transform describing the relationship between scanners and camera


        %%
        % The following relate to calibration of the sample. These are not in the stim config
        % as they are independent of it. i.e. a new config can be loaded and the the data in the
        % following properties does not alter
        calibratedBrainOutline % The outline of the brain calibrated to the sample
        refPointsSample  % The two reference points in sample space. User provides these via calibrateSample
        % -> see also refPointsStereotaxic, below under the getters section
    end % properties


    properties (SetObservable=true)
        experimentPath = '' % The absolute path to an experiment folder. This is used to automatically write log data
                            % when zapit.pointer.sendSamples is called.
        settings % The settings read in from the YAML file
    end % observable properties


    properties (Hidden)
        lastXgalvoVoltage  = 0 % Cached value indicating last X scanner voltage 
        lastYgalvoVoltage  = 0 % Cached value indicating last Y scanner voltage 
        lastLaserValue = 0 % Cached value indicating what the laser was last set to
        buildFailed = true % Used during boostrap by start_zapit
        breakScannerCalibLoop = false; % Used so GUI can break out of the scanner calibration loop.
        simulated = false % Tag to indicate whether it is in simulated mode
        listeners = {} % Cell array that holds listeners so they can be easily cleaned up in the destructor
    end % hidden properties


    properties (Hidden,SetObservable=true)
        lastAcquiredFrame % The last frame acquired by the camera
        calibrateScannersPosData % Used to plot data during scanner calibration
        scannersCalibrated = false % Gets set to true if the scanners are calibrated
        sampleCalibrated = false % Gets set to true if the sample is calibrated
    end % hidden observable properties


    % read-only properties that are associated with getters
    properties (SetAccess=protected, GetAccess=public)
       imSize
       refPointsStereotaxic  % Two reference points in stereotaxic space. By default bregma
                             % (first line [ML,AP] and a point 3 mm in front (second line)
    end % getter properties


    % Constructor and destructor
    methods
        function obj = pointer(varargin)
            % Constructor
            %
            % zapit.pointer.pointer
            %
            % Inputs (param/value pairs)
            % 'simulated' - [false by default] If true does not connect to hardware but 
            %   runs in simulated mode.

            params = inputParser;
            params.CaseSensitive = false;
            params.addParameter('simulated', false, @(x) islogical(x) || x==0 || x==1);

            params.parse(varargin{:});

            obj.simulated=params.Results.simulated;

            obj.settings = zapit.settings.readSettings;

            % Connect to camera
            if obj.simulated
                obj.cam = zapit.simulated.camera;
            else
                obj.cam = zapit.hardware.camera(obj.settings.camera.connection_index);
            end
            obj.cam.exposure = obj.settings.camera.default_exposure;

            % Re-apply the last used ROI
            if ~isempty(obj.settings.cache.ROI)
                obj.cam.ROI = round(obj.settings.cache.ROI);
            end

            % Log camera frames to lastAcquiredFrame and start camera
            if ~obj.simulated
                obj.cam.vid.FramesAcquiredFcn = @obj.storeLastFrame;
                obj.cam.vid.FramesAcquiredFcnCount=1; %Run frame acq fun every N frames
            else
               obj.listeners{end+1} = addlistener(obj.cam, 'lastAcquiredFrame', 'PostSet', @obj.storeLastFrame);
               % Make a listener instead of the FramesAcquiredFcn
               obj.cam.startVideo; pause(0.2), obj.cam.stopVideo; pause(0.2) % TODO -- for some reason we need to call this twice for it to start working properly
            end
            obj.cam.startVideo; 


            % Save settings if they are changed
            obj.listeners{end+1} = addlistener(obj, 'settings', 'PostSet', @obj.saveSettingsFile);

            if obj.simulated
                obj.DAQ = zapit.simulated.DAQ;
            else
                fprintf('Connecting to DAQ\n')
                switch lower(obj.settings.NI.wrapper)
                case 'vidrio'
                    obj.DAQ = zapit.hardware.DAQ.vidriowrapper;
                case 'dotnet'
                    obj.DAQ = zapit.hardware.DAQ.dotNETwrapper;
                end
            end

            obj.DAQ.parent = obj;
            obj.zeroScanners
            obj.loadLaserFit
            obj.buildFailed = false; % signal to start_zapit that all went well

        end % Constructor
        
        
        function delete(obj,~,~)
            % Stop the camera and disconnect from hardware
            %
            % zapit.pointer.delete
            %
            
            fprintf('Shutting down optostim software\n')
            cellfun(@delete,obj.listeners)
            if isvalid(obj.cam)
                obj.cam.vid.FramesAcquiredFcn = [];
                obj.cam.stopVideo;
            end
            delete(obj.cam)
            delete(obj.DAQ)

        end % Destructor
        
    end % end of constructor/destructor block


    % Getters and setters
    methods
        function imSize = get.imSize(obj)
            % Return size of image being acquired by camera
            %
            % imSize = zapit.pointer.imSize(obj)
            %
            % Purpose
            % Return size of image being acquired by camera. This could change after
            % the camera has been started so it must be handled dynamically.

            imSize = obj.cam.ROI;
            imSize = imSize(3:4);
        end % get.imsize

        function refPointsStereotaxic = get.refPointsStereotaxic(obj)
            % Return the stereoatxic reference points
            %
            % refPointsStereotaxic = get.refPointsStereotaxic(obj)
            %
            % Purpose
            % Return the stereotaxic reference coords by pulling the AP
            % position from the settings

            refPointsStereotaxic = zeros(2,2);
            refPointsStereotaxic(2,2) = obj.settings.calibrateSample.refAP;
        end % refPointsStereotaxic

    end % getters and setters


    % Other short methods
    methods


        function wipeScannerCalib(obj)
            % Wipe the current scanner calibration
            %
            % function zapit.pointer.wipeScannerCalib
            %
            % Purpose
            % Used when a new calibration is initiated or if there is a reason to
            % wipe the existing transform. e.g. the user changes camera ROI.

            obj.transform = [];
            obj.scannersCalibrated = false;
        end % wipeScannerCalib


        function actualCoords = returnScannerCalibTargetCoords(obj)
            % Return target coords of the beam during calibration
            %
            % function zapit.pointer.returnScannerCalibTargetCoords
            %
            % Purpose
            % Return the coordinates the beam is supposed to have gone to during
            % calibration. These are the coordinates for which we also got a location
            % for where the beam actually went. Some locations may be missing if the
            % software could not determine the location of the beam there. 

            if isempty(obj.calibrateScannersPosData)
                actualCoords = [];
                return
            end

            actualCoords = cat(1,obj.calibrateScannersPosData(:).actualCoords);
        end


        function saveSettingsFile(obj,~,~)
            % This callback is run every time the settings are altered to save them to disk
            %
            %  function zapit.pointer.saveSettingsFile(obj,~,~)
            %
            % Purpose
            % Saves the settings to the YAML when they are changed
    
            settingsFile = zapit.settings.findSettingsFile;
            zapit.yaml.WriteYaml(settingsFile,obj.settings);
        end % saveSettingsFile


        function clearExperimentPath(obj)
            % Set experimet path to an empty string
            %
            % function zapit.pointer.clearExperimentPath(obj)
            %
            % Purpose
            % Set the experiment path to be an empty string so we do not log
            % stimulus information when calling zapit.pointer.sendSamples

            obj.experimentPath = '';
        end % clearExperimentPath


        function setLaserPowerControlVoltage(obj,laserControlVoltage)
            % Set the laser AO line to a specified voltage value
            %
            % function zapit.pointer.setLaserPowerControlVoltage
            %
            % Purpose
            % Set the laser voltage with an unlocked AO operation.

            obj.DAQ.connectUnclockedAO % will not re-connect if currently connected
            obj.DAQ.writeAnalogData([obj.lastXgalvoVoltage, obj.lastYgalvoVoltage, laserControlVoltage])
            obj.lastLaserValue = laserControlVoltage;
        end % setLaserPowerControlVoltage


        function moveBeamXY(obj,beamXY)
            % Set the two scanner AO lines to specified voltage value
            %
            % function zapit.pointer.moveBeamXY
            %
            % Purpose
            % Set the two galvo control AO lines with an unlocked AO operation.
            % This property was moved from the DAQ class to here because there 
            % are now two DAQ classes and leaving it there led to repetition. 

            obj.DAQ.connectUnclockedAO % will not re-connect if currently connected

            beamXY = beamXY(:)'; % Ensure column vector
            obj.DAQ.writeAnalogData([beamXY,obj.lastLaserValue])

            % update cached values
            obj.lastXgalvoVoltage = beamXY(1);
            obj.lastYgalvoVoltage = beamXY(2);
        end % moveBeamXY


        function zeroScanners(obj)
            % Zero the beam
            % 
            % zapit.pointer.zeroScanners
            %
            % Purpose
            % Sets beam to 0V/0V (center of image).

            obj.moveBeamXY([0,0]);
        end % zeroScanners

    end % methods

end % classdef
