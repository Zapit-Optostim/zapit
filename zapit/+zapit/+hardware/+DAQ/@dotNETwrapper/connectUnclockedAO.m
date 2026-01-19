function connectUnclockedAO(obj, verbose)
    % connectUnclockedAO(obj)
    %
    % function zapit.DAQ.dotNETwrapper.connectUnclockedAO
    %
    % Create a task that is unclocked AO and can be used for sample setup.
    % The connection options are set by properties in the dotNETwrapper
    % class. see: .device_ID, .AOchans, .AOrange,
    %
    % Inputs
    % verbose - [optional, false by default]. Reports to screen what it is doing if true

    import NationalInstruments.DAQmx.*

    if nargin<2
        verbose = false;
    end

    % If we are already connected we don't proceed
    if ~isempty(obj.hAO) && isvalid(obj.hAO) && obj.hAO.AOChannels.Count>0 && ...
            startsWith(char(obj.hAO.AOChannels.All.VirtualName), 'unclockedao') %TODO: not the task name!
        return
    end

    obj.stopAndDeleteAOTask

    if verbose
        fprintf('Creating unclocked AO task on %s\n', obj.device_ID)
    end

    taskName = 'unclockedao';
    obj.hAO = NationalInstruments.DAQmx.Task(taskName);
    channelName = obj.genChanString(obj.AOchans);

    obj.hAO.AOChannels.CreateVoltageChannel(channelName, taskName, ...
                    -obj.AOrange, obj.AOrange, AOVoltageUnits.Volts);

    obj.hAO.Control(TaskAction.Verify);

    obj.hAOtaskWriter = AnalogMultiChannelWriter(obj.hAO.Stream);

    obj.hAO.Start;
end % connectUnclockedAO