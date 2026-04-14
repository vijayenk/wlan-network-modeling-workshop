function onWGSym = wurMCOOKOnSymbols(seq,dataRate,subchannelIndex,cfgFormat,osf,varargin)
%onWGSym WUR On symbol waveform generations
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   ONWGSYM = wurMCOOKOnSymbols(SEQ,DATARATE,SUBCHANNELINDEX,OSF,CFGFORMAT)
%   generates the On-Off waveforms for a specific 20 MHz subchannel.
%
%   ONWGSYM is the time-domain On-Off signal. It is a complex matrix of
%   size Ns-by-Nsym-by-Nt, where Ns represents the number of time-domain
%   samples, Nsym represents the number of symbols in the On symbol 
%   waveform, and Nt represents the number of transmit antennas.
%
%   SEQ is a non-zero vector of normalized sequence used for the 
%   construction of the MC-OOK On symbol. 
%
%   DATARATE specifies the transmission rate as character vector or string 
%   and must be 'LDR', or 'HDR'.
%
%   SUBCHANNELINDEX indicates the subchannel index for CBW20, CBW40 and
%   CBW80 and must be between 1 and 4 inclusive.
%
%   OSF is the oversampling factor.
%
%   CFGFORMAT is the format configuration object of type <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>,
%   which specifies the parameters for the WUR PPDU format.
%
%   ONWGSYM = wurMCOOKOnSymbols(...,SYMOFFSET) generates the On-Off
%   waveforms for a 20 MHz subchannel with a specific offset within the
%   symbol randomizer.
%
%   SYMOFFSET is an integer scalar that represents the symbol offset to
%   progress the state of the linear feedback shift register.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

chanBW = cfgFormat.ChannelBandwidth;

% Get the parameters for waveform FFT use
[k,Nfft,CPLength,useIdx] = wlan.internal.wurWGParameters(dataRate,chanBW,osf);
k = k(subchannelIndex,:);
Ntone = numel(k);

chBW = wlan.internal.cbwStr2Num(chanBW);
nsym = size(seq,2);

[m,Tcsr] = wlan.internal.wurSymbolRandomizer(nsym,dataRate,varargin{:});
seq = seq .* m;

% Add cyclic shift per symbol to shift per antenna
Tcs = wlan.internal.wurTxAntCyclicShift(dataRate,cfgFormat,subchannelIndex); % Cyclic shift per antenna
Tcsr = Tcsr + Tcs;
csd = Tcsr*chBW*1e-3; % Cyclic shift in samples per symbol

% Apply per symbol and per-antenna cyclic shift
NfftNominal = Nfft/osf;
phaseShift = exp(-1i*2*pi*permute(csd,[3 2 1]).*k.'/NfftNominal);
seq = seq.*phaseShift;
xCycShift = complex(zeros(Nfft,nsym,cfgFormat.NumTransmitAntennas));
xCycShift(k+Nfft/2+1,:,:) = seq;

y = ifft(ifftshift(xCycShift,1),[],1);
% IEEE 802.11ba/D8.0, December 2020, Equation 30-3.
y = y*sqrt(2)*(Nfft/sqrt(cfgFormat.NumTransmitAntennas*Ntone));
% Guard interval
onWGSym = [y(useIdx(end)-CPLength+1:useIdx(end),:,:); y(useIdx,:,:)];

end

