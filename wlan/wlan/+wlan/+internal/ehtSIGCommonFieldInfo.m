function s = ehtSIGCommonFieldInfo(cbw,mode,NDBPS,isNDP)
%ehtSIGCommonFieldInfo EHT-SIG common field information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   S = ehtSIGCommonFieldInfo(CBW,MODE,NDBP,ISNDP) returns the EHT-SIG
%   common field information for an EHT MU or NDP packet format for a given
%   channel bandwidth, compression mode and NDBPS.
%
%   The output structure S has the following fields:
%
%   NumCommonFieldBits    - Number of common field bits
%   NumCommonFieldSamples - Number of common field samples
%   NumCommonFieldSymbols - Number of common field symbols
%   NumContentChannels    - Number of content channels

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen

numCRCBits = 4; % Number of CRC bits in EHT-SIG common field
numTailBits = 6; % Number of Tail bits in EHT-SIG common field
switch cbw
    case 20
        numContentChannels = 1;
    otherwise
        numContentChannels = 2;
end

% Number of content channel is 1 for NDP or SU-MIMO (compressedMode-1)
if mode==1 % NDP or SU-MIMO
    numContentChannels = 1;
end
N = 0; % For codegen
M = 0; % For codegen
if mode==0
    % For OFDMA, get number of RU allocation subfields, N and M
    [N,M] = wlan.internal.ehtSIGNumAllocationSubfields(cbw);
end

switch mode
    case 0 % OFDMA
        % Common filed includes CRC and tail for 1 or 2 encoding blocks
        numCommonFieldBits = 16+9*N+numCRCBits+numTailBits+1+9*M+(numCRCBits+numTailBits)*(M~=0);
    otherwise % SU, NDP, MU-MIMO
        if isNDP
            % Common field includes U-SIG overflow and CRC and tail (IEEE P802.11be/D3.0 Figure 36-35)
            numCommonFieldBits = 16+numCRCBits+numTailBits; % IEEE P802.11be/D3.0, Table 36-37
        else % MU-MIMO, non-OFDMA
            % Common field does not include 1 user field nor CRC and tail
            numCommonFieldBits = 20; % IEEE P802.11be/D3.0, Table 36-36.
        end
end

numSamplesPerSym = (cbw/20)*80;
commonFieldSamples = ceil(numCommonFieldBits/NDBPS)*numSamplesPerSym;
symLength = 4*cbw; % Number of symbols in time domain
numCommonFieldSymbols = commonFieldSamples/symLength;

s = struct( ...
    'NumCommonFieldBits', numCommonFieldBits, ...
    'NumCommonFieldSamples', commonFieldSamples, ...
    'NumCommonFieldSymbols', numCommonFieldSymbols, ...
    'NumContentChannels', numContentChannels);
end