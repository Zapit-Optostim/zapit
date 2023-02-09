classdef (Abstract) settingsValuesTests

    % Tests associated with default_settings

    methods(Static)

        function [actualStruct,isValid] = check_isnumeric(actualStruct,defaultStruct,sectionName,fieldName)
            isValid = true;
            if ~isnumeric(actualStruct.(sectionName).(fieldName))
                fprintf('-> %s.%s should be a number. Setting it to %d.\n', ...
                    sectionName,fieldName,defaultStruct.(sectionName).(fieldName))
                actualStruct.(sectionName).(fieldName) = defaultStruct.(sectionName).(fieldName);
                isValid = false;
            end
        end

        function [actualStruct,isValid] = check_ischar(actualStruct,defaultStruct,sectionName,fieldName)
            isValid = true;
            if ~ischar(actualStruct.(sectionName).(fieldName))
                fprintf('-> %s.%s should be a scalar. Setting it to %s.\n', ...
                    sectionName,fieldName,defaultStruct.(sectionName).(fieldName))
                actualStruct.(sectionName).(fieldName) = defaultStruct.(sectionName).(fieldName);
                isValid = false;
            end
        end

        function [actualStruct,isValid] = check_isscalar(actualStruct,defaultStruct,sectionName,fieldName)
            isValid = true;
            if ~isscalar(actualStruct.(sectionName).(fieldName))
                fprintf('-> %s.%s should be a scalar. Setting it to %d.\n', ...
                    sectionName,fieldName,defaultStruct.(sectionName).(fieldName))
                actualStruct.(sectionName).(fieldName) = defaultStruct.(sectionName).(fieldName);
                isValid = false;
            end
        end

        function [actualStruct,isValid] = check_isZeroOrGreaterScalar(actualStruct,defaultStruct,sectionName,fieldName)
            isValid = true;
            if ~isscalar(actualStruct.(sectionName).(fieldName)) || ...
                    actualStruct.(sectionName).(fieldName)<0
                fprintf('-> %s.%s should be a number. Setting it to %d.\n', ...
                    sectionName,fieldName,defaultStruct.(sectionName).(fieldName))
                actualStruct.(sectionName).(fieldName) = defaultStruct.(sectionName).(fieldName);
                isValid = false;
            end
        end

        function [actualStruct,isValid] = check_isLogicalScalar(actualStruct,defaultStruct,sectionName,fieldName)
            isValid = true;
            if ~isscalar(actualStruct.(sectionName).(fieldName)) || ...
                actualStruct.(sectionName).(fieldName) ~= 0 || ...
                actualStruct.(sectionName).(fieldName) ~= 1
                fprintf('-> %s.%s should be a logical scalar. Setting it to %d.\n', ...
                    sectionName,fieldName,defaultStruct.(sectionName).(fieldName))
                actualStruct.(sectionName).(fieldName) = defaultStruct.(sectionName).(fieldName);
                isValid = false;
            end
        end


        %% The following perform conversions not checks
        function [actualStruct,isValid] = convert_cell2mat(actualStruct,~,sectionName,fieldName)
            isValid = true;
            actualStruct.(sectionName).(fieldName) = cell2mat(actualStruct.(sectionName).(fieldName));
        end


    end % Methods

end % classdef
