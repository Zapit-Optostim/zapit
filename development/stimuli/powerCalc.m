function powerCalc
    % The original configuration of the software sees us present 4 mW of light for 12.5 ms.
    % The beam goes back and forth between two locations with a resultant duty cycle of 40 Hz. 
    % We want to try presenting the same total number of photons but over a shorter period of
    % time. So, for example, halving the time and doubling the intensity. 
    % The function calculates how many pulses we can cram into this duty cycle given 
    % the constraints of a fixed time for beam motion and a fixed max power. 


    blanking_ms = 0.4; % The scanners are pretty quiet with a 0.3 ms nominal
                       % transit time. Plus 0.1 for lag and so forth.

    base_ms = 12.5;
    base_mW = 4;

    pulseDuration_ms = linspace(1,10,40);
    pulseDuration_ms = [1,1.25,1.5,2,2.5, 3.4, 5, 6.125, base_ms];
    for ii= 1:length(pulseDuration_ms)
        ms = pulseDuration_ms(ii);
        total_ms = ms+blanking_ms;

        required_power(ii) = (base_ms/ms) * 4;
        num_pulses(ii) = floor(base_ms/total_ms);

    end

    zapit.utils.focusNamedFig(mfilename)
    clf
    subplot(1,2,1)
    plot(pulseDuration_ms,num_pulses,'o-k')
    ylabel('Num pulses')
    xlabel('Pulse duration')
    grid on


    subplot(1,2,2)
    plot(pulseDuration_ms,required_power,'o-k')
    ylabel('Required power (mW)')
    xlabel('Pulse duration')
    grid on
