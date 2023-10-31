function testFiltering

    % Test a convolution for generating the smoothed scanner waveforms instead of the
    % ad-hoc linspace thing


    nSamples = 100;
    wavForm = [ones(1,nSamples), ...
                ones(1,nSamples)*2, ...
                ones(1,nSamples)*1.5]';

    clf
    kernelLength = 8;
    filtWav = circshift(wavForm,kernelLength*2);
    kernel = ones(kernelLength,1)/kernelLength;
    filtWav = conv(filtWav,kernel,'valid');
    % Add in the missing values at the end
    filtWav(end:end+kernelLength-1) = filtWav(end);

    filtWav = circshift(filtWav,round(kernelLength*-1.5));

    plot(wavForm, '.k-','color',[1,1,1]*0.5)
    hold on
    plot(filtWav+0.003, '.r-')


    if length(wavForm) == length(filtWav)
        fprintf('Filtered and original waveforms are the same length\n')
    end
