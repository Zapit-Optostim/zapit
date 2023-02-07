function drawBrainAreasOnSample(obj,areaCoords)
    % Run the beam around the perimeter of defined brain areas
    %
    % zapit.pointer.drawBrainAreasOnSample(obj,areaCoords)
    %
    % Purpose
    % Accepts a list of brain area index values and runs the beam around them.
    % Must run DAQ.stopAndDeleteAOTask manually to stop.
    % This function is usually called by zapit.gui.main.controller.paintArea_Callback
    %
    % Inputs
    % areaCoords - a vector that is a list of brain area index values.
    % Does no plotting.


    if isempty(obj.stimConfig)
        return
    end

    atlasData = obj.stimConfig.atlasData;
    brain_areas = atlasData.dorsal_brain_areas; % For ease
    bAreas = brain_areas(areaCoords).boundaries_stereotax;
    bAreas = arrayfun(@(a) brain_areas(a).boundaries_stereotax,areaCoords, 'UniformOutput', false);
    bAreas = cat(1,bAreas{:});

    % TODO : ramp beam between areas and switch off laser during the ramps
    %        this will make it run hugely quieter

    % Transform into sample space
    coords = cellfun(@(x) zapit.utils.rotateAndScaleCoords(fliplr(x)', ...
                            obj.refPointsStereotaxic, ...
                            obj.refPointsSample)', ...
                     bAreas, 'UniformOutput', false);

    % Add short ramps between jumps to areas
    n = 200; % Number of points in the jump between areas

    laserControl = obj.laser_mW_to_control(obj.settings.calibrateScanners.calibration_power_mW);

    for ii=1:length(coords)-1

        % Add laser and blanking signals
        coords{ii} = coords{ii}(1:2:end,:); % downsample to avoid high sample rates later
        coords{ii}(:,3) = laserControl;
        coords{ii}(:,4) = 0; % blanking LED

        % Make the ramps
        x1 = coords{ii}(end,1);
        x2 = coords{ii+1}(1,1);
        y1 = coords{ii}(end,2);
        y2 = coords{ii+1}(1,2);

        galvoRamp = [linspace(x1,x2,n)',linspace(y1,y2,n)'];
        galvoRamp(:,3:4) = 0; % so beam is off

        coords{ii} = [coords{ii}; galvoRamp];

    end

    % Now the last position wraps around to the first
    coords{end} = coords{end}(1:2:end,:);
    coords{end}(:,3) = laserControl;
    coords{end}(:,4) = 0; % blanking LED

    % Make the ramps
    x1 = coords{end}(end,1);
    x2 = coords{1}(1,1);
    y1 = coords{end}(end,2);
    y2 = coords{1}(1,2);

    galvoRamp = [linspace(x1,x2,n)',linspace(y1,y2,n)'];
    galvoRamp(:,3:4) = 0; % so beam is off

    coords{end} = [coords{end}; galvoRamp];

    coords = cat(1, coords{:});


    % First place beam in the centre of the area we want to stimulate
    obj.moveBeamXY(mean(coords(:,1:2)));
    
    %Replace first two columns with voltage values
    [xVolt,yVolt] = obj.mmToVolt(coords(:,1), coords(:,2));

    coords(:,1) = xVolt;
    coords(:,2) = yVolt;

    % NOTE: changing the number of samples per second will speed up presentation of the spots.
    % At 1000 you will by eye see a grid of points. On the screen, though, this is not visible.
    % Would have to average many frames to see this.


    % Set sample rate so we are drawing at about 60 cycles per second.
    n = length(coords) * 50;
    sRate = round(10^round(log10(n),1));

    maxSampleRate = 125000;

    % If we get sample rate issues we can maybe set the blanking signal to zero
    % at the start then play out only three AOs.
    if sRate>maxSampleRate
        fprintf('Draw brain areas capping sample rate from %d to %d\n', ...
        sRate, maxSampleRate)
        sRate = maxSampleRate;
    end


    obj.DAQ.connectClockedAO('numSamplesPerChannel',size(coords,1), ...
                            'samplesPerSecond',sRate, ...
                            'taskName','scannercalib')

    obj.DAQ.writeAnalogData(coords)

    obj.DAQ.start;

end
