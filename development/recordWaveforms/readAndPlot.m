function readAndPlot(fname,sampleRate,nChans)
    
    if nargin<3
        nChans=3;
    end

    if nargin<2
        sampleRate = 1E5;
    end
    fid = fopen(fname);

    data = fread(fid,'integer*2');

    figure
    cla
    hold on

    timeAxis = linspace(0,(length(data)/nChans)/sampleRate,length(data)/nChans)*1E3; % ms
    for ii=1:nChans
        plot(timeAxis,data(ii:nChans:end))
    end
    %xlim([0,1E4])
