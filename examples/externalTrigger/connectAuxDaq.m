function out = connectAuxDaq(devID)
    % Connect to digotal line and return task and digital writer class
    %
    % out = connectAuxDaq(devID)
    %
    % Purpose
    % Connect to DAQ for DO so a separate function can rapidly switch the DAQ
    %
    % Inputs
    % devID - [optional] by default 'Dev2'
    %
    % Outputs
    % out - contains the task and digital writer class as fields.
    %
    % Rob Campbell - SWC 2023


    % Standard imports
    NET.addAssembly('NationalInstruments.DAQmx');
    import NationalInstruments.DAQmx.*


    if nargin<1
        devID = 'Dev2';
    end


    % Create task
    hDO = NationalInstruments.DAQmx.Task();

    % Connect to port0 line0
    chan = [devID,'/Port0/line0'];
    hDO.DOChannels.CreateChannel(chan,'',ChannelLineGrouping.OneChannelForEachLine);

    % Make digital writter class
    dWriter = DigitalSingleChannelWriter(hDO.Stream);

    % Output structure
    out.task = hDO;
    out.dWriter = dWriter;
