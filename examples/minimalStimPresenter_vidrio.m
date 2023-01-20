classdef minimalStimPresenter_vidrio < handle

    % Minimal code example showing how to present pre-calculated stimulus waveforms for optostim
    %
    % minimalStimPresenter_vidrio
    %
    %
    % * Purpose
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
    %
    % * Communicating with the NI DAQ
    % NI hardware uses an API known as NI DAQmx. This is not available directly in MATLAB so 
    % Zapit uses a wrapper built by Vidrio Technologies to run ScanImage in order to talk to 
    % DAQmx. There are other ways to communicate with DAQmx, this one was chosen for historical
    % reasons. This class uses this same wrapper.
    %
    %
    % * Before Starting
    % Before using this function you should use the zapit.stimConfig.writeWaveformsToDisk method
    % to write some data to disk. The quickest way to do this:
    % a) Start Zapit with start_zapit
    % b) Load a stim config file with File > Load stim config. You can load the example file at:
    %    examples/example_stimulus_config_files/uniAndBilateral_5_conditions.yml
    % c) Run the sample calibration step. If there is no sample, place the brain outline anywhere.
    % d) You can write the waveforms to a directory with:
    %    hZP.stimConfig.writeWaveformsToDisk(DIR_PATH_AS_STRING)
    % e) Close Zapit so it does not hog the DAQ.
    % f) Fire up an instance of this class: msp = minimalStimPresenter_vidrio('zapit_waveforms.mat');
    % You might find it easier to do the above steps with the examples directory added temporarily
    % to the MATLAB path.
    %
    % * Example usage
    % msp = minimalStimPresenter_vidrio('/path/to/zapit_waveforms.mat', 'Dev2');
    % msp.sendSamples(2) % waveforms start right away and continue until next command
    % msp.stopOptoStim
    % 
    %
    % Rob Campbell - SWC 2023
    %
    %
    % * Further Reading
    % https://github.com/tenss/MATLAB_DAQmx_examples -- lots of DAQmx examples in MATLAB
    % https://github.com/danionella/lsmaq/ -- simple MATLAB laser scanning with .NET & DAQmx


    properties
        waveforms % Cell array of waveforms loaded from the zapit_waveforms.mat file
        hAO % NI DAQ object

        rampDownInMS = 250  % Generally this is a good number. If the user has specified 
                            % something else it will be in the stimConfig file. 

        samplesPerSecond = 1E6 % This must match  the number used to build the waveforms                                % performance.

        device_ID = 'Dev1' % Must be set to the name of your device. This can be done
                          % optionally at instantiation (see constructor)

        hardwareTriggered = false % By default we don't want to wait for a hardware
                                  % trigger before we start for this example. In reality
                                  % this may well need to be on by default. See connectClockedAO

        lastBufferedWaveform  % Used to help perform the rampdown
    end % properties



    methods

        function obj = minimalStimPresenter_vidrio(fname,devID)
            % constructor
            %
            % Inputs
            % fname - relative or absolute path to the zapit waveforms file
            % devID - if you DAQ device is not called Dev1, you can supply the name here.
            %         alternatively, set the device_ID property manually before sending samples.
            %
            % Examples
            % msp = minimalStimPresenter_vidrio('./zapit_waveforms.mat','Dev3')

            if nargin>1
                obj.device_ID = devID;
            end

            % Loads two variables: a cell array called "waveforms" and a scalar
            % called "samplesPerSecond". We convert to doubles because they need to
            % be double for DAQmx but we saved as single to produce a smaller file.
            load(fname)
            obj.waveforms = waveforms;
            obj.waveforms = cellfun(@(x) double(x), obj.waveforms,'uni',false);
            obj.samplesPerSecond = samplesPerSecond/10;

            obj.connectClockedAO
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
                obj.waveforms(:,3) = 0;
            end
            
            % Write voltage samples onto the task
            waveforms = obj.waveforms{indexToPresent};
            obj.lastBufferedWaveform = waveforms;
            obj.hAO.writeAnalogData(waveforms);
            
            obj.hAO.start; % start the execution of the new task

        end % sendSamples


        function stopOptoStim(obj)
            % Stop waveform presentation with a ramp-down
            %
            % This method corresponds to zapit.pointer.stopOptoStim

            bufferSize = obj.hAO.sampQuantSampPerChan;

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
                t = obj.lastBufferedWaveform;
                t(:,3) = t(:,3) * amp; % The third column is the laser amplitude
                obj.hAO.writeAnalogData(t); % Write these to the device buffer
            end

            % Zero everything (scanners and laser and masking light)
            t(:) = 0;
            obj.hAO.writeAnalogData(t);
            obj.hAO.stop  % stop task
        end % stopOptoStim


        function connectClockedAO(obj)
            % Start a clocked task. 
            %
            % This is the equivalent of zapit.DAQ.vidriowrapper.connectClockedAO
            %
            % Purpose
            % Create a task that is clocked AO and can be used for sample setup.


            numSamplesPerChannel=size(obj.waveforms{1},1);

            % Delete the task if it already exists
            if ~isempty(obj.hAO)
                obj.hAO.stop;
                delete(obj.hAO);
            end

            %% Create the inactivation task
            obj.hAO = zapit.hardware.vidrio_daqmx.Task('clockedAO');
            
            % Set output channels
            obj.hAO.createAOVoltageChan(obj.device_ID, 0:3, [], -10, 10);
            
            % Configure the task sample clock, the sample size and mode to be continuous and set the size of the output buffer
            obj.hAO.cfgSampClkTiming(obj.samplesPerSecond, 'DAQmx_Val_ContSamps', numSamplesPerChannel, 'OnboardClock');
            obj.hAO.cfgOutputBuffer(numSamplesPerChannel);
            
            % Allow sample regeneration
            % https://www.ni.com/en-gb/support/documentation/supplemental/06/analog-output-regeneration-in-ni-daqmx.html
            obj.hAO.set('writeRegenMode', 'DAQmx_Val_AllowRegen'); 
            obj.hAO.set('writeRelativeTo','DAQmx_Val_FirstSample');
            
            % Configure the trigger
            if obj.hardwareTriggered
                % Wait for line PFI0 to go high before playing waveforms
                obj.hAO.cfgDigEdgeStartTrig('PFI0', 'DAQmx_Val_Rising');
            end
        end % connectClockedAO


    end % methods

end % classdef