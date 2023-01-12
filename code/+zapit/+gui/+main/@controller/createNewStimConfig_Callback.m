function createNewStimConfig_Callback(obj,~,~)
    % Load the stim config editor GUI
    % 
    % 
    
    obj.hStimConfigEditor = zapit.gui.stimConfigEditor.controller(obj);
end
