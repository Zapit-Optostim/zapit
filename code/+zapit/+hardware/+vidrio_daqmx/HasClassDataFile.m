classdef HasClassDataFile < handle
    %% NOTES
    %
    %	TODO: ensureClassDataFileStatic() should perhaps ensure that all specified variables exist in any pre-existing CDF and add/initialize any that don't.
    %
    %% ************************************************************************
    
    % ClassData File Mechanism
    methods (Static, Hidden)
        function deleteClassDataFile(className)
            fname = getClassDataFileName(className);
            if exist(fname, 'file')
                delete(fname);
            end
        end
        
        function backupClassDataFileStatic(className)
            fname = getClassDataFileName(className);
            [p,f,e] = fileparts(fname);
            
            if exist(fname,'file')
                system(sprintf('copy /V "%s" /B "%s" /B',fname,fullfile(p,[f '_' datestr(now,30) e]))); %Backup to file with date/time stamp appended to filename
            end
        end
        
        function ensureClassDataFileStatic(className,initValStruct,classDataFileName)
            %Ensures that class data store exists for specified className (creating, if necessary)
            %    initValStruct: A struct specifying the class data 'variables' and their initial values
            %
            % NOTES (USAGE)
            %    * ensureClassData() OR ensureClassDataStatic() should be called once and only once in any class requiring a class data store
            %    * To implement a classData file store, generally either ensureClassData() is called from class constructor OR ensureClassDataStatic() is called from a static method
            %
            % NOTES (DEV)
            %    * At moment, there is no check to prevent a double call to ensureClassData() -- this would required of the classData.mat variables on every call
            %
            
            if nargin < 3 || isempty(classDataFileName)
                classDataFileName = getClassDataFileName(className);
            end
            
            %Ensure class data file exists, and create if needed
            if ~exist(classDataFileName, 'file')
                if ~exist(fileparts(classDataFileName),'dir')
                    mkdir(fileparts(classDataFileName));
                end
                save(classDataFileName,'-mat','-struct','initValStruct');
            else
                %Ensure all specified fields exist -- if not, add them
                lastwarn('');
                missingFields = setdiff(fieldnames(initValStruct),who('-file',classDataFileName));
                [~,warnID] = lastwarn;
                
                if isempty(warnID)
                    if ~isempty(missingFields)
                        tmp = struct();
                        for i=1:length(missingFields)
                            tmp.(missingFields{i}) = initValStruct.(missingFields{i});
                        end
                        save(classDataFileName,'-mat','-struct','tmp','-append');
                    end
                else % file is corrupted
                    zapit.hardware.vidrio_daqmx.ErrorHandler.logAndReportError('Class Data File %s is corrupt. Reverting to default.',replace(classDataFileName,'\','\\'));
                    save(classDataFileName,'-mat','-struct','initValStruct');
                end
            end
        end
        
        
        function val = getClassDataVarStatic(className,varName,classDataFileName,tfSearchSuperclasses)
            %Read classData variable, i.e. value stored in MAT file
            %maintained by class
            % className: Name of class whose classData file will be read
            % varName: Name of variable
            % tfSearchSuperclasses (optional): If true (the default), this
            % method starts at className and searches up its inheritance
            % hierarchy, returning the first 'hit'. The search order is that
            % returned by the 'superclasses' method (apparently
            % depth-first). If false, only the classData file for className
            % is considered.
            %
            % If no matching classData var is found, an error is thrown.
            
            if nargin < 3
                classDataFileName = [];
            end
            if nargin < 4
                tfSearchSuperclasses = true;
            end
            
            val = lclClassDataVarHelper(className,varName,classDataFileName,@nstedLoadVar,tfSearchSuperclasses&&isempty(classDataFileName));
            
            function v = nstedLoadVar(fn)
                tmp = load(fn,'-mat',varName);
                v = tmp.(varName);
            end
        end
        
        function setClassDataVarStatic(className,varName,val,classDataFileName,tfSearchSuperclasses)
            %Write classData variable, i.e. value stored in MAT file
            %maintained by class.
            % className: Name of class to whose classData file will be written
            % varName: Name of variable
            % val: Value to be set
            % tfSearchSuperclasses (optional): If true (the default), this
            % method starts at className and searches up its inheritance
            % tree, setting the first classData variable that matches
            % varName. The search order is that returned by the
            % 'superclasses' method (apparently depth-first). If false, this
            % method considers only the particular class className.
            %
            % If no matching classData var is found, an error is thrown.
            
            if nargin < 4
                classDataFileName = [];
            end
            if nargin < 5
                tfSearchSuperclasses = true;
            end
            
            tmp.(varName) = val;  %#ok<STRNU>
            lclClassDataVarHelper(className,varName,classDataFileName,@nstedSaveVar,tfSearchSuperclasses&&isempty(classDataFileName));
            function v = nstedSaveVar(fn)
                save(fn,'-mat','-struct','tmp','-append');
                v = [];
            end
        end
    end
    
    %% PROTECTED METHODS
    
    methods(Access=protected)
        function ensureClassDataFile(obj,initValStruct,classDataFileName,className)
            % Ensure that classData file store for specified class exists (creating, if necessary)
            % SYNTAX
            %   ensureClassDataFile(obj,initValStruct)
            %   ensureClassDataFile(obj,initValStruct,className)
            %
            %   initValStruct: A struct specifying the class data 'variables' and their initial values
            %   className: IF specified, the classData file will be associated with the specified className. If not, the class of the object is assumed.
            %              Typically, "mfilename('class')" is supplied for this argument, when used.
            %
            % NOTES (USAGE)
            %    * ensureClassData() OR ensureClassDataStatic() should be called once and only once in any class requiring a class data store
            %    * To implement a classData file store, generally either ensureClassData() is called from class constructor OR ensureClassDataStatic() is called from a static method
            narginchk(2,4);
            if nargin < 3
                classDataFileName = [];
            end
            if nargin < 4 || isempty(className)
                className = class(obj);
            end
            zapit.hardware.vidrio_daqmx.HasClassDataFile.ensureClassDataFileStatic(className,initValStruct,classDataFileName);
        end
        
        function backupClassData(obj,className)
            % Backup class data file for specified class, to duplicate file with date/time-stamp appended
            % SYNTAX
            % backupClassData(obj,className)
            %
            % className: IF specified, the classData file will be associated with the specified className. If not, the class of the object is assumed.
            %            Typically, "mfilename('class')" is supplied for this argument, when used.
            
            
            narginchk(1,2);
            
            if nargin == 1
                className = class(obj);
            end
            zapit.hardware.vidrio_daqmx.HasClassDataFile.backupClassDataFileStatic(className);
        end
        
        function val = getClassDataVar(obj,varName,classDataFileName,className)
            %Read classData variable, i.e. a value stored in MAT file maintained by class
            % SYNTAX
            %   val = getClassDataVar(obj,varName)
            %   val = getClassDataVar(obj,varName,className)
            %   If className is specified, getClassDataVar looks for
            %   varName in the classData variables for the specified class.
            %   When className is not specified, getClassDataVar starts at
            %   the class of obj and searches up its inheritance tree,
            %   returning the first matching classData variable. In either
            %   case, if no matching classData variable is found, [] is
            %   returned.
            %
            % NOTES
            %   The 'className' form should generally be used within abstract classes, or other classes that expect to be inherited from
            
            narginchk(2,4);
            if nargin < 3
                classDataFileName = [];
            end
            if nargin < 4 || isempty(className)
                className = class(obj);
                tfSearchSuperClasses = true;
            else
                tfSearchSuperClasses = false;
            end
            
            val = zapit.hardware.vidrio_daqmx.HasClassDataFile.getClassDataVarStatic(className,varName,classDataFileName,tfSearchSuperClasses);
        end
        
        function setClassDataVar(obj,varName,val,classDataFileName,className)
            %Write classData variable, i.e. value stored in MAT file maintained by class.
            % SYNTAX
            %   setClassDataVar(obj,varName,val)
            %   setClassDataVar(obj,varName,val,className)
            %
            %   className: If specified, setClassDataVar writes to the
            %   classData file for the specified class. Otherwise,
            %   setClassDataVar starts at the class of obj and searches up
            %   its inheritance tree, setting varName to be val in the
            %   first classData file found in which varName is a classData
            %   variable. In either case, if varName is not found as an
            %   existing classData variable, an error is thrown.
            %
            % NOTES
            %   The 'className' argument allows one to access classData file stores maintained by superclasses of the current object
            %   The 'className' form should generally be used within abstract classes, or other classes that expect to be inherited from
            
            narginchk(3,5);
            if nargin < 4
                classDataFileName = [];
            end
            if nargin < 5
                className = class(obj);
                tfSearchSuperClasses = true;
            else
                tfSearchSuperClasses = false;
            end
            zapit.hardware.vidrio_daqmx.HasClassDataFile.setClassDataVarStatic(className,varName,val,classDataFileName,tfSearchSuperClasses);
        end
    end
end

%% HELPER FUNCTIONS
function classDataFileName = getClassDataFileName(className)
classPrivatePath = zapit.hardware.vidrio_daqmx.util.className(className,'classPrivatePath');
classNameShort   = zapit.hardware.vidrio_daqmx.util.className(className,'classNameShort');

classDataFileName = fullfile(classPrivatePath, [classNameShort '_classData.mat']);
end


function result = lclClassDataVarHelper(clsName,varName,classDataFileName,fcn,tfSearchSuperclasses)
%Applies supplied function (fcn) to specified variable (varName) of
%specified class(es) (clsName), as well as those class(es)' superclasses
%(if tfSearchSuperclasses=true)

if tfSearchSuperclasses
    classlist = [{clsName};superclasses(clsName)];
else
    classlist = {clsName};
end

for c = 1:numel(classlist)
    if isempty(classDataFileName)
        fname = getClassDataFileName(classlist{c});
    else
        fname = classDataFileName;
    end
    if exist(fname,'file')==2
        s = whos('-file',fname,varName);
        if ~isempty(s)
            % the classData file exists, and it contains varName
            result = fcn(fname);
            return;
        end
    end
end

error('HasClassDataFile:ClassDataVarNotFound',...
    'Class data var ''%s'' not found for class ''%s''.',...
    varName,clsName);
end




% ----------------------------------------------------------------------------
% Copyright (C) 2022 Vidrio Technologies, LLC
% 
% ScanImage (R) 2022 is software to be used under the purchased terms
% Code may be modified, but not redistributed without the permission
% of Vidrio Technologies, LLC
% 
% VIDRIO TECHNOLOGIES, LLC MAKES NO WARRANTIES, EXPRESS OR IMPLIED, WITH
% RESPECT TO THIS PRODUCT, AND EXPRESSLY DISCLAIMS ANY WARRANTY OF
% MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
% IN NO CASE SHALL VIDRIO TECHNOLOGIES, LLC BE LIABLE TO ANYONE FOR ANY
% CONSEQUENTIAL OR INCIDENTAL DAMAGES, EXPRESS OR IMPLIED, OR UPON ANY OTHER
% BASIS OF LIABILITY WHATSOEVER, EVEN IF THE LOSS OR DAMAGE IS CAUSED BY
% VIDRIO TECHNOLOGIES, LLC'S OWN NEGLIGENCE OR FAULT.
% CONSEQUENTLY, VIDRIO TECHNOLOGIES, LLC SHALL HAVE NO LIABILITY FOR ANY
% PERSONAL INJURY, PROPERTY DAMAGE OR OTHER LOSS BASED ON THE USE OF THE
% PRODUCT IN COMBINATION WITH OR INTEGRATED INTO ANY OTHER INSTRUMENT OR
% DEVICE.  HOWEVER, IF VIDRIO TECHNOLOGIES, LLC IS HELD LIABLE, WHETHER
% DIRECTLY OR INDIRECTLY, FOR ANY LOSS OR DAMAGE ARISING, REGARDLESS OF CAUSE
% OR ORIGIN, VIDRIO TECHNOLOGIES, LLC's MAXIMUM LIABILITY SHALL NOT IN ANY
% CASE EXCEED THE PURCHASE PRICE OF THE PRODUCT WHICH SHALL BE THE COMPLETE
% AND EXCLUSIVE REMEDY AGAINST VIDRIO TECHNOLOGIES, LLC.
% ----------------------------------------------------------------------------
