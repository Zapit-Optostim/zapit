function varargout = writeWaveformsToDisk(obj,filePath)
    % Write waveform matrices that are to be sent to DAQ to disk
    %
    % zapit.stimConfig.writeWaveformsToDisk(filePath)
    %
    % Purpose
    % Save to disk the waveforms that are used to present stimuli in stereotaxic space.
    % In other words, these are the waveforms that Zapit is sending to the DAQ when
    % zapit.pointer.sendSamples is invoked. This method is not needed in normal operation
    % but is included in case users want to send out the waveforms using custom code
    % written in a different language. 
    %
    % The waveforms are saved in a version 6 .mat file called zapit_waveforms.mat;
    % and the file is saved in a directory defined by the filePath input argument.
    % If there is already a file at the location then it is overwritten without
    % warning! The .mat file contains a single cell array called waveforms. Each cell
    % contains the wavforms for one stimulus condition. Stimulus conditions can
    % be printed to the CLI with zapit.stimConfig.print, or written to disk along with
    % other relevant information using zapit.stimConfig.logStimulusParametersToFile
    % The latter method is necessary for later reconstituting what was presented.
    %
    % The order of the cells in the waveforms array corresponds to the order of the
    % stimulus locations in the stim config YAML file.
    %
    % The .mat file also contains a variable called samplesPerSecond, which is necessary
    % for downstream code to present the stimuli at the correct rate.
    %
    % The .mat file is saved as version 6 for increased compatibility with with
    % other languages.
    %
    % For a minimal example showing how to present the stimuli in the same way as
    % zapit see the class minimalStimPresenter in the examples folder located in
    % the project root directory.
    %
    % 
    % Inputs
    % filePath - Path to which the 'zapit_waveforms.mat' file will be written. If a
    %       file of the same name already exists at this location it is overwritten
    %       without warning!
    %
    % Outputs
    % waveforms [optional] - The waveform cell array that is printed to disk.
    %
    %
    % Rob Campbell - SWC 2023
    %
    % Also see:
    % zapit.stimConfig.logStimulusParametersToFile
    % zapit.stimConfig.print


    %%
    % Check input arguments
    if nargin<2
        fprintf('zapit.stimConfig.%s requires one input argument\n', mfilename)
        return
    end

    if ~exist(filePath,'dir')
        fprintf('The path "%s" does not exist. zapit.stimConfig.%s can not save waveforms there.\n', ...
            filePath, mfilename)
        return
    end


    %%
    % Make a cell array containing the waveforms
    cSamp = obj.chanSamples;

    for ii=1:size(cSamp.scan,3)
        % Singles are adequate and we save space
        waveforms{ii} = single([cSamp.scan(:,:,ii), cSamp.light(:,:,ii)]);
    end

    samplesPerSecond = obj.parent.DAQ.samplesPerSecond;

    %%
    % Save waveforms
    fname = 'zapit_waveforms.mat';
    save(fullfile(filePath,fname),'waveforms', 'samplesPerSecond', '-v6')


    %%
    % Optional output argument
    if nargout>0
        varargout{1} = waveforms;
    end

end % writeWaveformsToDisk
