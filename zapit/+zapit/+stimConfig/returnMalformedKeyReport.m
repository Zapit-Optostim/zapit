function msg = returnMalformedKeyReport(fname)
    % Report duplicate or non-sequential stimLocations keys in a stim config file
    %
    % msg = zapit.stimConfig.returnMalformedKeyReport(fname)
    %
    % Purpose
    % Stimulus conditions are stored as fields named stimLocations01, stimLocations02, and
    % so on. Two kinds of malformed key sequence cause conditions to be silently lost:
    %
    % 1. Duplicate keys. Two blocks with the same name (e.g. two "stimLocations15:") can not
    %    both survive: a MATLAB struct can only hold one field of that name, so ReadYaml
    %    keeps the last and the earlier condition vanishes. This has actually shipped in an
    %    example file, where a load-then-save quietly dropped a condition.
    % 2. Gaps. loadConfig walks stimLocations01, 02, ... and stops at the first missing
    %    index, so a file numbered 01,02,04 loads only two conditions and everything from
    %    the gap onward is ignored.
    %
    % Neither is detectable after ReadYaml (in the duplicate case the field is already
    % gone), so we scan the raw file text. A config with either problem is refused by
    % zapit.pointer.loadStimConfig rather than loaded incomplete.
    %
    % Inputs
    % fname - path to the stim config file to scan
    %
    % Outputs
    % msg - empty if the keys are well formed. Otherwise a human-readable description of
    %       what is wrong, suitable for printing to the CLI.
    %
    %
    % Rob Campbell - SWC 2026
    %
    % See also
    % zapit.pointer.loadStimConfig


    msg = '';

    if ~exist(fname,'file')
        return
    end

    % Read the raw text: duplicates are invisible once the YAML has been parsed
    fid = fopen(fname,'r');
    if fid < 0
        return
    end
    txt = fread(fid,'*char')';
    fclose(fid);

    % Find all top-level stimLocationsNN keys, in file order
    tok = regexp(txt, '(?m)^stimLocations(\d+)\s*:', 'tokens');
    if isempty(tok)
        return % No conditions found. Not this function's problem to report.
    end

    ind = cellfun(@(x) str2double(x{1}), tok);

    % 1. Duplicates
    uniqueInd = unique(ind);
    if length(uniqueInd) < length(ind)
        duplicated = uniqueInd(arrayfun(@(x) sum(ind==x)>1, uniqueInd));
        msg = sprintf(['File contains duplicate stimLocations key(s): %s. Each condition ', ...
            'must have a unique number, otherwise conditions are silently lost when the ', ...
            'file is read.'], mat2str(duplicated));
        return
    end

    % 2. Gaps / not starting at 1. Keys must run 1..N with nothing missing.
    expected = 1:length(ind);
    if ~isequal(sort(ind(:))', expected)
        missing = setdiff(expected, ind);
        if isempty(missing)
            msg = sprintf(['stimLocations keys are not numbered sequentially from 1 ', ...
                '(found: %s).'], mat2str(sort(ind(:))'));
        else
            msg = sprintf(['stimLocations keys are not sequential: %s missing (found: %s). ', ...
                'Conditions after a gap are silently ignored when the file is read.'], ...
                mat2str(missing), mat2str(sort(ind(:))'));
        end
        return
    end

end % returnMalformedKeyReport
