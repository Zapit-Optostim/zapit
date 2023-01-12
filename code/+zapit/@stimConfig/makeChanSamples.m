function makeChanSamples(obj, laserPowerInMW)
    % Prepares voltages for each photostimulation site
    %
    % zapit.stimConfig.makeChanSamples(laserPowerInMW)
    %
    %
    % Inputs
    % laserPowerInMW - Desired laser power in mW
    %
    % Outputs
    % None but the chanSamples property is updated.
    %
    % Maja Skretowska - 2021


    

    numHalfCycles = 4; % arbitrary, no of half cycles to buffer

    % TODO: defaultLaserFrequency will probably be used to make the brain area config file and from there that will be the relevant value
    obj.numSamplesPerChannel = obj.parent.DAQ.samplesPerSecond/obj.parent.settings.experiment.defaultLaserFrequency*(numHalfCycles/2);
    
    % find edges of half cycles
    cycleEdges = linspace(1, obj.numSamplesPerChannel, numHalfCycles+1);
    edgeSamples = ceil(cycleEdges(1,:));
    
    
    % make up samples for scanner channels
    % (coordsLibrary is already in a volt format)
    coordsLibrary = obj.coordsLibrary;
    scanChnl = zeros(obj.numSamplesPerChannel,2,size(coordsLibrary,2)); % matrix for each channel
    %             lghtChnl = zeros(obj.numSamplesPerChannel,2,2);                         % 1st dim is samples, 2nd dim is channel, 3rd dim is conditions
    
    %% make up scanner volts to switch between two areas
    for inactSite = 1:size(coordsLibrary, 1)    % CHECK if it really is the first dim
        
        % inactSite gets column from the coordinates library
        xVolts = coordsLibrary(inactSite,1,:);
        yVolts = coordsLibrary(inactSite,2,:);
        for cycleNum = 1:(length(edgeSamples)-1)
            segStart = edgeSamples(cycleNum);
            segStop = edgeSamples(cycleNum+1);
            siteIndx = rem(cycleNum+1,2)+1;         % check whether it's an odd (rem = 1) or even (rem = 0) number and then add 1 to get an index
            scanChnl(segStart:segStop,1,inactSite) = xVolts(siteIndx);
            scanChnl(segStart:segStop,2,inactSite) = yVolts(siteIndx);
        end
        
    end
    
    %% make up samples for laser and masking light channels    
    anlgOut = ones(1,obj.numSamplesPerChannel) * obj.parent.laser_mW_to_control(laserPowerInMW); %Write the correct control voltage
    digitalAmplitude = 4;
    digOut = ones(1,obj.numSamplesPerChannel) * digitalAmplitude;

    % allow 1 ms around halfcycle change to be 0 (in case scanners are not in the right spot
    % TODO -- this should be based on empirical values
    MASK = ones(1,obj.numSamplesPerChannel);
    sampleInterval = 1/obj.parent.DAQ.samplesPerSecond;
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
    

    
end % makeChanSamples

