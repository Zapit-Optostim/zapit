

Data generated as follows using the Dev branch on 4th Feb 2023


```matlab
hZP =  zapit.pointer('simulated',true);
hZP.stimConfig = zapit.stimConfig('uniAndBilateral_5_conditions.yml');
hZP.stimConfig.parent = hZP;

% "calibrate" it
hZP.refPointsSample = hZP.refPointsStereotaxic;

% So now make and save the following
chanSamples = obj.loadChanSamples;



