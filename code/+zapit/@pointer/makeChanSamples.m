function obj = makeChanSamples(obj, freqLaser, laserAmplitude, plotFigure)
    % Prepares voltages for each inactivation site
    %
    % zapit.pointer.makeChanSamples(freqLaser, laserAmplitude)
    %
    %
    % Inputs
    % freqLaser - Frequency of inactivation, amplitude of voltage fed to laser
    % laserAmplitude -
    % plotFigure - false by default. If true make a debug figure
    %
    % Outputs
    % None but the chanSamples property matrix is updated.
    %
    % Maja Skretowska - 2021


    if nargin<4
        plotFigure = false;
    end
    
    obj.freqLaser = freqLaser;                  % full cycles in Hz
    numHalfCycles = 4;                          % arbitrary, no of half cycles to buffer
    obj.numSamplesPerChannel = obj.DAQ.sampleRate/obj.freqLaser*(numHalfCycles/2);
    
    % TODO -- hardcoded stuff
    %  digitalAmplitude = 0.72;                       % old version with analog obis settings and without an arduino (gives 3.8 mW power)
    digitalAmplitude = 1.5; % fed into Arduino
    
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
    
    %masking light is always on, laser is on only when LaserOn == 1
    anlgOut = (-cos(linspace(0, numHalfCycles*2*pi, obj.numSamplesPerChannel)) + 1) * laserAmplitude;
    digOut = ones(1,obj.numSamplesPerChannel) * digitalAmplitude;

    % allow 2 samples around halfcycle change to be 0 (in case scanners are not in the right spot
    digOut([edgeSamples,edgeSamples(1:end-1)+1])= 0; 
    
    for lightCond = 0:1
        % if light condition is 0, then laser samples become 0 too
        lghtChnl(:,1,lightCond+1) = anlgOut*lightCond;              % analog laser output
        lghtChnl(:,2,lightCond+1) = digOut*(5/digitalAmplitude);    % analog masking light output
        lghtChnl(:,3,lightCond+1) = digOut*lightCond;               % digital laser gate
    end
    
    
    %% save all samples in a structure to access as object property
    obj.chanSamples.scan = scanChnl;
    % x-by-2-by-6, where rows are samples, columns are channels, and 3rd dim
    % is which area is selected
    
    obj.chanSamples.light = lghtChnl;
    % x-by-3-by-2, where rows are samples, columns are channels, and 3rd dim
    % is whether laser is off or on
    
    %% visualization of channel samples
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
        plot([ii ii],laserAmplitude*[0 2],'g-','LineWidth',1)
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

