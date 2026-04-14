function y = vhtGetSTSPerUser(paddedData,scramInitBits,mcsTable,chanBW,numOFDMSym,userIdx,numSTS,varargin)
%vhtGetSTSPerUser Encode, parse and map bits to create space-time streams
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = vhtGetSTSPerUser(DATA,SCAM,MCSTABLE,CHANBW,NUMSYM,USERIDX,NUMSTS)
%   performs scrambling, encoding, stream parsing, segment parsing,
%   interleaving, constellation mapping and segment deparsing to form
%   complex 'BCC' encoded symbols representing the space-time stream for a
%   user.
%
%   Y = vhtGetSTSPerUser(...,CHANNELCODING,NUMSYMMAXINIT,MSTBC) performs
%   scrambling, encoding, stream parsing, segment parsing, interleaving,
%   constellation mapping and segment deparsing to form complex 'BCC' or
%   'LDPC' encoded symbols representing the space-time stream for a user.
%
%   DATA is the padded PSDU with service bits.
%
%   SCRAM is the scrambler initialization bits.
%
%   MCSTABLE is a structure array containing the rate information for all
%   users.
%
%   CHANBW is a character vector or string specifying the channel
%   bandwidth.
%
%   NUMSYM is the number of OFDM symbols.
%
%   USERIDX is the user index of interest and is used to index into
%   MCSTABLE.
%
%   NUMSTS is the number of space-time streams for the user.
%
%   CHANNELCODING is a character vector or string scalar and specifies the
%   coding type. It must be one of 'BCC' and 'LDPC'. The default is set to
%   'BCC' encoding.
%
%   NUMSYMMAXINIT is the number of OFDM symbols resulted due to LDPC
%   encoding as specified in IEEE Std 802.11ac(TM)-2013, Section
%   22.3.10.5.5, Eq 22-65. The NUMSYMMAXINIT is the initial maximum number
%   of symbols without adding any extra symbols due to LDPC. The
%   NUMSYMMAXINIT input is only required for LDPC.
%
%   MSTBC specifies the space-time block coding in the data field
%   transmission. The MSTBC of one mean no STBC. The STBC value of two
%   considers STBC in the calculation of LDPC encoding parameters. The
%   MSTBC input is only required for LDPC encoding.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

narginchk(7,10);

if nargin == 7
    channelCoding = 'BCC';
else
   channelCoding = varargin{1};
   numSymMaxInit = varargin{2};
   mSTBC = varargin{3};
end

numES     = mcsTable.NES(userIdx);
numSS     = mcsTable.Nss(userIdx);
rate      = mcsTable.Rate(userIdx);
numBPSCS  = mcsTable.NBPSCS(userIdx);
numCBPS   = mcsTable.NCBPS(userIdx);
numDBPS   = mcsTable.NDBPS(userIdx);
numSeg    = 1 + any(strcmp(chanBW, {'CBW16', 'CBW160'}));
numCBPSSI = numCBPS/numSS/numSeg;

scrambData = wlanScramble(paddedData, scramInitBits);

if strcmp(channelCoding, 'BCC')
    % BCC Encoding
    %   Reshape scrambled data as per IEEE Std 802.11ac-2013, Eq. 22-60
    %   for multiple encoders
    numTailBits = 6;
    encodedStreams = reshape(scrambData, numES, []).';
    % BCC encoding, Section 22.3.10.5.3, IEEE Std 802.11ac-2013
    encodedData = wlanBCCEncode([encodedStreams; zeros(numTailBits,numES)], rate);
else
    % LDPC Encoding as specified in IEEE Std 802.11-2012, 802.11ac-2013,
    % Section 20.3.11.17.5 and Section 22.3.10.5.4 respectively.

    numPLD = numSymMaxInit*numDBPS; % Number of payload bits, Eq 22-61

    cfg = wlan.internal.getLDPCparameters(numDBPS, rate, mSTBC, numPLD, numOFDMSym);
    encodedData = wlan.internal.ldpcEncode(scrambData, cfg);
end

% Repetition coding
%   Repeat encoded data for S1G MCS 10
if (rate==1/2)&&(numDBPS==6) % rate and Ndbps for S1G MCS10
    repeatedData = wlan.internal.repetitionForMCS10(encodedData);
else
    repeatedData = encodedData;
end

% Parse encoded data into streams
%   Section 22.3.10.6, IEEE Std 802.11ac-2013
streamParsedData = wlanStreamParse(repeatedData, numSS, numCBPS, numBPSCS); % [(Ncbpss*Nsym),Nss]

% Segment parsing for 16, 160, 80+80 MHz
%   Section 22.3.10.7, IEEE Std 802.11ac-2013
parsedData = wlanSegmentParseBits(streamParsedData, chanBW, numES, numCBPS, numBPSCS); % [(Ncbpssi*Nsym),Nss,Nseg]

% BCC Interleaving, Section 22.3.10.8, IEEE Std 802.11ac-2013,
% Section 24.3.9.8, IEEE Std P802.11ah/D5.0
if strcmp(channelCoding, 'BCC')
    interleavedData = wlanBCCInterleave(parsedData, 'VHT', numCBPSSI, chanBW);
    % [(Ncbpssi*Nsym),Nss,Nseg]
else
    % Interleaving is not required for LDPC
    interleavedData = parsedData;
end

% Constellation mapping, Section 22.3.10.9, IEEE Std 802.11ac-2013
mappedData = wlanConstellationMap(interleavedData, numBPSCS);  % [(Nsd/Nseg*Nsym),Nss,Nseg]

% Reshape to form OFDM symbols
mappedData = localReshape(mappedData, numCBPSSI/numBPSCS, [], numSS, numSeg); % [Nsd/Nseg,Nsym,Nss,Nseg]

% LDPC tone mapping index as specified in IEEE 802.11ac-2013, Section
% 22.3.10.19.2.
if strcmp(channelCoding,'LDPC')
    mappingIndexLDPC = wlan.internal.getToneMappingIndices(chanBW);
    mappedData(mappingIndexLDPC,:,:,:) = mappedData; % [Nsd/Nseg,Nsym,Nss,Nseg]
end

% Frequency segment deparsing, Section 22.3.10.9.3, IEEE Std 802.11ac-2013
ssPerUser = wlanSegmentDeparseSymbols(mappedData, chanBW); % [Nsd,Nsym,Nss]

% STBC encoding, Section 22.3.10.9.4, IEEE Std 802.11ac-2013
if numSTS>numSS
    y = wlan.internal.stbcEncode(ssPerUser(:,:,:), coder.ignoreConst(numSTS)); % Indexing for codegen
else
    y = ssPerUser(:,:,:); % Indexing for codegen
end

end

function y = localReshape(y, varargin)
    coder.internal.prefer_const(varargin);
    coder.inline('never');
    y = reshape(y, varargin{:});
end
