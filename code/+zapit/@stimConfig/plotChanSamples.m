function obj = plotChanSamples(obj, laserPowerInMW, plotFigure)
    % Prepares voltages for each inactivation site
    %
    % zapit.pointer.plotChanSamples(laserPowerInMW)
    %
    %
    % Inputs
    % laserPowerInMW - Desired laser power in mW
    % plotFigure - false by default. If true make a debug figure
    %
    % Outputs
    % None but the chanSamples property matrix is updated.
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
    
end % plotMakeChanSamples

