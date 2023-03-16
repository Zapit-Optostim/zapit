function waveformRecorder(devID,fname)
    % A simple example showing how to acqurire waveforms with hardware-timed continuous analog input using using DAQmx via .NET
    %
    % function waveformRecorder(devID)
    %
    %
    % Inputs
    %   devID - [optional] 'Dev1' by default
    %
    % Rob Campbell - SWC, 2023

    % Add the DAQmx assembly if needed then import
    nidaqmx.add_DAQmx_Assembly
    import NationalInstruments.DAQmx.*

    if nargin<1
        devID = 'Dev1';
    end

    if nargin<2
        fname = 'test.bin';
    end

    if ~nidaqmx.deviceExists(devID)
        fprintf('%s does not exist\n', devID)
        return
    end

    % Parameters for the acquisition (device and channels)
    minVoltage = -5;       % Channel input range minimum
    maxVoltage = 5;        % Channel input range maximum


    % Task configuration
    sampleRate =1E5;                  % Sample Rate in Hz
    numSamplesToPlot = 2E5 ;            % Read off this many samples each time to plot
    bufferSize_numSamplesPerChannel = 10*numSamplesToPlot; % The number of samples to be stored in the buffer per channel.


    % * Create a DAQmx task
    %   C equivalent - DAQmxCreateTask
    %   http://zone.ni.com/reference/en-XX/help/370471AE-01/daqmxcfunc/daqmxcreatetask/
    task = NationalInstruments.DAQmx.Task();


    % * Set up analog inputs on device defined by variable devID
    %   More details at: "help dabs.ni.daqmx.Task.createAIVoltageChan"
    %   C equivalent - DAQmxCreateAIVoltageChan
    %   http://zone.ni.com/reference/en-XX/help/370471AE-01/daqmxcfunc/daqmxcreateaivoltagechan/
    channelName = [devID,'/AI0:2'];
    nChans = 3;
    task.AIChannels.CreateVoltageChannel(channelName, '',  AITerminalConfiguration.Differential, ...
                                        minVoltage, maxVoltage, AIVoltageUnits.Volts);


    % * Configure the sampling rate and the number of samples
    %   More details at: "help dabs.ni.daqmx.Task.cfgSampClkTiming"
    %   C equivalent - DAQmxCfgSampClkTiming
    %   http://zone.ni.com/reference/en-XX/help/370471AE-01/daqmxcfunc/daqmxcfgsampclktiming/
    %   SampleQuantityMode is an enum
    task.Timing.ConfigureSampleClock('', ...
            sampleRate, ...
            SampleClockActiveEdge.Rising, ...
            SampleQuantityMode.ContinuousSamples, ... % And we set this to continuous
            bufferSize_numSamplesPerChannel)



    AIreader = AnalogUnscaledReader(task.Stream);
    task.EveryNSamplesReadEventInterval = numSamplesToPlot;
    task.Control(TaskAction.Verify);

    AIlistener = addlistener(task, 'EveryNSamplesRead', @readAndPlotData);

    % Open a figure window and have it shut off the acquisition when closed
    % See: basicConcepts/windowCloseFunction.m
    fig=clf;
    set(fig,'CloseRequestFcn', @windowCloseFcn, ...
        'Name', 'Close figure window to stop acquisition')
    hold on

    for ii=1:nChans
        P{ii} = plot(zeros(1,numSamplesToPlot));
    end

    %hold off
    % Start the task and wait until it is complete. Task starts right away since we
    % configured no triggers

    fid = fopen(fname,'w+');
    task.Start
    fprintf('Recording data on %s. Close window to stop.\n', devID);
  
    pause(5)
    disp('STOPPING')
    task.Stop()
    


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    function windowCloseFcn(~,~)
        %This runs when the user closes the figure window or if there is an error
        fclose(fid);
        if exist('task','var')
            fprintf('Cleaning up DAQ task\n');
            task.Stop;    % Calls DAQmxStopTask
            task.Dispose
            delete(task); % The destructor (dabs.ni.daqmx.Task.delete) calls DAQmxClearTask
        else
            fprintf('No task variable present for clean up\n')
        end

        if exist('fig','var') %In case this is called in the catch block
            delete(fig)            
        end
    end %close windowCloseFcn



    function readAndPlotData(src,evt)
        % This callback function runs each time a pre-defined number of points have been collected
        % This is defined at the hTask.registerEveryNSamplesEvent method call.
        
        try 
            data = AIreader.ReadInt16(numSamplesToPlot).int16;
        catch ME
            fprintf('\n\n*** ERROR IN CALLBACK ***\n')
            disp(ME.message)
            task.Stop
            return
        end
        fwrite(fid,data,'integer*2');
        if isempty(data)
            fprintf('Input buffer is empty\n' );
        else
            for ii=1:nChans
                P{ii}.YData(1,:) = data(ii,:);
            end

            drawnow
        end

    end %readAndPlotData

end %close hardwareContinuousVoltage


