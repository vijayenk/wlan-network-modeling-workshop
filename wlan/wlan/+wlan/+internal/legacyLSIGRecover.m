function [bits,failCheck,lsigInfo,eqCombLSIGSym,varargout] = legacyLSIGRecover(x,chanEst,nVar,chanBW)
%legacyLSIGRecover Recover information bits in L-SIG field of Non-HT, HT and VHT packet format
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BITS,FAILCHECK] = legacyLSIGRecover(RX,CHANEST,NVAR,CHANBW) recovers
%   the information bits in the L-SIG field and performs parity and rate
%   checks.
%
%   BITS is an int8 column vector of length 24 containing the recovered
%   information bits.
%
%   FAILCHECK is a logical scalar which is true if BITS fails the parity
%   check or its first 4 bits is not one of the eight legitimate rates.
%
%   [...,INFO] = legacyLSIGRecover(...), where INFO is a structure with the
%   following fields:
%       MCS    - Indicate the MCS value as defined in IEEE Std 802.11-2016,
%                Table 17-6.
%       LENGTH - Indicate the number of octets in the PSDU that the MAC is
%                currently requesting the PHY to transmit.
%
%   [...,EQCOMBLSIGSYM] = legacyLSIGRecover(...) returns the equalized data
%   subcarriers after averaging L-SIG and RL-SIG field symbols.
%
%   [...,EQLSIGSYM] = legacyLSIGRecover(...) also returns the equalized
%   data subcarriers of L-SIG and RL-SIG field symbols independently.
%
%   X is the received time-domain packet. It is a Ns-by-Nr matrix of real
%   or complex values, where Ns represents the number of time-domain
%   samples in the L-SIG field and Nr represents the number of receive
%   antennas.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the L-LTF. It is a real or complex array of size Nst-by-1-by-Nr, where
%   Nst represents the total number of occupied subcarriers. The singleton
%   dimension corresponds to the single transmitted stream in the L-LTF
%   which includes the combined cyclic shifts if multiple transmit antennas
%   are used.
%
%   NVAR is the noise variance estimate. It is a real, nonnegative
%   scalar.
%
%   CHANBW is the channel bandwidth and must be 'CBW20', 'CBW40', 'CBW80',
%   'CBW160', or 'CBW320'.

%   Copyright 2022-2025 The MathWorks, Inc.

% Get OFDM configuration
[cfgOFDM,dataInd,pilotInd] = wlan.internal.getOFDMConfig(chanBW,'Long','Legacy');

% Extract data and pilot subcarriers from channel estimate
chanEstData = chanEst(dataInd,:,:);
chanEstPilots = chanEst(pilotInd,:,:);

% Get algorithm defaults
recParams = wlan.internal.parseOptionalInputs(mfilename);

% ofdmOutData is [48*num20, 1, numRx]
[ofdmOutData,ofdmOutPilots] = wlan.internal.wlanOFDMDemodulate(x,cfgOFDM,recParams.OFDMSymbolOffset);

% Pilot phase tracking Get reference pilots, from IEEE Std 802.11-2012, Eqn
% 20-14
z = 0; % No offset as first symbol with pilots
refPilots = wlan.internal.nonHTPilots(1,z,chanBW);

% Estimate CPE and phase correct symbols
cpe = wlan.internal.commonPhaseErrorEstimate(ofdmOutPilots,chanEstPilots,refPilots);
ofdmOutData = wlan.internal.commonPhaseErrorCorrect(ofdmOutData,cpe);

% Merge num20 channel estimates and demodulated symbols together for the repeated subcarriers for data carrying subcarriers
NsdSeg = 48; % Number of subcarriers in 20 MHz segment
num20MHz = size(ofdmOutData,1)/NsdSeg; % Number of 20 MHz subchannels
[ofdmDataOutOne20MHz,chanEstDataOne20MHz] = wlan.internal.mergeSubchannels(ofdmOutData,chanEstData,num20MHz);

% Equalize data carrying subcarriers, merge 20 MHz subchannels
[eqCombLSIGSym,csiCombData] = wlan.internal.equalize(ofdmDataOutOne20MHz,chanEstDataOne20MHz,recParams.EqualizationMethod,nVar);
if nargout==5
    % Equalize the L-SIG without merging 20 MHz subchannels
    varargout{1} = wlan.internal.equalize(ofdmOutData,chanEstData,recParams.EqualizationMethod,nVar); % Equalize without combining
end

% Demap and decode L-SIG symbols
[bits,failCheck] = wlanLSIGBitRecover(eqCombLSIGSym,nVar,csiCombData);

% Interpret L-SIG information bits
lsigInfo = struct;
[lsigInfo.MCS,lsigInfo.Length] = wlan.internal.interpretLSIG(bits);

end
