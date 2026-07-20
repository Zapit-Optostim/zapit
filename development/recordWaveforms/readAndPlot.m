function varargout = readAndPlot(fname,sampleRate,nChans)

    % function varargout = readAndPlot(fname,sampleRate,nChans)
    % 
    % Read and plot raw data
    %
    % Reasonable defaults for inputs by default so it's enough to
    % to just feed in a file name. If no output arg is specifed the
    % function will plot the data to screen. If an output is requested
    % the plotting is skipped.
    %
    % Rob Campbell 


    if nargin<3
        nChans=3;
    end

    if nargin<2
        sampleRate = 1E5;
    end
    fid = fopen(fname);

    data = fread(fid,'integer*2');
    timeAxis = linspace(0,(length(data)/nChans)/sampleRate,length(data)/nChans)*1E3; % ms

    if nargout>0
        out.waveforms = data;
        out.time = timeAxis;
        varargout{1} = out;
        return
    end

    figure
    cla
    hold on

    for ii=1:nChans
        plot(timeAxis,data(ii:nChans:end))
    end
    %xlim([0,1E4])
