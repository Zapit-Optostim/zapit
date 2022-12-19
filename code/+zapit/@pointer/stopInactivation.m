function stopInactivation(obj)
    % called at the end of a trial
    % send 0 Volts if sample generation has already been triggered
    % and stops task
    
    % TODO -- this method we will change to allow for the ramp-down
    try
        % try-end used because overwriting buffer before trigger
        % comes (e.g. run abort before inactivation) may throw errors
        
        voltChannel(:,1:2) = obj.chanSamples.light(:,[1 1],1); % just zeros
        voltChannel(:,3:4) = obj.chanSamples.light(:,[1 1],1); % just zeros
        
        obj.DAQ.hC.writeAnalogData(voltChannel);
        
        % pause to wait for 0s to be updated in the buffer and
        % generated before closing
        pause(1);
    end
    
    % stop task and send to pre-generation stage, allowing to write
    % next trial samples without conflicts
    obj.DAQ.hC.abort
end % stopInactivation

