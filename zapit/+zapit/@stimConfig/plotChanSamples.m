function obj = plotChanSamples(obj, conditionToPlot)
    % Plots the voltage waveforms that will be send to the DAQ
    %
    % zapit.stimConfig.plotChanSamples
    %
    % Purpose
    % Makes diagnostic plots of of the scanner waveforms.
    %
    % Inputs
    % none
    %
    % Outputs
    % none
    %
    % Maja Skretowska - 2021


    if nargin<2
        conditionToPlot = 1;
    end


    % Get the data
    chanSamples = obj.chanSamples;
    if isempty(chanSamples)
        return
    end

    % extract data of interest
    anlgOut = chanSamples.light(:,1,conditionToPlot);
    digOut =  chanSamples.light(:,2,conditionToPlot);
    xGalvo =  chanSamples.scan(:,1,conditionToPlot);
    yGalvo =  chanSamples.scan(:,2,conditionToPlot);
    numHalfCycles = 4; % TODO -- should not be here like this. SETTINGS!
    edgeSamples = ceil(linspace(1, obj.numSamplesPerChannel, numHalfCycles+1));



    % Make plot        
    fig = zapit.utils.focusNamedFig(mfilename);

    clf
    subplot(3,1,1)
    % analog volt output for 1st area to 1st scanner mirror
    plot(xGalvo,'.k','MarkerSize',10);
    hold on
    plot(yGalvo,'.r','MarkerSize',10);

    for ii = edgeSamples
        plot([ii ii],ylim,'g--','LineWidth',1)
    end
    title('analog output to scan mirrors')
    ylabel('area')
        
    subplot(3,1,2)
    % analog volt output to laser and masking light
    plot(anlgOut,'.','MarkerSize',10);
    hold on
    for ii = edgeSamples
        plot([ii ii],ylim,'g--','LineWidth',1)
    end
    title('analog output to laser')
    ylabel('amplitude')
        
    subplot(3,1,3)
    % digital volt output to laser <--- TODO what is this?
    plot(digOut,'.','MarkerSize',10);
    hold on
    for ii = edgeSamples
        plot([ii ii],ylim,'g--','LineWidth',1)
    end
    title('analog output to masking light')
    ylabel('on/off')
    xlabel('samples generated at 5000 Hz rate')
    
end % plotChanSamples

