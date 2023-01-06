function isPressed = isShiftPressed
    % Return true if shift is pressed
    %
    % zapit.utils.isShiftPressed
    %
    % 

    mod = get(gcbo,'currentModifier');
    isPressed = false;
    if length(mod)==1
        isPressed = strcmp(mod{1},'shift');
    end
end

