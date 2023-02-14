function plotChanSamples(obj, conditionToPlot)
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
    xGalvo =  chanSamples(:,1,conditionToPlot);
    yGalvo =  chanSamples(:,2,conditionToPlot);
    laser = chanSamples(:,3,conditionToPlot);
    digOut =  chanSamples(:,4,conditionToPlot);



    % Make plot        
    fig = zapit.utils.focusNamedFig(mfilename);

    timeAxisMS = ((1:length(xGalvo)) /obj.parent.DAQ.samplesPerSecond)*1E3;

    clf
    subplot(3,1,1)
    % analog volt output for 1st area to 1st scanner mirror
    plot(timeAxisMS,xGalvo,'k-','LineWidth',1);
    hold on
    plot(timeAxisMS,yGalvo,'b-','LineWidth',1);

    for ii = obj.edgeSamples
        plot([timeAxisMS(ii), timeAxisMS(ii)],ylim,'r--','LineWidth',1)
    end
    title('analog output to scan mirrors')
    ylabel('Galvo voltage')
        
    subplot(3,1,2)
    % analog volt output to laser and masking light
    plot(timeAxisMS,laser,'-','LineWidth',1,'MarkerSize',10);
    hold on
    title('analog output to laser')
    ylabel('amplitude')
    ylim(obj.parent.settings.laser.laserMinMaxControlVolts)

    for ii = obj.edgeSamples
        plot([timeAxisMS(ii), timeAxisMS(ii)],ylim,'r--','LineWidth',1)
    end


    subplot(3,1,3)
    plot(timeAxisMS,digOut,'-','LineWidth',1,'MarkerSize',10);
    hold on


    title('analog output to masking light')
    ylabel('State')
    xlabel(sprintf('Time [ms]'))
    set(gca,'YTick',[0,5],'YTickLabel',{'Low','High'})
    ylim([-0.25,5.25])

    for ii = obj.edgeSamples
        plot([timeAxisMS(ii), timeAxisMS(ii)],ylim,'r--','LineWidth',1)
    end
    
end % plotChanSamples

