function catAndMouseButton_Callback(obj,~,~)


    % Both can not be activate at the the same time
    if obj.CatMouseButton.Value == 1
        obj.PointModeButton.Value = 0;
    end




end
