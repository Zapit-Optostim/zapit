function varargout = vidrio_unclocked(vNI)
    % Run simple tests with the unclocked task
    %
    % function vidrio_unclocked(vNI)
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
    vNI.connectUnclocked(true)


    %---------------------------------------------------------------------------------------------
    % Change laser value
    vals = rand(1,10) * 3;
    input(sprintf('\nPress return to play %d random values through the laser control line\n', ...
          length(vals)), 's')
    for ii=1:length(vals)
        vNI.setLaserPowerControlVoltage(vals(ii))
        pause(0.125)
    end



    if nargout>0
        varargout{1} = vNI;
    else
        delete(vNI)
    end
