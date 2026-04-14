function sequence = wurOnSymSequence(dataRate,cfgFormat,varargin)
%wurOnSymSequence WUR MC-OOK On symbol sequence
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   sequence = wurOnSymSequence(dataRate,cfgFormat) generates the sequence
%   used for the construction of MC-OOK On symbol.
%
%   SEQUENCE is a non-zero vector of normalized sequence used for the
%   construction of the MC-OOK On symbol.
%
%   DATARATE specifies the transmission rate as character vector or string
%   and must be 'LDR', or 'HDR'.
%
%   CFGFORMAT is the format configuration object of type <a
%   href="matlab:help('wlanWURConfig')">wlanWURConfig</a>,
%   which specifies the parameters for the WUR PPDU format.
%
%   sequence = wurOnSymSequence(...,subchannelIndex) generates the sequence
%   used for the construction of MC-OOK On symbol.
%
%   SUBCHANNELINDEX indicates the subchannel index for CBW20, CBW40 and 
%   CBW80 and must be between 1 and 4 inclusive.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

subchannelIndex = 1;
if nargin>2
    subchannelIndex = varargin{1};
end

switch cfgFormat.Subchannel{subchannelIndex}.SymbolDesign
    % IEEE P802.11ba/D8.0, December 2020, Table AC-1 and Table AC-2
    case 'Example1'
        sequenceHDR = [1 0 -3 0 -3 0 0 0 -3 0 -3 0 1].'/sqrt(6.333);
        sequenceLDR = [-1 1 1 1 -1 1 0 -1 -1 -1 1 -1 -1].';
    case 'Example2'
        sequenceHDR = [3+7i 0 1+15i 0 -5+13i 0 0 0 13-5i 0 -15-1i 0 7+3i].'/sqrt(159.333);
        sequenceLDR = [1+1i -1+1i -1+1i 1+1i -1+1i 1-1i 0 1+1i 1+1i 1-1i 1+1i -1-1i -1+1i].'/sqrt(2);
    case 'Example3'
        sequenceHDR = [3+5i 0 -7+5i 0 -7-5i 0 0 0 -5+1i 0 7+7i 0 5-5i].'/sqrt(59.333); % The scaling factor (denominator) is changed from D8.0 to be scaled to the unit power
        sequenceLDR = [-1+1i 1+1i -1+1i 1+1i -1-1i 1-1i 0 1-1i 1+1i -1-1i -1-1i 1+1i 1+1i].'/sqrt(2);
    otherwise % User-defined
        sequenceHDR = cfgFormat.Subchannel{subchannelIndex}.HDRSequence.';
        sequenceLDR = cfgFormat.Subchannel{subchannelIndex}.LDRSequence.';
end

switch dataRate
    % Extract the sequence at the corresponding subcarrier indices k 
    % defined in IEEE P802.11ba/D8.0, December 2020, Section 30.3.4.1 and 30.3.4.2
    case 'LDR'
        % k = (-6 -5, ... -1, 1, 2, ... 6)
        sequence = sequenceLDR([1 2 3 4 5 6 8 9 10 11 12 13]);       
    otherwise % HDR
        % k = (-6, -4, -2, 2, 4, 6)
        sequence = sequenceHDR([1 3 5 9 11 13]);
end

end

