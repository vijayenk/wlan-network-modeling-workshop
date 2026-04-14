function s = heSIGBCommonFieldInfo(chanBW,NDBPS)
%heSIGBCommonFieldInfo HE SIG-B field information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   S = heSIGBCommonFieldInfo(CHANBW,NDBPS) returns the information for
%   HE-SIG-B common field for the given channel bandwidth and the number of
%   data bits per symbol. The output structure S has the following fields:
%   
%   NumCommonFieldBits      - Number of common field bits
%   NumCommonFieldSamples   - Number of common field samples
%   NumCommonFieldSymbols   - Number of common field symbols
%   NumContentChannels      - Number of content channels
%   NumRUAllocationSubfield - RU allocation subfield
%   NumCRCBits              - Number of CRC bits
%   NumTailBits             - Number of tail bits
%   Center26ToneBit         - Indication of Center26Tone

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

numCRCBits = 4; % Number of CRC bits in HE-SIG-B common field
numTailBits = 6; % Number of Tail bits in HE-SIG-B common field

switch chanBW
   case 20
       numContentChannels = 1;
       center26ToneBit = 0; % No center bit
       N = 1; % RU allocation subfield, Table 27-24, IEEE Std 802.11ax-2021
   case 40
       numContentChannels = 2;
       center26ToneBit = 0; % No center bit
       N = 1;
   case 80
       numContentChannels = 2;
       center26ToneBit = 1; % Center bit
       N = 2;
   otherwise % 160MHz
       numContentChannels = 2;
       center26ToneBit = 1; % Center bit
       N = 4;
end

numCommonFieldBits = N*8+center26ToneBit+numCRCBits+numTailBits;
numSamplesPerSym = (chanBW/20)*80;
commonFieldSamples = ceil(numCommonFieldBits/NDBPS)*numSamplesPerSym;
symLength = 4*chanBW; % Number of symbols in time domain
numCommonFieldSymbols = commonFieldSamples/symLength;

s = struct( ...
    'NumCommonFieldBits',      numCommonFieldBits, ...
    'NumCommonFieldSamples',   commonFieldSamples, ...
    'NumCommonFieldSymbols',   numCommonFieldSymbols, ...
    'NumContentChannels',      numContentChannels, ...
    'NumRUAllocationSubfield', N, ...
    'NumCRCBits',              numCRCBits, ...
    'NumTailBits',             numTailBits, ...
    'Center26ToneBit',         center26ToneBit);
end