function pulseDuration_ms = checkTimeAveragedPower(hZP)



    % Check the time-averaged power of a stimulus set. We want to know
    % whether the system is generating the same power per pulse over
    % stim number



    chanSamples = hZP.stimConfig.chanSamples;
    samplesPerSecond = hZP.settings.NI.samplesPerSecond;


    pulseTimeAveragedPower = zeros(1,size(chanSamples,3));
    numSamplesPerPulse =  zeros(1,size(chanSamples,3));


    for ii = 1:length(pulseTimeAveragedPower)
        laserTrace = chanSamples(:,3,ii);
        startTimes = find(diff(laserTrace)>0);

        firstPulseStart = startTimes(1);

        endTimes = find(diff(laserTrace)<0);
        endTimes(endTimes<firstPulseStart)=[];
        firstPulseEnd = endTimes(1);



        % Add the command voltage over this period
        pulseTimeAveragedPower(ii) = sum(laserTrace(firstPulseStart:firstPulseEnd));
        numSamplesPerPulse(ii) = firstPulseEnd - firstPulseStart;
    end


    figure(140)
    clf
    subplot(2,1,1)
    plot(pulseTimeAveragedPower, 'ok-')
    xlabel('Number of stimuli')
    ylabel('Integrated power per pulse [au]')
    grid on

    subplot(2,1,2)
    pulseDuration_ms = (numSamplesPerPulse/samplesPerSecond)*1E3
    plot(pulseDuration_ms, 'ok-')
    xlabel('Number of stimuli')
    ylabel('Pulse duration [ms]')
    grid on


