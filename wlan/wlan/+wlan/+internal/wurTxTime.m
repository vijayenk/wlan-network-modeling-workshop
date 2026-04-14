function params = wurTxTime(cfgFormat)
%wurTxTime WUR transmission time
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PARAMS = wurTxTime(cfgFormat) returns WUR parameters as per IEEE
%   P802.11ba/8.0, December 2020.
%
%   The output structure PARAMS contains the following fields:
%
%   TXTIME            - Transmission time in ns
%   LSIGLength        - L_LENGTH in L-SIG field
%   NSYM              - Number of MC-OOK symbols per 20 MHz subchannels as
%                       vector of length 1-by-NumSubchannels
%   NPad              - Number of padding bits per 20 MHz subchannels as
%                       vector of length 1-by-NumSubchannels
%   ActiveSubchannels - Index of active subchannels
%   PSDULength        - PSDULength per subchannel as a vector of length
%                       1-by-NumSubchannels
%
%   CFGFORMAT is the format configuration object of type <a
%   href="matlab:help('wlanWURConfig')">wlanWURConfig</a>,
%   which specifies the parameters for the WUR PPDU format.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

numSubchannels = cfgFormat.NumSubchannel;
txTime = zeros(1,numSubchannels);
lsigLength = zeros(1,numSubchannels);
NSym = zeros(1,numSubchannels);
TWURSyncData = zeros(1,numSubchannels);
psduLength = zeros(1,numSubchannels);

% Skip the calculation for punctured subchannels
activeSubchannels = getActiveSubchannelIndex(cfgFormat);

for i=1:length(activeSubchannels)
    subCh = activeSubchannels(i);
    p = wlan.internal.wurSymbolParameters(cfgFormat.Subchannel{subCh}.DataRate);
    t = wlan.internal.wurTimingRelatedConstants(cfgFormat.Subchannel{subCh}.DataRate);

    % IEEE P802.11ba/D8.0, December 2020, Equation 30-14
    NSym(subCh) = 8*cfgFormat.Subchannel{subCh}.PSDULength*p.NSPDB;

    % IEEE P802.11ba/D8.0, December 2020, Equation 30-13
    txTime(subCh) = t.TLSTF+t.TLLTF+t.TLSIG+t.TBPSKMark1+t.TBPSKMark2+t.TWURSync+t.TSym*NSym(subCh);

    % IEEE P802.11ba/D8.0, December 2020, Equation 30-16
    lsigLength(subCh) = (txTime(subCh)-20e3)/4e3*3-3; % TXTIME in ns

    % Length of Sync and Data fields per 20 MHz subchannel
    TWURSyncData(subCh) = t.TWURSync+t.TSym*NSym(subCh);

    % PSDULength
    psduLength(subCh) = cfgFormat.Subchannel{subCh}.PSDULength;
end

txTime = max(txTime);
lsigLength = max(lsigLength);
maxTWURSyncData = max(TWURSyncData);
% IEEE P802.11ba/D8.0, December 2020, Equation 30-11
NPad = (maxTWURSyncData-TWURSyncData)*1e-3/4; % Convert ns to us

params = struct('TXTIME', txTime, ...
                'LSIGLength', lsigLength, ...
                'NSYM', NSym, ...
                'NPad', NPad, ...
                'ActiveSubchannels', activeSubchannels, ...
                'PSDULength', psduLength);
end