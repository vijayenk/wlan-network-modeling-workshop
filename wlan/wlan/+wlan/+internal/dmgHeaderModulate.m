function [y,varargout] = dmgHeaderModulate(bits,cfgDMG)
%dmgHeaderModulate DMG header modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgHeaderModulate(BITS,CFGDMG) generates the Header field time-domain
%   waveform. Y is the time-domain DMG Header field signal. It is a complex
%   column vector of length Ns, where Ns represents the number of
%   time-domain samples.
%
%   BITS is the encoded header bits. It is of size N-by-1 of type uint8,
%   where N is the number of LDPC encoded header bits.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.
%
%   [Y,D1,D2] = dmgHeaderModulate(...) additionally returns diagnostic
%   information. For Control PHY, D1 is the differential phase shift keying
%   modulated signal and D2 is not assigned. For OFDM PHY, D1 is the QPSK
%   modulated symbols on data subcarriers and D2 is the mapped data and
%   pilot subcarriers and symbols. For SC PHY, D1 and D2 are not assigned.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

nargoutchk(0,3);

switch phyType(cfgDMG)
    case 'Control'
        % IEEE 802.11ad-2012, Section 21.4.3.3.4 DBPSK Modulation
        d = dpskmod(int32(~bits),2);
        varargout{1} = d; % Symbols before spreading

        % IEEE 802.11ad-2012 Section 21.4.3.3.5 Spreading
        y = wlan.internal.dmgControlSpread(d);
    case 'SC'
        % IEEE 802.11ad-2012, Section 21.6.3.1.4 
        s = wlanConstellationMap(bits,1,pi*(0:size(bits,1)-1).'/2); % pi/2-BPSK modulation

        % Apply blocking and add guard interval as per IEEE 802.11ad-2012
        % Section 21.6.3.2.5 and repeat sequence multiplied with -1
        y = wlan.internal.dmgSymBlkGIInsert([s; s*-1]);
    otherwise % OFDM
        % QPSK Modulation
        d = wlan.internal.dmgQPSKModulate(bits);
        
        % Map to subcarriers with static tone pairing. IEEE 802.11ad-2012, Section 21.5.3.2.4.6.2
        NSYM = 1;
        [ofdmInfo,ofdmInd] = wlan.internal.dmgOFDMInfo();
        [k,pk] = wlan.internal.dmgTonePairingIndices('Static');
        grid = complex(zeros(ofdmInfo.NFFT,NSYM));
        grid(ofdmInd.DataIndices(k+1),:) = d(:,1);
        grid(ofdmInd.DataIndices(pk+1),:) = d(:,2); 

        % Generate pilot sequence. IEEE 802.11ad-2012, Section 21.5.3.2.5)
        grid(ofdmInd.PilotIndices,:) = wlan.internal.dmgPilots(NSYM,0); % p_(N+0)Pk
        
        varargout{1} = grid(ofdmInd.DataIndices,:); % Modulated data symbols
        varargout{2} = grid; % Mapped data and pilot subcarriers

        % OFDM modulate
        yt = wlan.internal.ofdmModulate(grid,ofdmInfo.NGI)*ofdmInfo.NormalizationFactor;
        y = yt(:,1); % For codegen
end
end
