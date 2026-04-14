function [k,pk] = dmgTonePairingIndices(varargin)
%dmgTonePairingIndices k and Pk indices for static or dynamic tone pairing
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [K,PK] = tonesPairingIndices() returns K and PK for static tone
%   mapping. Note the indices are 0-based as per the standard.
%
%   [K,PK] = tonesPairingIndices(TONEPAIRINGTYPE,GROUPPAIRINDEX) returns K
%   and PK for dynamic or static tone mapping. Note the indices are 0-based
%   as per the standard.
%
%   K and PK are indices used to map tone pairs. They are of size 168-by-1,
%   where 168 is the number of data tones in each half of the OFDM symbol.
%
%   TONEPAIRINGTYPE is a character vector and must be either 'Dynamic' or
%   'Static'.
%
%   GROUPPAIRINDEX is a 42-by-1 vector of group pair indices for dynamic
%   tone pairing.

%   Copyright 2016 The MathWorks, Inc.

%#codegen

narginchk(0,2);

if nargin>0
    tonePairingType = varargin{1};
else
    tonePairingType = 'Static';
end

ofdm = wlan.internal.dmgOFDMInfo();
k = (0:(ofdm.NSD/2-1)).';

% Indices for mapping to subcarriers with static or dynamic tone pairing
if strcmp(tonePairingType,'Dynamic')
    narginchk(2,2);
    groupPairIndex = varargin{2}; % index with l=0,1,2,...,(NSD/NTPG-1)
    
    % Dynamic tone pairing, IEEE 802.11ad-2012 Section 21.5.3.2.4.6.3
    NG = 42; % Number of DTP groups
    NTPG = (ofdm.NSD/2)/(NG); % Number of tones per group

    toneIndexOffset = NTPG*groupPairIndex+ofdm.NSD/2;
    pk = toneIndexOffset(floor(k/NTPG)+1)+mod(k,NTPG);
else
    % Static tone pairing, IEEE 802.11ad-2012 Section 21.5.3.2.4.6.2
    pk = k+ofdm.NSD/2;
end
end