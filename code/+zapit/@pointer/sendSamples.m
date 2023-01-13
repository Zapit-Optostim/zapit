function varargout = sendSamples(obj, t_trial, verbose)
    % Take X/Y coordinates of two points and cycle the laser between them.
    %
    % waveforms = zapit.pointer.sendSamples(obj,newTrial,verbose)
    %
    %
    % Purpose
    % Take X/Y coordinates of two points and exchange the laser between them at freqLaser for
    % pulseDuration seconds, locking it at a given point for tOpen ms. The parameters to actually
    % stimulate are obtained from the structure, t_trial, which is supplied as an obligatory
    % input argument (see below).
    % This function builds an n by 4 matrix of waveforms to send to the DAQ. The first two columns
    % are the scanner waveforms. The last two are the laser power and masking light.
    %
    % Inputs
    % t_trial - A structure withxs the following fields.
    %         CoordNum - [int] The index for the brain area to stimulate
    %         LaserOn - [int] If 1 the laser is turned on. If 0 the laser is off (control trial).
    %
    % verbose - [optional, false by default] If true print debug messages to screen.
    %
    % Outputs
    % waveforms - optionally return the waveforms for debug. 
    %
    %
    % Maja Skretowska - SWC 2020-2022
    % Rob Campbell - SWC 2022

    if nargin<3
        verbose = false;
    end

    if verbose
        fprintf('Stimulating area %d\n', t_trial.area)
    end


    % Make the waveforms to play
    waveforms = [];
    waveforms(:,1:2) = obj.stimConfig.chanSamples.scan(:,:,t_trial.area);
    waveforms(:,3:4) = obj.stimConfig.chanSamples.light(:,[1 2]);

    % Disable laser  if the user asked for this
    if t_trial.LaserOn == 0
        waveforms(:,3) = 0;
    end


    % TODO we need to set the triggering
    if ~isvalid(obj.DAQ.hAO) || ~strcmp(obj.DAQ.hAO.taskName, 'clockedao'); % TODO-- maybe this check should be in the
                                                % the createNewTask. So we don't make unless
                                                % the task names don't match?
        obj.DAQ.connectClockedAO('numSamplesPerChannel',size(waveforms,1));
    end


    
    % write voltage samples onto the task
    obj.DAQ.writeAnalogData(waveforms);

    % start the execution of the new task
    obj.DAQ.start;

    if nargout>0
        varargout{1} = obj.waveforms;
    end

end % sendSamples
