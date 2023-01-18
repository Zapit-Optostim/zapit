classdef minimalStimPresenter < handle

    % Minimal code example showing how to present stimulus waveforms in the same way as zapit
    %
    % minimalStimPresenter
    %
    % Purpose
    % This class serves as an example to demonstrate how Zapit conducts the actual photostimulation
    % using the NI DAQ. The purpose of the Zapit GUI is to calibrate the scanners and the sample to 
    % the camera space. Thereafter it is possible to position the beam to any desired coordinate 
    % defined in stereotaxic space. Photostimulation during the experiment sees the beam doing one 
    % of two things:
    % 1) Moving between two points at a given frequencies (typically 40 Hz).
    % 2) Remaining stationary but switching on and off at the above frequency.
    %
    % The above two situations are both achieved by playing a matrix of pre-calculated waveforms 
    % out of an NI DAQ at a particular sample rate using a clocked data acquisition Task. The NI 
    % DAQ is a real-time device that plays the waveforms continuously and independently of the 
    % PC. The waveforms play until a command is issued to stop them. This command does not end 
    % the waveforms abruptly but instead ramps down the laser power over a short period of time
    % (typically 250 ms). This is to avoid a large rebound excitation. 
    %
    % This class implements the following:
    % 1. Loading of pre-computed waveforms from disk.
    % 2. Setting up the DAQ with the correct parameters.
    % 3. Initiating presentation of a stimulus.
    % 4. Stopping the stimulus using the above described ramp.
    % 
    % The code is written in a minimal style for clarity. Where appropriate comments will cite
    % equivalent code in the main Zapit package that might implement the same functionality in a
    % more complete way. Links to other resources are also included as needed.
    %
    % * Communicating with the NI DAQ
    % NI hardware uses an API known as NI DAQmx. This is not available directly in MATLAB so 
    % Zapit uses a wrapper built by Vidrio Technologies to run ScanImage in order to talk to 
    % DAQmx. There are other ways to communicate with DAQmx, this one was chosen for historical
    % reasons. This class uses a more direct approach: importing NI's .NET interface for DAQmx 
    % into MATLAB. This approach is slightly lower level and so seems more appropriate given the
    % purpose of this class. The code looks very similar with both approaches. * To run this class
    % You will need to install NI DAQmx (see the main README) with .NET support enabled. 
    %
    %
    % * Before Starting
    % Before using this function you should use the zapit.stimConfig.writeWaveformsToDisk method
    % to write some data to disk. The quickest way to do this:
    % a) Start Zapit with start_zapit
    % b) Load a stim config file with File > Load stim config. You can load the example file at:
    %    examples/example_stimulus_config_files/uniAndBilateral_5_conditions.yml
    % c) You can write the waveforms to the current directory with:
    %    hZP.stimConfig.writeWaveformsToDisk
    % d) Fire up an instance of this class: msp = minimalStimPresenter('zapit_waveforms.mat');
    % 
    %
    % Example usage
    % msp = minimalStimPresenter('/path/to/zapit_waveforms.mat', 'Dev2');
    % msp.sendSamples(2) % waveforms start right away and continue until next command
    % msp.stopOptoStim
    % 
    %
    % Rob Campbell - SWC 2023


    properties
        waveforms % Cell array of waveforms loaded from the zapit_waveforms.mat file
        hAO % NI DAQ object

        rampDownInMS = 250  % Generally this is a good number. If the user has specified 
                            % something else it will be in the stimConfig file. 
        samplesPerSecond = 1E5  % This is defined in the Zapit settings file. It is an 
                                % important parameter. Incorrect values can lead to poor
                                % performance.

        obj.device_ID = 'Dev1' % Must be set to the name of your device. This can be done
        %                      % optionally at instantiation (see constructor)
    end % properties

    methods

        function obj = minimalStimPresenter(fname,devID)
            % constructor
            %
            % Inputs
            % fname - relative or absolute path to the zapit waveforms file
            % devID - if you DAQ device is not called Dev1, you can supply the name here.
            %         alternatively, set the device_ID property manually before sending samples.

            load(fname)
            obj.waveforms = waveforms;

            if nargin>1
                obj.device_ID = devID;
            end

        end % constructor


        function delete(obj)
            % Destructor 
            delete(obj.hAO)
        end % destructor


        function sendSamples(obj, indexToPresent, laserOn)
            % Send samples to the DAQ
            % 
            % This method corresponds to zapit.pointer.sendSamples

            if nargin<3
                laserOn = true;
            end

            % Disable laser if requested
            if laserOn == false
                waveforms(:,3) = 0;
            end

            obj.connectClockedAO('numSamplesPerChannel',size(waveforms,1), ...
                                    'hardwareTriggered', hardwareTriggered);
            
            % Write voltage samples onto the task
            obj.hAO.writeAnalogData(obj.waveforms{indexToPresent});
            
            obj.hAO.start; % start the execution of the new task

        end % sendSamples


        function stopOptoStim(obj)
            % Stop waveform presentation with a ramp-down
            %
            % This method corresponds to zapit.pointer.stopOptoStim


            bufferSize = obj.sampQuantSampPerChan;

            if isempty(bufferSize) || obj.hAO.isTaskDone
                return
            end

            msPerBuffer = (bufferSize/obj.samplesPerSecond) * 1E3;

            % Handle case where the user asks for a ramp-down that is smaller than the
            % buffer size.
            if obj.rampDownInMS < msPerBuffer
                obj.rampDownInMS = msPerBuffer;
            end

            % The number of buffers we need to play out to achieve the desired 
            % ramp-down time
            numBuffers = ceil(obj.rampDownInMS / msPerBuffer);

            % Each buffer will have the laser waveforms reduced by the amount defined by ampSequence
            ampSequence = linspace(1,0,numBuffers+2);
            ampSequence(1) = [];
            ampSequence(end) = [];

            % Loop over amp sequence and fill the buffer with waveforms of the same shape as the original
            % but of smaller amplitude:

            for amp = ampSequence
                t = obj.hAO.lastWaveform;
                t(:,3) = t(:,3) * amp; % The third column is the laser amplitude
                obj.hAO.writeAnalogData(t); % Write these to the device buffer
            end

            % Zero everything (scanners and laser and masking light)
            t(:) = 0;
            obj.hAO.writeAnalogData(t);
            obj.hAO.stop  % stop task
        end % stopOptoStim


        function connectClockedAO(obj, varargin)
            % Start a clocked task. 
            %
            % This is the equivalent of zapit.DAQ.vidriowrapper.connectClockedAO
            %
            % Purpose
            % Create a task that is clocked AO and can be used for sample setup.


            numSamplesPerChannel=length(obj.waveforms{1});

            hardwareTriggered = false; % set to true if you want to wait for a hardware trigger

            % Just in case a task already exists (TODO: do we need this for this example>)
            obj.hAO.stop; 
            delete(obj.hAO);

            %% Create the inactivation task
            taskName = 'minimalao';
            obj.hAO = zapit.hardware.vidrio_daqmx.Task(taskName);
            
            % Set output channels
            obj.hAO.createAOVoltageChan(obj.device_ID, 0:3, [], -10, 10);
            
            
            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hAO.cfgSampClkTiming(samplesPerSecond, 'DAQmx_Val_ContSamps', numSamplesPerChannel, 'OnboardClock');
            obj.hAO.cfgOutputBuffer(numSamplesPerChannel);
            
            % allow sample regeneration
            obj.hAO.set('writeRegenMode', 'DAQmx_Val_AllowRegen'); 
            obj.hAO.set('writeRelativeTo','DAQmx_Val_FirstSample');
            
            % Configure the trigger
            if hardwareTriggered
                obj.hAO.cfgDigEdgeStartTrig('PFI0', 'DAQmx_Val_Rising'); % Look for trigger on port PFI0
            end
        end % connectClockedAO


    end % methods

end % classdef 