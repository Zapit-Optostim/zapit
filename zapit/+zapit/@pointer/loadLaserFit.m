function loadLaserFit(obj)
    % Load the laser fit object to the user settings directory
    % 
    % zapit.pointer.loadLaserFit
    %
    % Purpose
    % Loads the laser fit to a .mat in the settings directory.
    %
    % Inputs
    % none
    %
    % Outputs
    % none
    %
    % Rob Campbell - SWC 2022
    %
    % See also:
    % zapit.pointer.generateLaserCalibrationCurve
    % zapit.pointer.saveLaserFit
    % zapit.pointer.laser_mW_to_control

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

end % loadLaserFit