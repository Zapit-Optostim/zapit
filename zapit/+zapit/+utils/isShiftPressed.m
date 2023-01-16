function isPressed = isShiftPressed
    % Return true if shift is pressed
    %
    % zapit.utils.isShiftPressed
    %
    % Inputs
    % none
    %
    % Outputs
    % isPressed - boolean. True if shift is presed. False otherwise.
    %
    % Rob Campbell - SWC 2022

    mod = get(gcbo,'currentModifier');
    isPressed = false;
    if length(mod)==1
        isPressed = strcmp(mod{1},'shift');
    end

end % isShiftPressed

