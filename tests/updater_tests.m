classdef updater_tests < matlab.unittest.TestCase
    % Simple tests of the updater pipeline

    properties
        vStruct % version structure
    end %properties


    methods(TestClassSetup)
        function getVersion(obj)
            obj.vStruct = zapit.version;
        end
    end


    methods (Test)

        function versionStructReasonable(obj)
            v = obj.vStruct.version;
            obj.verifyClass(v.MAJOR,'double')
            obj.verifyClass(v.MINOR,'double')
            obj.verifyClass(v.PATCH,'double')
            obj.verifyClass(v.preReleaseString,'char')
            obj.verifyClass(v.string,'char')
        end

        function readVersionsFromFile(obj)
            % All lines in the file should have valid dates
            pathToFile = fullfile('updater_data','changelog_dates.txt');
            % How many lines contain data?
            fileLines=strsplit(fileread(pathToFile),'\n');
            numDataLines = sum(cellfun(@(x) length(x),fileLines)>0);

            [~,V] = zapit.updater.getVersionFromChangeLog(pathToFile);
            obj.verifyEqual(length(V),numDataLines)
        end

        function checkDateIsReasonable(obj)
            d = obj.vStruct.date;
            obj.verifyClass(d.year,'double')
            obj.verifyClass(d.month,'double')
            obj.verifyClass(d.day,'double')

            obj.verifyGreaterThanOrEqual(d.year,2023)
            obj.verifyGreaterThanOrEqual(d.month,1)
            obj.verifyLessThanOrEqual(d.month,12)
            obj.verifyGreaterThanOrEqual(d.day,1)
            obj.verifyLessThanOrEqual(d.day,31)
        end

        function versionMesssageReasonable(obj)
            % Check whether the zapit version is producing the output we expect
            msg = obj.vStruct.message;
            obj.verifyEqual(regexp(msg,'^Zapit version \d+\.\d+\.\d+  --  \d{4}/\d+/\d+'),1);
        end

        function checkInstallPath(obj)
            obj.verifyEqual(exist(zapit.updater.getInstallPath,'dir'),7)
        end

        function check_versionStringToStruct(obj)
            vString = 'v0.6.1-beta';
            actual = struct('MAJOR',0, 'MINOR',6, 'PATCH', 1, 'preReleaseString', '-beta', 'string', '0.6.1-beta');
            vStruct = zapit.updater.versionStringToStructure(vString);
            obj.verifyEqual(actual,vStruct);

            vString = '1.6.1-alpha';
            actual = struct('MAJOR',1, 'MINOR',6, 'PATCH', 1, 'preReleaseString', '-alpha', 'string', '1.6.1-alpha');
            vStruct = zapit.updater.versionStringToStructure(vString);
            obj.verifyEqual(actual,vStruct);

            vString = '120.6.1';
            actual = struct('MAJOR',120, 'MINOR',6, 'PATCH', 1, 'preReleaseString', '', 'string', '120.6.1');
            vStruct = zapit.updater.versionStringToStructure(vString);
            obj.verifyEqual(actual,vStruct);
        end

        function check_isVersionNewer(obj)
            reference = struct('MAJOR',0, 'MINOR',6, 'PATCH', 1, 'preReleaseString', '-beta');

            test = struct('MAJOR',0, 'MINOR',6, 'PATCH', 1, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,false);

            test = struct('MAJOR',0, 'MINOR',6, 'PATCH', 0, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,false);

            test = struct('MAJOR',0, 'MINOR',2, 'PATCH', 0, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,false);

            test = struct('MAJOR',0, 'MINOR',2, 'PATCH', 0, 'preReleaseString', '');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,false);

            test = struct('MAJOR',0, 'MINOR',2, 'PATCH', 10, 'preReleaseString', '');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,false);

            test = struct('MAJOR',0, 'MINOR',6, 'PATCH', 2, 'preReleaseString', '');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,true);

            test = struct('MAJOR',0, 'MINOR',6, 'PATCH', 2, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,true);

            test = struct('MAJOR',0, 'MINOR',7, 'PATCH', 1, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,true);

            test = struct('MAJOR',0, 'MINOR',7, 'PATCH', 0, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,true);

            test = struct('MAJOR',0, 'MINOR',7, 'PATCH', 10, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,true);

            test = struct('MAJOR',1, 'MINOR',0, 'PATCH', 0, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,true);

            test = struct('MAJOR',1, 'MINOR',5, 'PATCH', 0, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,true);

            test = struct('MAJOR',1, 'MINOR',5, 'PATCH', 10, 'preReleaseString', '-beta');
            isNewer = zapit.updater.isVersionNewer(reference,test);
            obj.verifyEqual(isNewer,true);
        end

    end %methods (Test)


    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    methods
        % These are convenience methods for running the tests
        function chanSamples  = loadChanSamples(obj);
            load(fullfile(obj.testDataDir,'chanSamples.mat'));
        end
    end



end %classdef zapit_build_tests < matlab.unittest.TestCase
