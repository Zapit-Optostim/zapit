function makeTTLpulse(DAQ)
    % Flip digital transiently line on and off, generating a TTL pulse
    %
    % makeTTLpulse(DAQ)
    %
    % Purpose
    % Generate a rapid TTL pulse from a DAQ.
    %
    % Inputs
    % DAQ - the output of connectAuxDaq
    %
    % Rob Campbell - SWC 2023




    DAQ.dWriter.WriteSingleSampleSingleLine(true,false)
    DAQ.dWriter.WriteSingleSampleSingleLine(true,true)
    DAQ.dWriter.WriteSingleSampleSingleLine(true,false)
