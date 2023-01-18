function stressTest(doRampStop)
    % Run through all stims at random
    %
    % function stressTest(doRampStop)
    %
    % Purpose
    % Conducts a stress test on the optostim software. It runs through
    % all stimulus conditions at random until the user presses the "STOP"
    % button in the figure window that opens.
    %
    % Inputs
    % doRampStop - optional. True by default. If true we ramp down the laser power at the end.
    %
    %
    % Rob Campbell - SWC 2023



    hZP  = zapit.utils.getObject;

    if isempty(hZP)
        return
    end

    if nargin<1
        doRampStop = true;
    end

    n = 0; % to keep track of the number of presentations

    % hZP.cam.stopVideo;
    f = figure;
    %f.ToolBar='off';
    ButtonH = uicontrol('Parent',f,'Style','pushbutton', ...
                        'String','STOP','Units','normalized',...
                        'Position',[0.3 0.5 0.4 0.2],'Visible','on',...
                        'Callback', @(~,~) stopTest);

    keepRunning = true;
    hZP.cam.stopVideo;
    successes = [];
    while keepRunning
        hZP.sendSamples('hardwareTrigger',false);
        pause(0.25);

        if doRampStop
            t = hZP.stopOptoStim;
            successes(end+1) = t;

        else
            hZP.DAQ.stop;
        end

        n = n+1;
        disp(n)

    end

    fS = find(successes==false);
    fprintf('Number of stop failures: %d\n',length(fS))
    close(f)
    hZP.DAQ.stop;
    hZP.cam.startVideo;


    function stopTest
        keepRunning = false;

    end

end
