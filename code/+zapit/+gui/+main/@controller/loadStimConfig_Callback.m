function loadStimConfig_Callback(obj,~,~)

    obj.model.cam.stopVideo; % Stop video first as the video running seems to really slow down loading
    [pointsFile,fpath] = uigetfile('*.yaml','Pick a config file');
    pathToConfig = fullfile(fpath,pointsFile);

    fprintf('Loading %s\n', pathToConfig)
    obj.model.stimConfig = zapit.stimConfig(pathToConfig);
    obj.model.cam.startVideo;
end
