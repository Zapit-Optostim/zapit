function removeOverlays(obj,overlayToRemove)
    % Remove overlaid line plot data from the camera image
    %
    % function removeOverlays(obj,overlayToRemove)
    %
    % Purpose
    % The camera image could have overlaid line plot data, such as the current estimated laser
    % position, the calibration locations for scanners or brain, etc. The handles for these are
    % stored in the structure obj.plotOverlayHandles, which could contain a number of different
    % things. % e.g. brain borders. This convenience method looks them up by name and deletes:
    % both removing data from the plot and also the associated field from the structure.
    %
    % The ideas behind this system is that we do not need one property per plot object,
    % and all plot objects are organised nicely under one property. They can easily be
    % deleted by different methods.
    %
    % Inputs
    % If no inputs are provided, this function deletes *all* plot handles and removes
    % all fields from the plotOverlayHandles structure. Alternatively, if
    % overlayToRemove is a string then all overlays associated with that field name
    % are removed.
    %
    % e.g. calibrateScanners uses obj.removeOverlays('calibrateScanners') to remove all
    % previous plot objects associated with it. This works because these were stored in
    % obj.plotOverlayHandles.calibrateScanners
    %
    %
    % Rob Campbell - SWC 2022


    if isempty(obj.plotOverlayHandles)
        return
    end

    if nargin<2
        overlayToRemove=[];
    end


    f=fields(obj.plotOverlayHandles);
    for ii=1:length(f)
        % Skip if the user provided an overlay name and this does not match
        if ~isempty(overlayToRemove) && ~strcmp(f{ii},overlayToRemove)
            continue
        end
        t_Handles = obj.plotOverlayHandles.(f{ii});

        if iscell(t_Handles)
            cellfun(@(x) delete(x), t_Handles)
        elseif isstruct(t_Handles)
            structfun(@(x) checkIfLineAndDelete(x), t_Handles)
        elseif ismatrix(t_Handles)
            delete(obj.plotOverlayHandles.(f{ii}))
        end

        obj.plotOverlayHandles = rmfield(obj.plotOverlayHandles,(f{ii}));
    end

end %removeOverlays


function checkIfLineAndDelete(h)
    if isa(h,'matlab.graphics.chart.primitive.Line')
        delete(h)
    end
end
