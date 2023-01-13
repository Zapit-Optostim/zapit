function obj = plotChanSamples(obj)
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


    if isempty(obj.chanSamples)
        return
    end

    xAxis = [1:obj.numSamplesPerChannel];

    anlgOut = obj.chanSamples.light(:,1);
    digOut = obj.chanSamples.light(:,3);

        
    figure(22) % TODO -- improve figure ID. This can cause a bug
    clf

        
    subplot(3,1,1)
    % analog volt output for 1st area to 1st scanner mirror
    plot(xAxis,obj.chanSamples.scan(:,1,1),'.','MarkerSize',10);
    hold on
    for ii = cycleEdges(1,:)
        plot([ii ii],[min(obj.chanSamples.scan(:,1,1)) max(obj.chanSamples.scan(:,1,1))],'g-','LineWidth',1)
    end
    title('analog output to scan mirrors')
    ylabel('area')
        
    subplot(3,1,2)
    % analog volt output to laser and masking light
    plot(xAxis,anlgOut,'.','MarkerSize',10);
    hold on
    for ii = cycleEdges(1,:)
        plot([ii ii],laserPowerInMW*[0 2],'g-','LineWidth',1)
    end
    title('analog output to laser')
    ylabel('amplitude')
        
    subplot(3,1,3)
    % digital volt output to laser
    plot(xAxis, digOut,'.','MarkerSize',10);
    hold on
    for ii = cycleEdges(1,:)
        plot([ii ii],digitalAmplitude*[0 1],'g-','LineWidth',1)
    end
    title('digital output to laser')
    ylabel('on/off')
    xlabel('samples generated at 5000 Hz rate')
    
end % plotChanSamples

