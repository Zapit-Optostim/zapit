function generateSupportReport(reportFname)
% Generate a .zip file containing a support report for Zapit
%
% function generateSupportReport(attemptLaunch,reportFname)
%
%
% Purpose
%  Saves useful install info to a zip file.
%
% Inputs
% reportFname - If provided, the report is written to this location. Otherwise a 
%               UI is presented to the user for a location to be chosed. 
% 
%
% Rob Campbell - SWC 2023


    %Generate default save location
    [~,userPath]=system('echo %USERPROFILE%');
    userDesktopDir = fullfile(userPath(1:end-1),'Desktop');
    defaultFname = ['Zapit_Report_',  datestr(now,'dd-mm-yyyy_HH-MM'),'.zip'];

    if nargin < 2 || isempty(reportFname)
        [reportFname,pathname] = uiputfile('.zip','Choose path to save report', fullfile(userDesktopDir,defaultFname));
        if reportFname==0
            return
        end

        reportFname = fullfile(pathname,reportFname);
    end


    % Log files to zip and delete
    filesToZip = {};
    tempFilesToDelete = {};

    [fpath,fname,fext] = fileparts(reportFname);
    if isempty(fpath)
        fpath = pwd;
    end

    if isempty(fname)
        fname = fullfile(userDesktopDir,defaultFname);
    end

    % Open a temporary text file into which we will dump a variety of general system information
    tmpTxtFileName = fullfile(tempdir,[fname '_system_details.txt']);
    tempFilesToDelete{end+1} = tmpTxtFileName;

    disp('Generating Zapit report...');
    wb = waitbar(0,'Generating Zapit report');


    % Add the Zapit commit sha to filesToZip
    gitInfo = zapit.updater.getGitInfo;
    if ~isempty(gitInfo)
        dumpToTXT(tmpTxtFileName, gitInfo);
    end

    waitbar(0.15,wb); drawnow

    % Record current path
    dumpToTXT(tmpTxtFileName, struct('matlabCurrentPath', path) );

    % Record MATLAB and Java versions
    dumpToTXT(tmpTxtFileName, struct('matlabVersion', version) );
    dumpToTXT(tmpTxtFileName, struct('javaVersion', version('-java')) );

    % Record Windows version
    [~,winVer] = system('ver');
    dumpToTXT(tmpTxtFileName, struct('WindowsVersion', winVer) );

    % Get memory info
    if ispc
        [~,sysMem] = memory;
        mem.TotalRAMinGB = sysMem.PhysicalMemory.Total / 1024^3;
        mem.AvailableRAMinGB = sysMem.PhysicalMemory.Available / 1024^3;
        dumpToTXT(tmpTxtFileName,mem)
    end

    % Get OpenGL information
    openGLInfo = opengl('data');
    dumpToTXT(tmpTxtFileName,openGLInfo)


    waitbar(0.5,wb); drawnow


    % Get current session history
    jSessionHistory = com.mathworks.mlservices.MLCommandHistoryServices.getSessionHistory;
    mSessionHistory = char(jSessionHistory);

    % Get current current text from the command window
    cmdWinDoc = com.mathworks.mde.cmdwin.CmdWinDocument.getInstance;
    jFullSession   = cmdWinDoc.getText(cmdWinDoc.getStartPosition.getOffset,cmdWinDoc.getLength);
    mFullSession = char(jFullSession);
  
    
    % Add the tmp file to the zip list
    filesToZip{end+1} = tmpTxtFileName;

    try
        %save separate files for convenience
        fn = fullfile(tempdir,'mSessionHistory.txt');
        fidt = fopen(fn,'w');
        arrayfun(@(x)fprintf(fidt,'%s\n', strtrim(mSessionHistory(x,:))),1:size(mSessionHistory,1));
        fclose(fidt);
        tempFilesToDelete{end+1} = fn;
        filesToZip{end+1} = fn;

        fn = fullfile(tempdir,'mFullSession.txt');
        fidt = fopen(fn,'w');
        fprintf(fidt,'%s', mFullSession);
        fclose(fidt);
        tempFilesToDelete{end+1} = fn;
        filesToZip{end+1} = fn;
    catch
    end


    % Copy the Zapit settings files
    waitbar(0.7,wb); drawnow
    settingsFname = zapit.settings.findSettingsFile;
    filesToZip{end+1} = settingsFname;


    waitbar(0.9,wb); drawnow

    % Zip important information
    fprintf('zipping files:\n')
    cellfun(@(x) fprintf(' %s\n',x), filesToZip)
    fprintf('\n')
    zip(reportFname, filesToZip);

    % Clean directory
    cellfun(@(f)delete(f),tempFilesToDelete);
    
    waitbar(1,wb);

    disp('Zapit report finished');

    delete(wb); % delete the waitbar
end % generateSupportReport




function dumpToTXT(fname,data)
    % Dump file to text file
    fid = fopen(fname,'a');
    if isstruct(data)
        f = fields(data);
        for ii=1:length(f)
            theseData = data.(f{ii});
            fprintf(fid,'%s - ', f{ii});
            if ischar(theseData)
                fprintf(fid,'%s\n',theseData);
            end
            if isnumeric(theseData)
                fprintf(fid,'%0.2f\n',theseData);
            end
        end
    else
        fprintf('Data are not a struct\n')
    end
    fclose(fid);
end % dumpToTXT
