

Data generated as follows using the Dev branch on 4th Feb 2023


```matlab
hZP =  zapit.pointer('simulated',true,'settingsFile','zapitSystemSettings.yml');

hZP.loadStimConfig('uniAndBilateral_5_conditions.yml');


% "calibrate" it
hZP.applyUnityStereotaxicCalib;

% So now make and save the following
chanSamples = hZP.stimConfig.chanSamples;

% Then save with
save chanSamples.mat chanSamples



