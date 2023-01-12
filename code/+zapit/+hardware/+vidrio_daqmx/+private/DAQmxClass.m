classdef DAQmxClass < zapit.hardware.vidrio_daqmx.APIWrapper & zapit.hardware.vidrio_daqmx.PDEPPropDynamic
    %DAQMXCLASS Abstract class representing a generic DAQmx 'class', i.e. a
    %level of DAQmx entity that has Get/Set and other methods, e.g. 'Task',
    %'Channel', 'Device', etc.
    %
    %% TODO:
    %   Look at APICallLocal() -- doesn't make too much sense as presently implemenented. Is it necessary as a method? It's only used by apiVersionDetectHookFcn().
    %    
    %% CHANGES
    %   VI120110A: When setting the 'ReadChannelsToRead' property call DAQmxResetReadChannelsToRead() first -- Vijay Iyer 12/1/10
    %   VI120110B: Handle properties which have known side effect of corrupting (at least sometimes) the readChannelsToRead property -- Vijay Iyer 12/1/10
    %   VI052611A: Revert VI120110A; NI fixed issue as of DAQmx 9.3 (CAR 277095) -- Vijay Iyer 5/26/11
    %
    % *************************************************************************

    %% ABSTRACT PROPERTY REALIZATIONS (zapit.hardware.vidrio_daqmx.APIWrapper)
    
    %Following MUST be supplied with non-empty values for each concrete subclass
    properties (Constant, Hidden)
        apiPrettyName = 'NI DAQmx';  %A unique descriptive string of the API being wrapped
        apiCompactName = 'NIDAQmx'; %A unique, compact string of the API being wrapped (must not contain spaces)
        
        apiSupportedVersionNames = getSupportedVersions(true); %A list of shorthand names for API versions supported by this wrapper class
        
        %Properties which can be indexed by version
        apiDLLNames = 'nicaiu'; %Either a single name of the DLL filename (sans the '.dll' extension), or a Map of such names keyed by values in 'apiSupportedVersionNames'
        apiHeaderFilenames = zlclInitAPIHeaderFilenames(); %Either a single name of the header filename (with the '.h' extension - OR a .m or .p extension), or a Map of such names keyed by values in 'apiSupportedVersionNames'
        
        apiCachedDataPath = [fileparts(mfilename('fullpath')) filesep 'private'];
    end
    
    %Following properties are sometimes supplied values by concrete subclasses, or they can be left empty when realized - in which case default values are used.
    properties (SetAccess=protected, Hidden)
        
        %API 'pre-fab' cached data variables
        apiStandardFuncRegExp; %Regular expression used to parse function prototypes and identify 'standard' functions of the API, about which standard API data (e.g. methodNargoutMap, responseCodeMap) will be stored. If not supplied, data will be stored for /all/ functions found in library.
        apiHasFuncNargoutMap; %<LOGICAL - Default=false> If true, 'funcNargoutMap' API data var is extracted from list of 'standard' functions, using extractFuncNargoutMap() method.
        
        %API response code handling
        apiResponseCodeSuccess = 0; %<NUMERIC> If specified, the first output argument of API 'standard' functions is taken to be a response code, with the specified response value(s) indicating call was successful.
        apiResponseCodeProcessor = 'apiResponseCodeHookFcn'; %<One of {'none', 'apiResponseCodeMapHookFcn','apiResponseCodeHookFcn', <responseCodeMap regular expression>} - Default = 'none'>
        
        apiResponseCodeMapExtractionType = 'none'; %<One of {'none', 'regexp', or 'method'} - Default = 'none'> If 'regexp' or 'function', the class has a 'responseCodeMap' API data var - a Map of response code names to response code values.
        
        %API 'custom' cached data variables
        apiCachedDataVarMap = containers.Map({'codeValueMap' 'codeNameMap'},{'extractDAQmxCodeMaps' 'extractDAQmxCodeMaps'}); %A Map whose keys (strings) specify custom class-specific data variables to store to API Data file, and whose values (strings) specify method names used to extract each of the 'apiCachedDataVars'. If same name is used for more than one variable, method is only invoked once.
        
        apiVersionDetectEnable = true; %<LOGICAL - Default=false> If true, indicates that subclass implements an 'apiVersionDetectHookFcn' method which performs auto-detection of API version installed on system, and returns apiCurrentVersion value. If false, the centrally maintained apiVersionData file is used for version specification of this API.
        
        apiHeaderRootPath = fullfile(fileparts(fileparts(mfilename('fullpath'))),'private');
        apiHeaderFinalPaths;
        apiHeaderPathStem;
        apiHeaderPlatformPaths = 'standard';

        apiDLLPaths; %DLL installed on installed system; not included with distribution
        apiDLLPlatformPaths;
        
        apiAuxFile1Names;
        apiAuxFile1Paths;
        
        apiAuxFile2Names;
        apiAuxFile2Paths;
        
    end
    
    %% ABSTRACT PROPERTY REALIZATIONS (zapit.hardware.vidrio_daqmx.PDEPProp)
    
    properties (Hidden, Constant)
        pdepSetErrorStrategy = 'setEmpty'; % <One of {'setEmpty','restoreCached','setErrorHookFcn'}>. setEmpty: stored property value becomes empty when driver set error occurs. restoreCached: restore value from prior to the set action generating error. setErrorHookFcn: The subclass implements its own setErrorHookFcn() to handle set errors in subclass-specific manner.
    end
    
    
    %% ABSTRACT PROPERTIES
    %Properties used to handle specifics of getting/setting properties for each DAQmx class
    properties (Abstract, SetAccess=private, Hidden)
        gsPropRegExp; %Cell array of regular expressions used to extract the properties for this particular DAQmx class
        gsPropPrefix; %Prefix before property name used during 'DAQmxGet/Set' calls, for this particular DAQmx class
        gsPropIDArgNames; %Cell array of argument names, specified as names of properties of this object, required for get/set calls for this particular DAQmx class
        gsPropNumStringIDArgs; %Number of string ID arguments, e.g. device or channel name. This is used to determine number of output arguments to discard (becaused shared library interface appends output arguments for every string input argument)
    end
    
    %% HIDDEN PROPERTIES 
    
    properties (Hidden,Constant)
        apiInstallationHeaderPath = zlclInitApiInstallationHeaderPath();
        apiInstallationHeaderFile = 'nidaqmx.h';        
    end            
    
    properties (SetAccess=private, Dependent)
        system; %Handle to the singleton System object -- makes this available to end user!
    end
    
    properties (Access=private, Dependent)
        apiPropTypeMap; %Map from (api property names) -> types
        userPropMap;   %Map from (user property names) -> (api property names)
        lowerPropMap;  %Map from (all lowercase prop names) -> (user property names)
    end
    
    properties (Access=private,Dependent)
        gsPropIDArgs;
    end
    
    %% ABSTRACT METHOD IMPLEMENTATIONS (zapit.hardware.vidrio_daqmx.PDEPPropDynamic)
    methods (Access=protected)
        function [tf, didyoumean, allProps] = pdepIsPropAddable(obj,propname)
            assert(ischar(propname) && ~isempty(propname));
            
            userPropNameMap = obj.userPropMap;
            lowerPropMap = obj.lowerPropMap;
            if userPropNameMap.isKey(propname)
                tf = true;
                didyoumean = [];
                allProps = [];
            elseif lowerPropMap.isKey(lower(propname))
                tf = false;
                didyoumean = lowerPropMap(lower(propname));
                allProps = [];
            else
                tf = false;
                didyoumean = [];
                allProps = userPropNameMap.keys();
            end
        end
    end
    
    %% ABSTRACT METHOD IMPLEMENTATIONS (zapit.hardware.vidrio_daqmx.PDEPProp)
    methods (Access=protected, Hidden)
        function pdepPropHandleGet(obj, src, evnt)
            obj.pdepPropGroupedGet(@obj.getDAQmxProperty, src, evnt);
        end
        
        function pdepPropHandleSet(obj, src, evnt)
            obj.pdepPropGroupedSet(@obj.setDAQmxProperty, src, evnt);            
        end
    end
    
    %% HOOK METHOD IMPLEMENTATIONS (zapit.hardware.vidrio_daqmx.APIWrapper)
    methods (Hidden)
        function apiCurrentVersion = apiVersionDetectHookFcn(obj)
            
            try
                
                majorVer = apiCallLocal('DAQmxGetSysNIDAQMajorVersion');
                minorVer = apiCallLocal('DAQmxGetSysNIDAQMinorVersion');
                
                if ismember('DAQmxGetSysNIDAQUpdateVersion',libfunctions(obj.apiDLLNames))
                    updateVer = apiCallLocal('DAQmxGetSysNIDAQUpdateVersion');
                else
                    updateVer = 0;
                end
                
                %primaryVersion = double(majorVer) + 0.1 * double(minorVer);
                
                %versionNum2NameMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
%                 versionNum2NameMap = containers.Map({1},{struct()}); versionNum2NameMap.remove(1);
%                 
% 				versionNum2NameMap(9.3) = '9.3.x';
%                 versionNum2NameMap(9.6) = '9.6.x';
%                 versionNum2NameMap(9.8) = '9.8.x';
%                 versionNum2NameMap(14.5) = '14.5.x';
%                 
%                 if ~versionNum2NameMap.isKey(primaryVersion)
%                     errorUnsupportedVersion();
%                 end
                
%                apiCurrentVersion = versionNum2NameMap(primaryVersion);

                apiCurrentVersion = sprintf('%d.%d.x',majorVer,minorVer);
                
                if ~ismember(apiCurrentVersion,getSupportedVersions(false));
                    errorUnsupportedVersion();
                end
                
%                 if ischar(apiCurrentVersion)
%                     return;
%                 elseif isa(apiCurrentVersion,'containers.Map')
%                     apiCurrentVersion = apiCurrentVersion(updateVer); %Use secondary map of updateVer to apiCurrentVersion string
%                 else
%                     error('Logical programming error');
%                 end
%                 
%                 return;
            catch ME
                if libisloaded(obj.apiDLLNames);
                    unloadlibrary(obj.apiDLLNames);
                end
                ME.rethrow();
            end
            
            
            function errorUnsupportedVersion()
                formattedVersion = sprintf('%d.%d.%d', majorVer, minorVer, updateVer);
                error('Version %s of the ''%s'' API is not supported', formattedVersion, obj.apiPrettyName);
            end
            
            
            %TODO: Update APIWrapper apiCallXXX mechanisms so they can be used in this 'pre-constructed' case
            function val = apiCallLocal(funcName)
                [status,val] = calllib(obj.apiDLLNames, funcName, 0); %Assumes apiDLLNames is a 'scalar'-string
                if status ~= obj.apiResponseCodeSuccess
                    error(' Failed to auto-detect version of ''%s''. Error status %d was encountered during call to ''%s''.', obj.apiPrettyName, status, funcName);
                end
            end
        end
        
        function responseCodeInfo = apiResponseCodeHookFcn(obj, responseCode)
            
            responseCodeInfo.errorName = num2str(responseCode);
            
            %Determine size of errorDescription
            errorDescriptionLength = obj.apiCallRaw('DAQmxGetErrorString', responseCode, libpointer(), 0);
            
            %Get errorDescription
            if errorDescriptionLength <= 0
                responseCodeInfo.errorDescription = '';
            else
                errorDescription = char(ones(1, errorDescriptionLength));
                responseCodeInfo.errorDescription = obj.apiCall('DAQmxGetErrorString', responseCode, errorDescription, errorDescriptionLength);
            end
            
            %Determine if warning or error
            responseCodeInfo.warningOnly = responseCode > 0;
            
        end
        
    end
    
    
    %% CONSTRUCTOR/DESTRUCTOR
    methods
        
    end
    
    %% PROPERTY ACCESS METHODS
    methods (Hidden)
        
        function val = getDAQmxProperty(obj, ourPropName, returnEmptyResponseCodes)
            
            if nargin < 3
                returnEmptyResponseCodes = [];
            end
            
            map = obj.userPropMap;
            assert(map.isKey(ourPropName));
            devPropName = map(ourPropName); % go from user convention to DAQmx convention
            
            %Determine property arguments to use, based on data type of property
            mightNeedDecode = false;
            
            assert(obj.apiPropTypeMap.isKey(devPropName));
            switch obj.apiPropTypeMap(devPropName)
                case 'cstring'
                    maxStringLength = 2048;
                    propArgs{1} = repmat('a', [1 maxStringLength]); %Al
                    propArgs{2} = maxStringLength;
                case {'longPtr' 'int32Ptr'}
                    mightNeedDecode = true;
                    propArgs{1} = 0;
                otherwise %A numeric type; definitely not one with a code
                    propArgs{1} = 0; %All other types can be handled by a numeric double type (even if integer-valued)
            end
            
            %Determine number of output arguments, including those to discard
            outArgs = cell(obj.gsPropNumStringIDArgs + 1, 1);
            
            %Get the property
            [responseCode, outArgs{:}] = obj.apiCallRaw(['DAQmxGet' obj.gsPropPrefix devPropName], obj.gsPropIDArgs{:}, propArgs{:}); %This will throw an error, if DAQmx complains
            if ismember(responseCode, returnEmptyResponseCodes) %response codes which can be handled gracefully
                val = [];
            elseif ~ismember(responseCode, [obj.apiResponseCodeSuccess obj.apiFilteredResponseCodes])
                obj.apiProcessErrorResponseCode(responseCode, ['DAQmxGet' obj.gsPropPrefix devPropName]);
                val = [];
            else
                val = outArgs{end};
            end
            
            %Decode property if needed
            %This is a crude, somewhat risky heuristic -- some property
            %values are integer values that might incidentally overlap a code value           
            if mightNeedDecode && ~isempty(val) && val >= 10000 %All attribute encodings (except AI resistance encoding) are values above 10000
                codeName = obj.decodePropVal(val);
                if ~isempty(codeName)
                    val = codeName;
                end
            end
            
            %Return scalar numerics as doubles
            if isnumeric(val) && isscalar(val)
                val = double(val);
            end
        end
        
        function setDAQmxProperty(obj, ourPropName, val)
            
            map = obj.userPropMap;
            assert(map.isKey(ourPropName));
            devPropName = map(ourPropName); % go from user convention to DAQmx convention
            
            %Determine if value must be encoded, based on data type of property
            if ischar(val) && any(strcmpi(obj.apiPropTypeMap(devPropName), {'longPtr','int32Ptr'}))
                setValEncoded = obj.encodePropVal(val);
                if ~isempty(setValEncoded)
                    val = setValEncoded;
                end
                %TODO: Flag cases for which encode fails, to notify that subsequent errors /may/ be due to incorrect spelling of code, etc
            end
            
            %First check if there is a DAQmx setter (i.e. not a read-only property)
            %           setFuncName = ['DAQmxSet' obj.gsPropPrefix devPropName];
            %             if ~ismember(setFuncName, libfunctions(obj.apiDLLName)) %Could maintain a list of all setter functions, to speed this
            %                 error(['Property ' devPropName ' is read-only. Cannot be set.']);
            %             end
            
            try 
                setFuncName = ['DAQmxSet' obj.gsPropPrefix devPropName];
                obj.apiCall(setFuncName, obj.gsPropIDArgs{:}, val);
            catch ME
                if strcmpi(ME.identifier,'MATLAB:UndefinedFunction')
                    error(['Property ' devPropName ' is read-only. Cannot be set.']);
                else
                    ME.rethrow();
                end
            end
        end
        
        function tf = isValidName(obj,name)
            % https://www.ni.com/documentation/en/ni-daqmx/latest/mxcncpts/namechantask/
            tf = ischar(name);
            tf = tf && ~isempty(strtrim(name));
            tf = tf && ~isempty(regexpi(name,'^[0-9a-z\x7f-\xff -]+[0-9a-z\x7f-\xff -_]*$','match','once')); %\x7f-\xff allows some special characters e.g. German Umlaute
        end
    end

    methods
        function sys = get.system(obj) %#ok
            sys = zapit.hardware.vidrio_daqmx.System.getHandle();
        end
        
        function idArgs = get.gsPropIDArgs(obj)
            %Determines arguments to use to identify entity whose property to get/set
            
            idArgs = cell(length(obj.gsPropIDArgNames), 1);
            for i=1:length(idArgs)
                idArgs{i} = eval(['obj.' obj.gsPropIDArgNames{i}]); %Use eval' because dynamic property referencing does not allow multiple fields (e.g. 'task.taskID')
            end
        end
        
        function map = get.apiPropTypeMap(obj)
            map = obj.getPropertyMaps();
        end
        
        function map = get.userPropMap(obj)
            [~, map] = obj.getPropertyMaps();
        end
        
        function map = get.lowerPropMap(obj)
            [~, ~, map] = obj.getPropertyMaps();
        end
        
    end
    
    %Help methods to property access methods
    methods (Access=protected)
        function [apiPropTypeMap userPropNameMap lowerPropMap] = getPropertyMaps(obj)
            
            [apiPropTypeMap userPropNameMap lowerPropMap] = ...
                zapit.hardware.vidrio_daqmx.private.DAQmxClass.accessPropertyMaps(class(obj));
            assert(isempty(apiPropTypeMap) == isempty(userPropNameMap));
            assert(isempty(apiPropTypeMap) == isempty(lowerPropMap));
            
            if isempty(apiPropTypeMap)
                prototypes = libfunctions(obj.apiDLLName, '-full');
                
                regexprs_ = obj.gsPropRegExp; % cache in case gsPropRegExp has a get method
                varTypes = cell(1,length(regexprs_));
                for idx = 1:length(regexprs_)
                    [~,varTypes{idx}] = regexp(prototypes, regexprs_{idx}, 'tokens', 'names', 'once');
                end
                varTypes = vertcat(varTypes{:});
                
                varTypes = cat(1,varTypes{:}); %Concatenate into a struct array
                apiPropNames  = {varTypes.varName}';
                apiPropTypes  = {varTypes.varType}';
                userPropNames = cell(size(apiPropNames));
                lowerNames    = cell(size(apiPropNames));
                for c = 1:numel(apiPropNames)
                    userPropNames{c} = obj.standardizePropName(apiPropNames{c});
                    lowerNames{c}    = lower(apiPropNames{c});
                end
                
                % Create + store maps
                apiPropTypeMap  = containers.Map(apiPropNames, apiPropTypes);
                userPropNameMap = containers.Map(userPropNames, apiPropNames);
                lowerPropMap    = containers.Map(lowerNames, userPropNames);
                zapit.hardware.vidrio_daqmx.private.DAQmxClass.accessPropertyMaps(class(obj), apiPropTypeMap, userPropNameMap, lowerPropMap);
            end
            
        end
    end       
    
    %Methods made available all the subclasses
    methods (Access=protected)
        
        function outVal = getQuiet(obj, varargin)
            %A getter which does not add dynamically created properties to the object following the get
            
            needToDelete = cellfun(@(propName)isempty(findprop(obj, propName)), varargin); %Find properties that didn't exist with object prior to operation
            outVal = get(obj, varargin{:});
            
            for i=1:length(varargin)
                if needToDelete(i)
                    delete(findprop(obj, varargin{i}));
                end
            end
        end
    end
    
    %% PUBLIC METHODS
    
    methods
        function reset(obj,propName)
            map = obj.userPropMap;
            assert(map.isKey(propName));
            devPropName = map(propName); % go from user convention to DAQmx convention 
            
            obj.apiCall(sprintf('DAQmxReset%s%s', obj.gsPropPrefix,devPropName),obj.gsPropIDArgs{:});            
        end
    end
    
    %% PRIVATE/PROTECTED METHODS
    methods (Hidden)
        function codeMapStruct = extractDAQmxCodeMaps(obj)
            codeMapStruct = struct();
            
            [codeNameMap, codeValueMap] = obj.extractCodeMap('#define\s*(DAQmx_Val_\w*)\s*([^/]*)', fullfile(obj.apiInstallationHeaderPath,obj.apiInstallationHeaderFile));
            
            codeMapStruct.codeNameMap = codeNameMap;
            codeMapStruct.codeValueMap = codeValueMap;
        end
    end
    
    methods (Access=protected)        
        function codeVal = encodePropVal(obj, codeName)
            %Extract value for DAQmx driver code name
            
            try
                codeNameMap = obj.accessAPIDataVar('codeNameMap');
                
                assert(ischar(codeName) && isvector(codeName),'One argument was expected to be a string, but argument supplied was of another type.');
                assert(codeNameMap.isKey(codeName),'Specified argument value (''%s'') is not recognized',codeName);
                
                codeVal = codeNameMap(codeName);
            catch ME
                ME.throwAsCaller();
            end
        end
        
        function codeName = decodePropVal(obj, codeVal)
            %Extract name for DAQmx driver code value
            
            codeValueMap = obj.accessAPIDataVar('codeValueMap');
            if codeValueMap.isKey(codeVal)
                codeName = codeValueMap(codeVal);
            else
                codeName = '';
            end
        end
	end
	
	%% METHOD OVERRIDES (zapit.hardware.vidrio_daqmx.APIWrapper)
	methods (Access=protected)
		function smartLoadLibrary(obj)
			
			%Paradoxically, disable accelerator to speed up loadlibrary
			%performance (workaround recommended per TMW Service Request
			%1-C76DED)
			accelState = feature('accel');
			feature('accel',0);
			smartLoadLibrary@zapit.hardware.vidrio_daqmx.APIWrapper(obj);
			feature('accel',accelState); %Restore initial accelerator state											 
		end        
	end

    %% STATIC METHODS
    methods (Static, Hidden)        
        function [apiPropTypeMap userPropNameMap lowerPropMap] = ...
                accessPropertyMaps(className, apiPropTypeMapInput, userPropNameMapInput, lowerPropMapInput)
            %Function to store and retrieve property maps for each class
            
            %Local memory store maintains one apiPropTypeMap and userPropNameMap for each concrete subclass for which this property is requested
            
            persistent lclPropMaps;
            if isempty(lclPropMaps)
                lclPropMaps = containers.Map(); % key: className. val: struct with fields 'apiPropTypeMap','userPropNameMap','lowerPropMap'
            end
            
            switch nargin
                case 1
                    if lclPropMaps.isKey(className)
                        tmp = lclPropMaps(className);
                        apiPropTypeMap = tmp.apiPropTypeMap;
                        userPropNameMap = tmp.userPropNameMap;
                        lowerPropMap = tmp.lowerPropMap;
                    else
                        apiPropTypeMap = [];
                        userPropNameMap = [];
                        lowerPropMap = [];
                    end
                case 4
                    assert(isa(apiPropTypeMapInput, 'containers.Map'));
                    assert(isa(userPropNameMapInput, 'containers.Map'));
                    assert(isa(lowerPropMapInput, 'containers.Map'));
                    tmp.apiPropTypeMap = apiPropTypeMapInput;
                    tmp.userPropNameMap = userPropNameMapInput;
                    tmp.lowerPropMap = lowerPropMapInput;
                    lclPropMaps(className) = tmp;
                    assert(nargout==0);
                otherwise
                    assert(false);
            end
        end
    end
end

%% LOCAL FUNCTIONS

function supportedVersions = getSupportedVersions(build)
    binfolder = fullfile(fileparts(fileparts(mfilename('fullpath'))),'private');
    hPathChanger = zapit.hardware.vidrio_daqmx.util.PathChanger(binfolder);

    try        
        exist('getDAQmxVersion','file'); % workaround for weired bug in Matlab 2015b can't find getDAQmxVersion on first call
        exist('getSupportedDAQmxVersions','file'); % workaround for weired bug in Matlab 2015b can't find getSupportedDAQmxVersions on first call
        getSupportedDAQmxVersions();
        supportedVersions = getSupportedDAQmxVersions();

        [majorVer,minorVer,updateVer] = getDAQmxVersion();
        
        if ~isempty(majorVer)
            versionString = sprintf('%d.%d.x',majorVer,minorVer);
            if~ismember(versionString,supportedVersions) && build
                str = input(sprintf(...
                    ['NI DAQmx: Binaries for DAQmx version %d.%d.x %s not included in distribution.\n',...
                    'Do you want to attempt to compile for this version? [Y/N] '],...
                    majorVer,minorVer,computer('arch')),'s');
                
                if strcmpi(str,'y')
                    exist('make','file'); % workaround for weired bug in Matlab 2015b can't find make on first call
                    make();
                end
            end
        end
        
        supportedVersions = getSupportedDAQmxVersions(); % double check if build was successful
        zapit.hardware.vidrio_daqmx.idioms.safeDeleteObj(hPathChanger);
    catch ME
       zapit.hardware.vidrio_daqmx.idioms.safeDeleteObj(hPathChanger);
       rethrow(ME);
    end
end

function hMap = zlclInitAPIHeaderFilenames()

supportedVersions = getSupportedVersions(false);
headerNames = repmat({'NIDAQmx_proto.m'},1,length(supportedVersions));
hMap = containers.Map(supportedVersions,headerNames);
end

function p = zlclInitApiInstallationHeaderPath()

% switch lower(computer)
%     case 'pcwin'
%         pfDir = 'program files';
%     case 'pcwin64'
%         pfDir = 'program files (x86)';
%     otherwise
%         assert(false);
% end

pfx86 = fullfile(zapit.hardware.vidrio_daqmx.idioms.startPath,'program files (x86)');
pf    = fullfile(zapit.hardware.vidrio_daqmx.idioms.startPath,'program files');

if isdir(pfx86)
    pfPath = pfx86;
elseif isdir(pf)
    pfPath = pf;
else
    assert(false);    
end

p = fullfile(pfPath,'national instruments','ni-daq','daqmx ansi c dev','include');

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
