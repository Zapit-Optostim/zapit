function connectUnclockedAI(obj, chan, verbose)
    % connectUnclockedAO(obj)
    %
    % Create a task that is unclocked AI and can be used for misc tasks.
    %
    % function zapit.DAQ.dotNETwrapper.connectUnclockedAI
    %
    % Inputs
    % chan - which channel to connect. Must be supplied as an integer.
    % verbose - [optional, false by default]. Reports to screen what it is doing if true

    import NationalInstruments.DAQmx.*

    if nargin<3
        verbose = false;
    end

    obj.stopAndDeleteAITask


    if verbose
        fprintf('Creating unclocked AI task on %s\n', obj.device_ID)
    end

    taskName = 'unclockedai';
    obj.hAI = NationalInstruments.DAQmx.Task(taskName);
    chan = [obj.device_ID,'/ai',num2str(chan)];

    obj.hAI.AIChannels.CreateVoltageChannel(chan, taskName, ...
                    AITerminalConfiguration.Differential, ...
                    -obj.AOrange, obj.AOrange, AIVoltageUnits.Volts);

    obj.hAI.Control(TaskAction.Verify)

    obj.hAIreader = AnalogSingleChannelReader(obj.hAI.Stream);

end % connectUnclockedAI