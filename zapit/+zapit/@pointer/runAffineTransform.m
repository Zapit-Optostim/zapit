function varargout = runAffineTransform(obj, targetBeamLocation, actualBeamLocation, diagnosticPlots)
    % Run an affine transformation to calibrate scanners to camera
    %
    % zapit.pointer.runAffineTransform(targetBeamLocation, actualBeamLocation, diagnosticPlots)
    %
    % Purpose
    % Runs an affine transform to calibrate the scanner and camera.
    % 
    % Inputs (optional)
    % targetBeamLocation - 
    % actualBeamLocation - 
    %  If both the above are provided and not empty, the transform is done on these. 
    %  Otherwise, the method looks in the calibrateScannersPosData property and extracts 
    %  data from there. Both the above arguments are n by 2 matrices with one x/y 
    % coordinate per row.
    %
    % diagnosticPlots - false by default.
    %
    % Rob Campbell - SWC 2023

    if nargin<3 || isempty(targetBeamLocation) || isempty(actualBeamLocation)
        if ~isempty(obj.calibrateScannersPosData)
            targetBeamLocation = cat(1,obj.calibrateScannersPosData(:).targetCoords);
            actualBeamLocation = cat(1,obj.calibrateScannersPosData(:).actualCoords);
        else
            return
        end
    end 

    if nargin<4
        diagnosticPlots = false;
    end

    if diagnosticPlots

        fig = zapit.utils.focusNamedFigure('scannercalibration');
        clf
        hold(fig,'on')

        plot(targetBeamLocation(:,1),targetBeamLocation(:,2),'or')
        plot(actualBeamLocation(:,1),actualBeamLocation(:,2),'ok')

        for ii=1:size(actualBeamLocation)
            x = [targetBeamLocation(ii,1), actualBeamLocation(ii,1)];
            y = [targetBeamLocation(ii,2), actualBeamLocation(ii,2)];
            plot(x,y,'-k')
        end
        hold(fig,'off')

    end

    % Check if there are duplicate entries in the actual beam positions
    tmp = unique(round(actualBeamLocation),'rows','first');

    if size(tmp,1) ~= size(actualBeamLocation,1)
        fprintf('There are %d duplicate values in the actual beam positions\n', ...
            size(actualBeamLocation,1) - size(tmp,1))
    end

    % runs affine transformation
    tform = fitgeotrans(targetBeamLocation,actualBeamLocation,'similarity');
    
    obj.transform = tform;

    if nargout>0
        varargout{1} = tform;
    end

end % runAffineTransform
