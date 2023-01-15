function loadLaserFit(obj)
% Load the laser fit object to the user settings directory
% 
%  Purpose
%  Loads the laser fit to a .mat in the settings directory.



    tFile = zapit.settings.findSettingsFile;
    tDir = fileparts(tFile);
    pathToLaserFit = fullfile(tDir,'laserFit.mat');

    if exist(pathToLaserFit,'file')
        load(pathToLaserFit);
        fprintf('Loading laser fit\n')
        obj.laserFit = laserFit;
    else
        fprintf('No laser fit file found. Laser is uncalibrated\n')
    end

