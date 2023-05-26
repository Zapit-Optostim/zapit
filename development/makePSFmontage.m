function h = makePSFmontage(data)
    % Testing code for making a PSF montage
    %
    % Example
    %
    % Run at the CLI:
    %  [R,C] = hZP.generateScannerCalibrationPoints;
    %  [out,im] = hZP.measurePointingAccuracy([C,R]);
    %  makePSFmontage(out)
    %
    %
    % To plot data from the last calibration in the API
    % makePSFmontage(hZP.calibrateScannersPosData)
    %
    % Rob Campbell



    zapit.utils.focusNamedFig(mfilename);
    clf

    ims=cat(3,data(:).laserSpotIm);

    ims = ims./max(ims,[],1:2);

    % Get the number of rows and columns based on the position of the points in the grid
    % TODO: THIS DOES NOT HANDLE MISSING PSFs! The DATA OUTPUT SHOULD INCLUDE THIS SOMEHOW.
    t=reshape([data.targetCoords],[2,length(data)])';
    p =[length(unique(t(:,1))),length(unique(t(:,2)))];

    h = montage(ims, 'size', p, 'BackGroundColor', 'w');

    subplotSize = size(h.CData,1:2) ./  p;
    subplotSize = subplotSize(1);

    % Loop through and add numbers
    n=1;
    offset=25;
    for ii = 1:p(2)
        for jj = 1:p(1)
            x = offset + (ii-1) * subplotSize;
            y = offset + (jj-1) * subplotSize;
            text(x,y, num2str(n),'color','y', 'FontSize',15, 'FontWeight', 'Bold')
            n=n+1;
        end
    end

    % Add a scale bar to the first image
    % TODO: should be saving mics/pix with the data. This is a terrible way of getting the value:
    s=zapit.settings.readSettings;
    %s.camera.micronsPerPixel  = 10; %HACK! TODO
    mpix = s.camera.micronsPerPixel / (subplotSize/size(ims,1));

    micronsForBar = 200;
    barLength = micronsForBar/mpix; % One hundred micron scale bar length
    hold on
    x=subplotSize-25; % How far in from image edge to place the bar
    plot([x-barLength, x], [x,x,], '-w', 'LineWidth', 3)
    text(x,x-21, [sprintf('%d ',micronsForBar),'\mum'], 'color', 'w', ...
             'FontSize', 12, 'FontWeight', 'Bold', ...
             'HorizontalAlignment', 'right')


    % QUICKLY GET A FWHM PSF
    im = ims(:,:,1);
    zapit.utils.focusNamedFig([mfilename,'2']);
    clf
    xSection = sum(im,1);
    xSection = xSection-min(xSection);
    xSection = xSection/max(xSection);
    pos = (1:length(xSection)) * s.camera.micronsPerPixel;
    pos = pos-mean(pos);
    plot(pos,xSection)

    % Get the FWHM
    [~,ind]=min(abs(pos));
    tmp = xSection(1:ind);
    [~,ind]=min(abs(tmp-0.5));

    fwhm = abs(pos(ind))*2;
    title(sprintf('FWHM = %d microns', round(fwhm)))


end %makePSFmontage





function [p,n]=numSubplots(n)
    % function [p,n]=numSubplots(n)
    %
    % Purpose
    % Calculate how many rows and columns of sub-plots are needed to
    % neatly display n subplots.
    %
    % Inputs
    % n - the desired number of subplots.
    %
    % Outputs
    % p - a vector length 2 defining the number of rows and number of
    %     columns required to show n plots.
    % [ n - the current number of subplots. This output is used only by
    %       this function for a recursive call.]
    %
    %
    %
    % Example: neatly lay out 13 sub-plots
    % >> p=numSubplots(13)
    % p =
    %     3   5
    % for i=1:13; subplot(p(1),p(2),i), pcolor(rand(10)), end
    %
    %
    % Rob Campbell - January 2010


    while isprime(n) & n>4,
        n=n+1;
    end

    p=factor(n);

    if length(p)==1
        p=[1,p];
        return
    end

    while length(p)>2
        if length(p)>=4
            p(1)=p(1)*p(end-1);
            p(2)=p(2)*p(end);
            p(end-1:end)=[];
        else
            p(1)=p(1)*p(2);
            p(2)=[];
        end
        p=sort(p);
    end


    %Reformat if the column/row ratio is too large: we want a roughly
    %square design
    while p(2)/p(1)>2.5
        N=n+1;
        [p,n]=numSubplots(N); %Recursive!
    end

    end %numSubplots
