function psfData = psfCrossSection(pointsToScan)
    % Testing code for acquiring then plotting nicely the beam pointing error
    %
    % Purpose
    % Acquires a "PSF" by scanning the beam across a sharp edge (like razor blade) with
    % photodiode underneath. The beam should go from being totally unoccluded to being occluded. 
    % The user feeds in "pointsToSan", which is a series of points along the Y axis. So the
    % razor blade should be oriented parallel to the X axis. A 10 micron spacing is totally
    % adequate as a the result of the acquisition is a cumulative Gaussian that is easy to fit
    % with a sigmoid.
    %
    % Wiring:
    % Feed photodiode into AI0 on the same DAQ as the scanners are controlled. Use low gain and
    % turn down the laser. You don't want to saturate the photodidoe.
    %
    % Plot
    % Inputs
    % pointsToScan - points in mm along the Y axis. OR the output of this function. 
    %           If the latter, the results are plotted and no acquistion is carried out. 
    %
    % Example
    % pointsToScan = 1:0.01:1.2; % 200 microns sampled every 10 microns
    % result = psfCrossSection(pointsToScan)
    % psfCrossSection(result) %plot the results and don't acquire
    % 
    %
    % Rob Campbell - SWC 2023


    % Get the data if none provided
    if ~isstruct(pointsToScan)
        hZP = zapit.utils.getObject;
        hZP.DAQ.connectUnclockedAI(2);


        for ii = 1:length(pointsToScan)
            hZP.moveBeamXYinMM([0,pointsToScan(ii)])
            pause(0.05)
            data(ii) = hZP.DAQ.readAnalogData;
        end

        % Make a structure for plot data
        psfData.x = pointsToScan';
        psfData.y = data';
    else
        psfData = pointsToScan;
    end

    % Centre x at its midpoint
    psfData.x = psfData.x - mean(psfData.x);
    zapit.utils.focusNamedFig(mfilename);
    clf
    subplot(2,1,1)
    hold on



    % Define the sigmoidal model function
    sigmoid = @(a, b, c, d, x) a + (b - a) ./ (1 + exp(-c .* (x - d)));

    % Define the custom model using fittype function
    model = fittype(sigmoid, 'independent', 'x', 'dependent', 'y', 'coefficients', {'a', 'b', 'c', 'd'});

    % Set initial parameter guesses:
    % In order these are:
    % 1. left asymptote
    % 2. right asymptote
    % 3. slope
    % 4. midpoint value (zero because we centred it)

    guesses = [mean(psfData.y(1:10)), mean(psfData.y(end-10:end)), 1, 0];

    % Fit the model to the data
    psfData.fitresult = fit(psfData.x, psfData.y, model, 'StartPoint', guesses);

    % Plot the results
    plot(psfData.fitresult, psfData.x, psfData.y);

    grid on


    subplot(2,1,2)
    x = linspace(min(psfData.x), max(psfData.x),1000)';
    PDF = diff(psfData.fitresult(x)) ./ diff(x);
    PDF = PDF*-1; % TODO: hard-coded and assumes we go from high to low
    x = x(1:end-1);

    % Centre the curve at zero
    [~,ind]=max(PDF);
    x = x-x(ind);
    x = x * 1E3;% convert to microns
    plot(x,PDF,'-k')

    % Get FWHM
    halfCurve = PDF(1:ind);
    halfMax = PDF(ind)/2;
    [~,ind]=min(abs(halfCurve-halfMax));
    FWHM = round(abs(x(ind))*2);
    title(sprintf('FWHM = %d microns\n', FWHM))
    psfData.FWHM = FWHM;
    grid on

end %plotPointingError
