function print(obj)
    % Print to the command line the index, coordinates, and brain area of each condition
    %
    % zapit.stimConfig
    %
    % Purpose
    % Provide a summary of the conditions in this stimulus configuration file
    % by printing to the command line what is in each stimulus condition. Example
    % output:
    %
    %  1. ML = +2.57 / AP = -3.58  <-->  ML = -2.57 / AP = -3.58  1' visual 
    %  2. ML = +0.54 / AP = +0.17  <-->  ML = -0.54 / AP = +0.17  2' motor 
    %  3. ML = +1.94 / AP = -1.18  <-->  ML = -1.94 / AP = -1.18  1' somatosensory trunk
    %  4. ML = -0.04 / AP = -3.89  Superior colliculus zonal layer

    fprintf('\n')

    for ii = 1:obj.numConditions
        tStim = obj.stimLocations(ii);
        areaNames = obj.getAreaNameFromCoords(tStim.ML, tStim.AP);

        fprintf('%d. ', ii)
        if length(tStim.ML)>1
            fprintf('ML = %+0.2f / AP = %+0.2f  <-->  ML = %+0.2f / AP = %+0.2f  ', ...
                tStim.ML(1), tStim.AP(1), tStim.ML(2), tStim.AP(2))

            areaNames = unique(areaNames);
            if length(areaNames) == 1
                fprintf('%s\n', areaNames{1})
            else
                fprintf('%s  <-->  %s\n', areaNames{:})
            end
        else
            fprintf('ML = %+0.2f / AP = %+0.2f  %s\n', tStim.ML, tStim.AP, areaNames)
        end
    end % for
end % print