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


        % TODO here for now (March 2023)
        tcpServer
    end % properties


    properties (SetObservable=true)
        experimentPath = '' % The absolute path to an experiment folder. This is used to automatically write log data
                            % when zapit.pointer.sendSamples is called.
        settings % The settings read in from the YAML file

        % State of the software - TODO -- doc
        state = 'idle'; % idle, rampdown, stim (queued or actually stimulating)

    end % observable properties


    properties (Hidden)
        lastXgalvoVoltage  = 0 % Cached value indicating last X scanner voltage
        lastYgalvoVoltage  = 0 % Cached value indicating last Y scanner voltage
        lastPresentedCondition = 0  % The index of the last condition presented by sendSamples
                                    % This is used to avoid choosing the same condition twice in a row.
        lastLaserValue = 0 % Cached value indicating what the laser was last set to
        buildFailed = true % Used during boostrap by start_zapit
        breakPointingAccuracyLoop = false; % Used so GUI can break out of a loop (like that in scanner calib) where the beam accuracy is measured
        simulated = false % Tag to indicate whether it is in simulated mode
        listeners  % Structure that holds listeners so they can be easily cleaned up in the destructor
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
                             % (first line [ML,AP] and the second is defined by the settings
                             % value at settings.calibrateSample.refAP
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
            params.addParameter('settingsFile', [], @(x) isempty(x) || ischar(x))
            params.parse(varargin{:});

            obj.simulated = params.Results.simulated;

            % By default we load the settings file in the normal location but for testing
            % is possible to define a different one
            if isempty(params.Results.settingsFile)
                obj.settings = zapit.settings.readSettings;
            else
                obj.settings = zapit.settings.readSettings(params.Results.settingsFile);
            end

            % Connect to camera
            if obj.simulated
                obj.cam = zapit.simulated.camera;
            else
                obj.cam = zapit.hardware.camera(obj.settings.camera.connectionIndex);
            end
            obj.cam.exposure = obj.settings.camera.default_exposure;

            % Re-apply the last used ROI
            if ~isempty(obj.settings.cache.ROI)
                obj.cam.ROI = round(obj.settings.cache.ROI);
            end

            % Log camera frames to lastAcquiredFrame and start camera
            if ~obj.simulated
                %% RAAC -- 14th May 2023 09:50 COMMENT OUT -- TODO
                %obj.cam.vid.FramesAcquiredFcn = @obj.storeLastFrame;
                %obj.cam.vid.FramesAcquiredFcnCount=1; %Run frame acq fun every N frames
            else
               obj.listeners.lastAcquiredFrame = addlistener(obj.cam, 'lastAcquiredFrame', 'PostSet', @obj.storeLastFrame);
               % Make a listener instead of the FramesAcquiredFcn
               % TODO: this seems to cause Zapit to hang on many systems and we don't care about the
               % simulated camera anyway, since it doesn't do anything useful right now. So comment
               % out until/unless it is actually needed.
               %obj.cam.startVideo; pause(0.2), obj.cam.stopVideo; pause(0.2) % TODO -- for some reason we need to call this twice for it to start working properly
            end

            % Only start video by default if we are not in simulated mode
            if ~obj.simulated
                obj.cam.startVideo;
            end


            % Set up TCP server if requested
            if obj.settings.tcpServer.enable
                obj.tcpServer = zapit.interfaces.TCPserver(...
                    'ip', obj.settings.tcpServer.IP, ...
                    'port', obj.settings.tcpServer.port);
                obj.tcpServer.parent = obj;
            end


            % Save settings if they are changed
            obj.listeners.saveSettings = addlistener(obj, 'settings', 'PostSet', @obj.saveSettingsFile);

            if obj.simulated
                obj.DAQ = zapit.simulated.DAQ;
                obj.DAQ.samplesPerSecond = obj.settings.NI.samplesPerSecond;
                obj.scannersCalibrated = true;
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

            fprintf('Shutting down Zapit optostim software\n')
            structfun(@delete,obj.listeners)
            if isvalid(obj.cam)
                obj.cam.vid.FramesAcquiredFcn = [];
                obj.cam.stopVideo;
            end
            delete(obj.cam)
            delete(obj.DAQ)
            delete(obj.tcpServer)
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


        function applyUnityStereotaxicCalib(obj)
            % Apply a 1:1 calibration between camera and stereotaxic coordinates
            %
            % function zapit.pointer.applyUnityStereotaxicCalib
            %
            % Purpose
            % Apply a dummy stereotaxic coordinate calibration for debugging and dev.

            obj.sampleCalibrated = true;
            obj.refPointsSample = obj.refPointsStereotaxic;
        end % applyUnityStereotaxicCalib


        function wipeStereotaxicCalib(obj)
            % Wipe the current stereotaxic calibration
            %
            % function zapit.pointer.wipeStereotaxicCalib
            %
            % Purpose
            % Used to remove the current stereotaxic coordinate calibration. Likely this
            % method will only be used for debugging and dev purposes.

            obj.sampleCalibrated = false;
            obj.refPointsSample = [];
        end % wipeStereotaxicCalib


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
            obj.DAQ.writeAnalogData([obj.lastXgalvoVoltage, obj.lastYgalvoVoltage, laserControlVoltage, 0])
            obj.lastLaserValue = laserControlVoltage;
        end % setLaserPowerControlVoltage


        function moveBeamXYinVolts(obj,beamXY)
            % Set the two scanner AO lines to specified voltage value
            %
            % function zapit.pointer.moveBeamXYinVolts(xyVolts)
            %
            % Purpose
            % Set the two galvo control AO lines with an unlocked AO operation. The beam
            % moves right away and as fast as possible.
            %
            % Inputs
            % beamXY - [x_voltage_value, y_voltage_value]

            obj.DAQ.connectUnclockedAO % will not re-connect if currently connected

            beamXY = beamXY(:)'; % Ensure column vector
            obj.DAQ.writeAnalogData([beamXY,obj.lastLaserValue,0])

            % update cached values
            obj.lastXgalvoVoltage = beamXY(1);
            obj.lastYgalvoVoltage = beamXY(2);
        end % moveBeamXYinVolts


        function moveBeamXYinMM(obj,beamXY)
            % Set the scanners to point the beam to a specified coordinate in mm
            %
            % function zapit.pointer.moveBeamXYinMM(xyVolts)
            %
            % Purpose
            % Point the beam to a locatation in mm
            %
            % Inputs
            % beamXY - [x_pos_in_mm, y_pos_in_mm]

            [xVoltage, yVoltage] = obj.mmToVolt(beamXY(1),beamXY(2));

            obj.moveBeamXYinVolts([xVoltage, yVoltage])

        end % moveBeamXYinVolts


        function zeroScanners(obj)
            % Zero the beam
            %
            % zapit.pointer.zeroScanners
            %
            % Purpose
            % Sets beam to 0V/0V (center of image).

            obj.moveBeamXYinVolts([0,0]);
        end % zeroScanners

    end % methods

end % classdef
