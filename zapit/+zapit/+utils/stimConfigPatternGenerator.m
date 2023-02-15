function stimConfigPatternGenerator(fname,coords,varargin)
    % Add a pattern of points to a stim config file. Creates it if necessary
    %
    % function zapit.utils.stimConfigPatternGenerator(fname,varargin)
    %
    % Purpose
    % Used to generate patterns of unilateral stimulation points. So if you 
    % make a grid of, say, 9 points. On a given trial only one of these points
    % will be stimulated.
    %
    %
    % Inputs (required)
    % fname - String defining relative or absolute path to stim config file name. 
    %        If file does not exist, it will be created. If it does exist, stimuli
    %        will be appended to the end of the file. If you wish to wipe an existing
    %        file see optional args below. 
    % coords - A 1x2 vector of coordinates: [ML,AP]. In mm.
    %
    % Input (optional param/val pairs)
    % 'pattern' - Which pattern to make. Options: 'grid' (default), 'cross', 'MLline', 'APline'
    % 'patternSize' - Scalar defnining how large the pattern should be in mm. 2 mm by default.
    %               If 'pattern' is 'grid or 'cross' then patternSize can optionally be a vector of
    %               length 2. In this case the first number is size along ML and the second size
    %               along AP.
    % 'numPoints' - Number of points along each dimension. 3 by default. Use an odd number if you
    %               want a point located at your coordinates. If 'pattern' is 'grid or 'cross' then
    %               numPoints can optionally be a vector of length 2. In this case the first number
    %               is n along ML and the second n along AP.
    % 'laserPower' - scalar. By default the values from the settings file are used.
    % 'bilateral' - bool. False by default. If true generate mirrored points on the other hemisphere.
    % 'overwriteFile' - false by default. If true, the file will be overwritten if it exists.
    % 'makePlot' - Bool. False by default. Generate a plot showing the locations of the stim points.
    %
    %
    % Outputs
    % none
    %
    %
    % EXAMPLES
    % All the following examples make files in the current MATLAB directory
    %
    % Example 1
    % Make a cross centred at bregma that extends 5 by 5 mm with 5 points along each axis:
    % zapit.utils.stimConfigPatternGenerator('myCrosses',[0,0], 'pattern', 'cross', ...
    %                                        'patternSize', 4, 'numPoints', 5)
    % Now add a smaller cross near left V1
    % zapit.utils.stimConfigPatternGenerator('myCrosses',[-2.5,-4], 'pattern', 'cross', ...
    %                                        'patternSize', 2, 'numPoints', 3)
    % Plot it:
    % zapit.utils.plotStimuli('myCrosses.yml')
    %
    % Example 2
    % Unique points covering visual cortex bilaterally (note abbreviated param names)
    % zapit.utils.stimConfigPatternGenerator('myV1',[-2.75,-4],'num',3,'patterns',1);
    % zapit.utils.stimConfigPatternGenerator('myV1',[2.75,-4],'num',3,'patterns',1);
    % zapit.utils.plotStimuli('myV1.yml')
    %
    % Example 3
    % Non-square grid covering visual cortex with bilaterally symmetric points then make plot
    % without an extra line of code.
    % zapit.utils.stimConfigPatternGenerator('myV1bilateral',[-2.75,-3.8],'num',[3,5], ...
    %        'patterns', [1,1.5],'bilateral',true, 'makePlot', true);
    %
    %
    % MORE EXAMPLES:
    % https://zapit.gitbook.io/user-guide/using-the-gui/generating-stimulus-patterns-at-the-cli
    %
    %
    % Rob Campbell - SWC 2023


    % Ensure file name has the correct extension
    [tPath,tName] = fileparts(fname);
    fname = fullfile(tPath,[tName,'.yml']);

    params = inputParser;
    params.addParameter('pattern','grid',@ischar);
    params.addParameter('patternSize',2,@isnumeric);
    params.addParameter('numPoints',3,@isnumeric);
    params.addParameter('laserPower',[],@isnumeric);
    params.addParameter('bilateral',false,@islogical);
    params.addParameter('overwriteFile',false,@islogical);
    params.addParameter('makePlot',false,@islogical);


    params.parse(varargin{:});

    pattern = params.Results.pattern;
    patternSize = params.Results.patternSize;
    numPoints = params.Results.numPoints;
    laserPower = params.Results.laserPower;
    bilateral = params.Results.bilateral;
    overwriteFile = params.Results.overwriteFile;
    makePlot = params.Results.makePlot;

    % Read settings
    tSettings = zapit.settings.readSettings;
    if isempty(laserPower)
        laserPower = tSettings.experiment.defaultLaserPowerMW;
    end


    % First we make the pattern
    if length(patternSize) == 1
        patternSize = [patternSize, patternSize];
    end

    if length(numPoints) == 1
        numPoints = [numPoints, numPoints];
    end

    % (These pattern size vectors will be the same for all patterns so we define here)
    x = linspace(-patternSize(1)/2, patternSize(1)/2, numPoints(1))';
    y = linspace(-patternSize(2)/2, patternSize(2)/2, numPoints(2))';


    switch lower(pattern)
    case 'cross'
        tmp{1} = repmat(coords, length(x),1);
        tmp{1}(:,1) = tmp{1}(:,1) + x;
        tmp{2} = repmat(coords, length(y),1);
        tmp{2}(:,2) = tmp{2}(:,2) + y;

        pointMatrix = cat(1,tmp{:});

    case 'grid'
        [ML,AP] = meshgrid(x,y);
        pointMatrix = repmat(coords,length(ML(:)),1) + [ML(:),AP(:)];

    case 'mlline'
        % Line extended along ML
        pointMatrix = repmat(coords, length(x),1);
        pointMatrix(:,1) = pointMatrix(:,1) + x;
    case 'apline'
        % Line extended along AP
        pointMatrix = repmat(coords, length(x),1);
        pointMatrix(:,2) = pointMatrix(:,2) + x;
    otherwise
        fprintf('Unknown pattern type "%s"\n', pattern)
        return
    end % switch


    pointMatrix = unique(pointMatrix,'rows');

    % Convert the point matrix into a structure that we can save to disk as a YAML
    pointAttributes.laserPowerInMW = laserPower;
    pointAttributes.stimDutyCycleHz = tSettings.experiment.defaultDutyCycleHz;
    pointAttributes.offRampDownDuration_ms = tSettings.experiment.offRampDownDuration_ms;


    % If we are appending to the file, we must load existing contents now.
    if ~overwriteFile && exist(fname,'file')
        stimC = zapit.yaml.ReadYaml(fname);
        n = length(fields(stimC));
    else
        n = 0;
    end


    for ii = 1:length(pointMatrix)
        fieldName = sprintf('stimLocations%02d',ii+n);
        stimC.(fieldName) = zapit.stimConfig.stimLocations; %create a template

        stimC.(fieldName).ML = pointMatrix(ii,1);
        stimC.(fieldName).AP = pointMatrix(ii,2);
        if bilateral
            stimC.(fieldName).ML(2) = -pointMatrix(ii,1);
            stimC.(fieldName).AP(2) = pointMatrix(ii,2);
        end

        stimC.(fieldName).Type = 'unilateral_points';

        % The attributes for each point can be different in theory even if at
        % the moment we make them all the same.
        stimC.(fieldName).Attributes = pointAttributes;
    end

    % Write to disk
    if overwriteFile && exist(fname,'file')
        delete(fname)
    end

    zapit.yaml.WriteYaml(fname, stimC);


    if makePlot
        zapit.utils.plotStimuli(fname)
    end

end % stimConfigPatternGenerator
