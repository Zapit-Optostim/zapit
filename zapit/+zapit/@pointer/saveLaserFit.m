function saveLaserFit(obj)
% Save the laser fit object to the user settings directory
% 
%  Purpose
%  Saves the laser fit to a .mat in the settings directory.


    if isempty(obj.laserFit)
        fprintf('No laser fit to save\n')
        return
    end


    tFile = zapit.settings.findSettingsFile;
    tDir = fileparts(tFile);
    laserFit = obj.laserFit;

    % TODO: date stamp this file?
    save(fullfile(tDir,'laserFit.mat'), 'laserFit')
