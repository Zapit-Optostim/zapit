function varargout = vidrio_clocked(vNI)
    % Run simple tests with the clocked task
    %
    % function vidrio_clocked(vNI)
    %
    % Purpose
    % Hook AOs to an osciloscope and run this. You should see the signals
    % played out on the scope.
    %
    % Inputs
    % vNI - Optionally supply an instance of zapit.hardware.DAQ.NI.vidriowrapper.
    %       If not supplied an instance is created.
    %
    % Outputs (optional)
    % vNI - Instance of the vidriowrapper class. If no output is requested, the
    %       instance used internally is cleaned up.
    %
    % Rob Campbell - SWC 2022


    if nargin<1
        vNI = zapit.hardware.DAQ.NI.vidriowrapper;
    end

    % Create unclocked task
    numSamples = 1000;
    vNI.connectClocked(numSamples,false,true)


    %---------------------------------------------------------------------------------------------
    % Play waveforms

    % make waveforms
    playForSeconds = 2;
    fprintf('Playing waveforms for %d seconds\n', playForSeconds)
    wForms = zeros(numSamples,3);
    wForms(:,1) = sin(linspace(-pi*2,pi*2,numSamples));
    wForms(:,2) = cos(linspace(-pi*2,pi*2,numSamples));
    wForms(:,3) = rand(numSamples,1)*pi;

    vNI.hC.writeAnalogData(wForms)
    vNI.start
    pause(playForSeconds)
    vNI.stop

    if nargout>0
        varargout{1} = vNI;
    else
        delete(vNI)
    end
