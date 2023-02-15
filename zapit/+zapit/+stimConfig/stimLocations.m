classdef stimLocations

    % Class that defines the field names for the stimulus locations
    %
    % function stimLoc = zapit.stimConfig.stimLocations
    %
    % Purpose
    % The stimLocations property in the zapit.stimConfig class defines the coordinates
    % to which the beam will go in each condition and also other meta-data that are
    % important with respect to the trial. The stimLocations data are, however, created
    % in the zapit.gui.stimConfigEditor class in the method returnStimConfigStructure.
    % This class acts as a template to ensure that no matter where the stimLocations are
    % defined, they will always be of the correct type and have the right field names.
    %
    %
    % Rob Campbell - SWC 2023

    properties
        ML = []
        AP = []
        Class = 'stimulate' % The user could in theory in future replace this
                            % with some other helpful string like "experiment" or "control".
        Type = '' % Options right now: 'bilateral_points', 'unilateral_points', 'unilateral_point'
        Attributes = {}
    end % properties


    methods

    end % methods

end % classdef
