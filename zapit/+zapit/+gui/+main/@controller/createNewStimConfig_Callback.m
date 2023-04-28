function createNewStimConfig_Callback(obj,~,~)
    % Load the stim config editor GUI
    %
    % zapit.gui.main.controller.createNewStimConfig_Callback
    %
    % Purpose
    % Launches the stimulus config editor GUI and also attaches to it references
    % for the main GUI and the model (zapit.pointer).
    %
    %
    % Rob Campbell - SWC 2023

    obj.hStimConfigEditor = zapit.gui.stimConfigEditor.controller(obj);

end % createNewStimConfig_Callback

