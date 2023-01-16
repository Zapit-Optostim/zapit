function saveLaserFit(obj)
    % Save the laser fit object to the user settings directory
    % 
    % zapit.pointer.saveLaserFit
    %
    % Purpose
    % Saves the laser fit to a .mat in the settings directory.
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
    % zapit.pointer.loadLaserFit
    % zapit.pointer.laser_mW_to_control

    if isempty(obj.laserFit)
        fprintf('No laser fit to save\n')
        return
    end


    tFile = zapit.settings.findSettingsFile;
    tDir = fileparts(tFile);
    laserFit = obj.laserFit;

    save(fullfile(tDir,'laserFit.mat'), 'laserFit')

end % saveLaserFit