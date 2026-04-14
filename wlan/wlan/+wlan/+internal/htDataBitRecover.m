function psdu = htDataBitRecover(rx, noiseVar, csi, cfg, ldpcParams)
%htDataBitRecover Recover data bits from HT Data field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PSDU = htDataBitRecover(RX,NOISEVAR,CSI,CFG,LDPCPARAMS) recovers the
%   data bits given the equalized Data field from a HT transmission, the
%   noise variance estimate, and the HT configuration object.
%
%   PSDU is an int8 column vector of length 8*CFG.PSDULength containing the
%   recovered information bits.
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
%   CFG is the format configuration object of type <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a> which
%   specifies the parameters for the HT format.
%
%   LDPCPARAMS is a structure containing LDPC decoding parameters.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

mcsTable   = wlan.internal.getRateTable(cfg);
numSS      = mcsTable.Nss;
numCBPSSI  = mcsTable.NCBPS/numSS;
numDBPS    = mcsTable.NDBPS;
rate       = mcsTable.Rate;
mSTBC      = mcsTable.mSTBC;
numOFDMSym = size(rx,2);

% Constellation demapping
qamDemodOut = wlanConstellationDemap(rx, noiseVar, mcsTable.NBPSCS);

% Apply bit-wise CSI and concatenate OFDM symbols in the first dimension
qamDemodOut = reshape(qamDemodOut, mcsTable.NBPSCS, [], numOFDMSym, numSS) .* ...
    reshape(csi, 1, [], 1, numSS); % [Nbpscs Nsd Nsym Nss]
qamDemodOut = reshape(qamDemodOut, [], numSS);

% BCC Deinterleaving
if strcmp(cfg.ChannelCoding,'BCC')
    deintlvrOut = wlanBCCDeinterleave(qamDemodOut, 'VHT', numCBPSSI, cfg.ChannelBandwidth);
else
    % Deinterleaving is not required for LDPC
    deintlvrOut = qamDemodOut;
end

% Stream deparsing
streamDeparserOut = wlanStreamDeparse(deintlvrOut, mcsTable.NES, mcsTable.NCBPS, mcsTable.NBPSCS);

% Channel decoding
if strcmp(cfg.ChannelCoding,'BCC')
    % BCC channel decoding
    htDataBits = wlanBCCDecode(streamDeparserOut, rate);
    % BCC decoder deparser
    descramIn = reshape(htDataBits.', [], 1);
else
    % LDPC Channel decoding
    numPLD = cfg.PSDULength*8 + 16; % Number of payload bits
    cfgLDPC = wlan.internal.getLDPCparameters(numDBPS, rate, mSTBC, numPLD);
    descramIn = wlan.internal.ldpcDecode(streamDeparserOut(:), cfgLDPC, ldpcParams.LDPCDecodingMethod, ldpcParams.alphaBeta, ldpcParams.MaximumLDPCIterationCount, ldpcParams.Termination);
end

% Derive initial state of the scrambler
scramSeqInit = descramIn(1:7);
scramInitBits = wlan.internal.scramblerInitialState(scramSeqInit);

% Remove pad and tail bits, and descramble
if all(scramInitBits==0)
    % Scrambler initialization invalid (0), therefore do not descramble
    descramOutData = descramIn(1:(16+8*cfg.PSDULength));
else
    descramOutData = wlanScramble(descramIn(1:(16+8*cfg.PSDULength)), scramInitBits);
end

% Remove the 16 service bits
psdu = descramOutData(17:end);

end
