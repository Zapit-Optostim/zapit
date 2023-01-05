function obj = makeChanSamples(obj, laserPowerInMW, plotFigure)
    % Prepares voltages for each inactivation site
    %
    % zapit.pointer.makeChanSamples(laserPowerInMW)
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


    
    if nargin<4
        plotFigure = false;
    end
    

    numHalfCycles = 4;                          % arbitrary, no of half cycles to buffer

    % TODO: defaultLaserFrequency will probably be used to make the brain area config file and from there that will be the relevant value
    obj.numSamplesPerChannel = obj.DAQ.samplesPerSecond/obj.settings.experiment.defaultLaserFrequency*(numHalfCycles/2);
    
    % find edges of half cycles
    cycleEdges = linspace(1, obj.numSamplesPerChannel, numHalfCycles+1);
    edgeSamples = ceil(cycleEdges(1,:));
    
    
    % make up samples for scanner channels
    % (coordsLibrary is already in a volt format)
    scanChnl = zeros(obj.numSamplesPerChannel,2,size(obj.coordsLibrary,2)); % matrix for each channel
    %             lghtChnl = zeros(obj.numSamplesPerChannel,2,2);                         % 1st dim is samples, 2nd dim is channel, 3rd dim is conditions
    
    %% make up scanner volts to switch between two areas
    for inactSite = 1:size(obj.coordsLibrary, 1)    % CHECK if it really is the first dim
        
        % inactSite gets column from the coordinates library
        xVolts = obj.coordsLibrary(inactSite,1,:);
        yVolts = obj.coordsLibrary(inactSite,2,:);
        for cycleNum = 1:(length(edgeSamples)-1)
            segStart = edgeSamples(cycleNum);
            segStop = edgeSamples(cycleNum+1);
            siteIndx = rem(cycleNum+1,2)+1;         % check whether it's an odd (rem = 1) or even (rem = 0) number and then add 1 to get an index
            scanChnl(segStart:segStop,1,inactSite) = xVolts(siteIndx);
            scanChnl(segStart:segStop,2,inactSite) = yVolts(siteIndx);
        end
        
    end
    
    %% make up samples for laser and masking light channels    
    anlgOut = ones(1,obj.numSamplesPerChannel) * obh.laser_mW_to_control(laserPowerInMW); %Write the correct control voltage
    digitalAmplitude = 4;
    digOut = ones(1,obj.numSamplesPerChannel) * digitalAmplitude;

    % allow 1 ms around halfcycle change to be 0 (in case scanners are not in the right spot
    % TODO -- this should be based on empirical values
    MASK = ones(1,obj.numSamplesPerChannel);
    sampleInterval = 1/obj.DAQ.samplesPerSecond;
    nSamplesInOneMS = 1E-3 / sampleInterval;

    for ii=1:nSamplesInOneMS
        MASK(edgeSamples(1:end-1)+(ii-1))=0;
    end

    anlgOut = anlgOut.*MASK;
    digOut = digOut.*MASK;

    % Can probabky make
    lghtChnl(:,1) = anlgOut;              % analog laser output
    lghtChnl(:,2) = digOut*(5/digitalAmplitude);    % analog masking light output
    lghtChnl(:,3) = digOut;               % digital laser gate

    
    %% save all samples in a structure to access as object property
    obj.chanSamples.scan = scanChnl;
    % x-by-2-by-6, where rows are samples, columns are channels, and 3rd dim
    % is which area is selected
    
    obj.chanSamples.light = lghtChnl;
    % x-by-3-by-2, where rows are samples, columns are channels, and 3rd dim
    % is whether laser is off or on
    


    %% visualization of channel samples TODO -- make this neater or maybe refactor elsewhere?
    if ~plotFigure
        return
    end

    xAxis = [1:obj.numSamplesPerChannel];
        
    figure(22) % TODO -- improve figure ID. This can cause a bug
    clf

        
    subplot(3,1,1)
    % analog volt output for 1st area to 1st scanner mirror
    plot(xAxis,scanChnl(:,1,1),'.','MarkerSize',10);
    hold on
    for ii = cycleEdges(1,:)
        plot([ii ii],[min(scanChnl(:,1,1)) max(scanChnl(:,1,1))],'g-','LineWidth',1)
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
    
end % makeChanSamples

