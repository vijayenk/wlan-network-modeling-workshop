function [y,varargout] = dmgDataModulate(bits,cfgDMG)
%dmgDataModulate DMG data modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgDataModulate(BITS,CFGDMG) generates the DMG format Data field
%   time-domain waveform.
%
%   Y is the time-domain DMG Data field signal. It is a complex column
%   vector of length Ns, where Ns represents the number of time-domain
%   samples.
%
%   BITS is the encoded data bits. It is of size N-by-1 of type uint8,
%   where N is the number of LDPC encoded header bits.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.
%
%   [Y,D] = dmgDataModulate(...) additionally returns diagnostic
%   information. For Control PHY, D is the symbols before spreading. For
%   OFDM PHY, D is the modulated symbols on data subcarriers. For SC PHY, D
%   is not assigned.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

nargoutchk(0,2);

mcsTable = wlan.internal.getRateTable(cfgDMG);

switch phyType(cfgDMG)
    case 'Control'
        % 21.4.3.3.4 DBPSK Modulation
        d = dpskmod(int32(~bits),2);
        varargout{1} = d; % Symbols before spreading

        % 21.4.3.3.5 Spreading
        y = wlan.internal.dmgControlSpread(d);
        
    case 'OFDM'
        parms = wlan.internal.dmgOFDMEncodingInfo(cfgDMG);

        [ofdmInfo,ofdmInd] = wlan.internal.dmgOFDMInfo();
        grid = complex(zeros(ofdmInfo.NFFT,parms.NSYM));

        switch mcsTable.NBPSCS
            case 1 % MCS 13-14
                % IEEE 802.11ad-2012 Section 21.5.3.2.4.2 SQPSK Modulation
                c = wlanConstellationMap(bits,2);

                % Map to subcarriers with static or dynamic tone pairing
                [k,pk] = wlan.internal.dmgTonePairingIndices(cfgDMG.TonePairingType,cfgDMG.DTPGroupPairIndex);
                d = reshape(c,ofdmInfo.NSD/2,parms.NSYM);
                grid(ofdmInd.DataIndices(k+1),:) = d;
                grid(ofdmInd.DataIndices(pk+1),:) = conj(d);

            case 2 % MCS 15-17       
                % IEEE 802.11ad-2012 Section 21.5.3.2.4.3 QPSK Modulation
                d = wlan.internal.dmgQPSKModulate(bits);
                
                % Map to subcarriers with static or dynamic tone pairing
                [k,pk] = wlan.internal.dmgTonePairingIndices(cfgDMG.TonePairingType,cfgDMG.DTPGroupPairIndex);
                grid(ofdmInd.DataIndices(k+1),:) = reshape(d(:,1),ofdmInfo.NSD/2,parms.NSYM);
                grid(ofdmInd.DataIndices(pk+1),:) = reshape(d(:,2),ofdmInfo.NSD/2,parms.NSYM);

            case 4 % MCS 18-21
                % IEEE 802.11ad-2012 Section 21.5.3.2.4.4 16QAM Modulation
                c = wlanConstellationMap(bits,4);
                bits = reshape(c,ofdmInfo.NSD,parms.NSYM);

                % Map to subcarriers, interleaving each side of DC
                grid(ofdmInd.DataIndices(1:2:end,:),:) = bits(1:end/2,:);
                grid(ofdmInd.DataIndices(2:2:end,:),:) = bits(end/2+1:end,:);

            otherwise % 6 % MCS 22-24
                % IEEE 802.11ad-2012 Section 21.5.3.2.4.5 64QAM Modulation
                c = wlanConstellationMap(bits,6);
                bits = reshape(c,ofdmInfo.NSD,parms.NSYM);

                % Map to subcarriers, interleaving subcarriers into thirds
                k = 0:(ofdmInfo.NSD-1);
                m = 112*(mod(k,3))+floor(k/3);
                grid(ofdmInd.DataIndices,:) = bits(m+1,:);
        end
        varargout{1} = grid(ofdmInd.DataIndices,:);

        % Generate pilot sequence (Section 21.5.3.2.5) and map
        grid(ofdmInd.PilotIndices,:) = wlan.internal.dmgPilots(parms.NSYM,1); % p_(N+1)Pk

        % OFDM modulate
        yl = wlan.internal.ofdmModulate(grid,ofdmInfo.NGI)*ofdmInfo.NormalizationFactor;
        y = yl(:,1); % for codegen
        
    otherwise % Single carrier PHY
        % Constellation mapping
        if mcsTable.NCBPS==2
            % pi/2-QPSK
            sd = wlanConstellationMap(bits,mcsTable.NCBPS,-pi/4);
        else
            % pi/2-BPSK, pi/2-16QAM, pi/2-64QAM
            sd = wlanConstellationMap(bits,mcsTable.NCBPS);
        end
        
        % pi/2 rotation per sample, equivalent to s = sd.*exp(1i*pi*(0:size(sd,1)-1).'/2);
        s = sd.*repmat(exp(1i*pi*(0:3).'/2),size(sd,1)/4,1);
        
        % Apply blocking, add guard interval and postfix as per Section
        % 21.6.3.2.5
        y = wlan.internal.dmgSymBlkGIInsert(s,true); 
end
end


