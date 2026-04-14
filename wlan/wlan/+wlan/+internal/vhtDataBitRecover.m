function [psdu,crc] = vhtDataBitRecover(rx, noiseVar, csi, cfg, ldpcParams, varargin)
%vhtDataBitRecover Recover data bits from VHT Data field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [PSDU, CRC] = vhtDataBitRecover(RX,NOISEVAR,CSI,CFG,LDPCPARAMS)
%   recovers the data bits given the equalized Data field from a VHT
%   transmission, the noise variance estimate, and the HT configuration
%   object.
%
%   PSDU is an int8 column vector of length 8*CFG.PSDULength containing the
%   recovered information bits.
%
%   CRC is an int8 column vector of length 8 containing the VHT-Data field
%   checksum bits.
%
%   RX contains the demodulated and equalized Data field OFDM symbols,
%   specified as a Nsd-by-Nsym-by-Nss complex-valued matrix, where Nsd is
%   the number of data subcarriers in the Data field and Nsym is the number
%   of OFDM symbols.
%
%   NOISEVAR is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   CSI contains  channel state information to enhance the demapping of
%   OFDM subcarriers. It is is a NSD-by-NSS column vector of real values.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a> which
%   specifies the parameters for the VHT format.
%
%   LDPCPARAMS is a structure containing LDPC decoding parameters.
%
%   [PSDU, CRC] = vhtDataBitRecover(...,USERIDX) recovers the data bits
%   given the equalized Data field from a multi-user transmission for the
%   user with index USERIDX.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

% Default
userIdx = 1;
if nargin>5
    % vhtDataBitRecover(RX,NOISEVAREST,CSI,CFG,LDPCPARAMS,USERIDX)
    userIdx = varargin{1};
end

mcsTable = wlan.internal.getRateTable(cfg);
chanBW = cfg.ChannelBandwidth;

% Set up some implicit configuration parameters
numBPSCS   = mcsTable.NBPSCS(userIdx);    % Number of coded bits per single carrier
numCBPS    = mcsTable.NCBPS(userIdx);     % Number of coded bits per OFDM symbol
numDBPS    = mcsTable.NDBPS(userIdx);
rate       = mcsTable.Rate(userIdx);
numES      = mcsTable.NES(userIdx);       % Number of encoded streams
numSS      = mcsTable.Nss(userIdx);       % Number of spatial streams
mSTBC      = mcsTable.mSTBC(userIdx);
numSeg     = strcmp(chanBW, 'CBW160') + 1;
% Number of coded bits per OFDM symbol, per spatial stream, per segment
numCBPSSI  = numCBPS/numSS/numSeg;
numOFDMSym = size(rx,2);

% Set channel coding
coder.varsize('channelCoding',[1,4]);
channelCoding = getChannelCoding(cfg);

% Segment parsing of symbols
parserOut  = wlanSegmentParseSymbols(rx, chanBW); % [Nsd/Nseg Nsym Nss Nseg]
csiParserOut = wlanSegmentParseSymbols(reshape(csi, [], 1, numSS), chanBW); % [Nsd/Nseg 1 Nss Nseg]

% LDPC Tone demapping
if strcmp(channelCoding{userIdx},'LDPC')
    mappingIndicesLDPC = wlan.internal.getToneMappingIndices(chanBW);
    parserOut = parserOut(mappingIndicesLDPC,:,:,:);
    csiParserOut = csiParserOut(mappingIndicesLDPC,:,:,:);
end

% Constellation demapping
qamDemodOut = wlanConstellationDemap(parserOut, noiseVar, numBPSCS); % [Ncbpssi,Nsym,Nss,Nseg]

% Apply bit-wise CSI and concatenate OFDM symbols in the first dimension
qamDemodOut = reshape(qamDemodOut, numBPSCS, [], numOFDMSym, numSS, numSeg) .* ...
    reshape(csiParserOut, 1, [], 1, numSS, numSeg);
qamDemodOut = reshape(qamDemodOut, [], numSS, numSeg); % [(Ncbpssi*Nsym),Nss,Nseg]

% BCC Deinterleaving
if strcmp(channelCoding{userIdx}, 'BCC')
    deintlvrOut = wlanBCCDeinterleave(qamDemodOut, 'VHT', numCBPSSI, chanBW); % [(Ncbpssi*Nsym),Nss,Nseg]
else
    % Deinterleaving is not required for LDPC
    deintlvrOut = qamDemodOut;
end

% Segment deparsing of bits
segDeparserOut = wlanSegmentDeparseBits(deintlvrOut, chanBW, numES, numCBPS, numBPSCS); % [(Ncbpss*Nsym),Nss]

% Stream deparsing
streamDeparserOut = wlanStreamDeparse(segDeparserOut(:,:), numES, numCBPS, numBPSCS); % [(Ncbps*Nsym/Nes),Nes]
% Indexing for codegen
if strcmp(channelCoding{userIdx}, 'BCC')
    % Channel decoding for BCC
    numTailBits = 6;
    chanDecOutPreDeparse = wlanBCCDecode(streamDeparserOut, mcsTable.Rate(userIdx));
    % BCC decoder deparser
    chanDecOut = reshape(chanDecOutPreDeparse(1:end-numTailBits,:)', [], 1);
else
    % LDPC decoding
    % Calculate numSymMaxInit as specified in IEEE Std 802.11-2020, Section
    % 21.3.10.5.4, Eq 21-65 and Section 21.3.20, Eq 21-107
    cfgInfo = validateConfig(cfg, 'MCS');
    numSym = cfgInfo.NumDataSymbols(1);

    % Estimate number of OFDM symbols as specified in IEEE Std 802.11-2020,
    % Section 21.3.20, Eq 21-107.
    numSymMaxInit = numSym - mSTBC*cfgInfo.ExtraLDPCSymbol;

    % Compute number of payload bits as specified in IEEE Std 802.11-2020,
    % Section 21.3.10.5.4, Eq 21-61 and Eq 21-66.
    numPLD = numSymMaxInit*numDBPS;

    cfgLDPC = wlan.internal.getLDPCparameters(numDBPS, rate, mSTBC, numPLD, numOFDMSym);
    chanDecOut = wlan.internal.ldpcDecode(streamDeparserOut, cfgLDPC, ldpcParams.LDPCDecodingMethod, ldpcParams.alphaBeta, ldpcParams.MaximumLDPCIterationCount, ldpcParams.Termination);
end

% Derive initial state of the scrambler
scramSeqInit = chanDecOut(1:7);
scramInitBits = wlan.internal.scramblerInitialState(scramSeqInit);

% Remove pad and tail bits, and descramble
if all(scramInitBits==0)
    % Scrambler initialization invalid (0), therefore do not descramble
    descramBits = chanDecOut(1:16+8*cfg.PSDULength(userIdx));
else
    descramBits = wlanScramble(chanDecOut(1:16+8*cfg.PSDULength(userIdx)), scramInitBits);
end

% Outputs
crc = descramBits(9:16);
psdu = descramBits(17:end);

end
