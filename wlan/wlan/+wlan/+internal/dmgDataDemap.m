function softBits = dmgDataDemap(sym,noiseVarEst,varargin)
%dmgDataDemap DMG Data field Demodulation for OFDM, SC and Control PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   SOFTBITS = dmgDataDemap(SYM,NOISEVAREST,CFGDMG) performs
%   demapping of the symbols SYM given the noise variance NOISEVAREST and
%   the DMG configuration object CFGDMG.
%
%   SOFTBITS = dmgDataDemap(SYM,NOISEVAREST,CSI,CFGDMG) performs demapping
%   of the symbols with additional CSI information. The CSI is only used
%   for OFDM PHY.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

narginchk(3,4)

csiFlag = 0;
if isa(varargin{1},'wlanDMGConfig')
    cfgDMG = varargin{1};
else 
    csi = varargin{1};
    cfgDMG = varargin{2};
    csiFlag = 1;
end

% Validate input sizes for OFDM, SC and Control PHY
switch phyType(cfgDMG)
    case 'SC'
        % Validate input size for SC PHY
        Ngi = 64; % Number of samples in guard interval
        blkSize = 512; % Number of samples in block
        parms = wlan.internal.dmgSCEncodingInfo(cfgDMG);
        numDataSymPerBlk = blkSize-Ngi; % Block size
        if any(size(sym,1) ~= numDataSymPerBlk)
            coder.internal.error('wlan:shared:IncorrectSCNsym',size(sym,1));
        end
        if any(size(sym,2) < parms.NBLKS)
            coder.internal.error('wlan:shared:IncorrectSCNblks',parms.NBLKS,size(sym,2));
        end
        sym = sym(:,1:parms.NBLKS); % Extract the minimum input signal length required to process the SC PHY
    case 'OFDM'
        % Validate input size for OFDM PHY
        ofdmInfo = wlan.internal.dmgOFDMInfo();
        parms = wlan.internal.dmgOFDMEncodingInfo(cfgDMG);
        if any(size(sym,1) ~= ofdmInfo.NSD)
            coder.internal.error('wlan:shared:IncorrectOFDMSC',size(sym,1));
        end
        if any(size(sym,2) ~= parms.NSYM)
            coder.internal.error('wlan:dmgDataDemap:IncorrectOFDMNsym',parms.NSYM,size(sym,2));
        end
       
        % Validate CSI input 
        if csiFlag
            validateattributes(csi,{'double'},{'real','column','finite'},mfilename,'CSI');
            if size(csi,1) ~= ofdmInfo.NSD
                coder.internal.error('wlan:shared:InvalidCSISize',size(csi,1));
            end
        end
        sym = sym(:,1:parms.NSYM); % Extract the minimum input signal length required to process the OFDM PHY
    otherwise 
        % Validate input size for Control PHY
        SF = 32; % Spreading factor
        headerIndex = wlanFieldIndices(cfgDMG,'DMG-Header');
        dataIndex = wlanFieldIndices(cfgDMG,'DMG-Data');
        headerLength = headerIndex(2)-headerIndex(1)+1;
        dataLength = dataIndex(2)-dataIndex(1)+1;
        minInputLength = double((dataLength+headerLength)/SF);
        if any(size(sym,1) < minInputLength)
            coder.internal.error('wlan:shared:IncorrectControlSym',minInputLength,size(sym,1));
        end
        sym = sym(1:minInputLength,1); % Extract the minimum input signal length required to process the Control PHY
end

mcsTable = wlan.internal.getRateTable(cfgDMG);

switch phyType(cfgDMG)
    case 'OFDM'
        switch mcsTable.NBPSCS
            case 1 % MCS 13,14
                [k,pk] = wlan.internal.dmgTonePairingIndices(cfgDMG.TonePairingType,cfgDMG.DTPGroupPairIndex);
                % Combine symbols before demodulation
                demappedData = sqpskCombine(sym,k,pk);
                softBits = wlanConstellationDemap(demappedData,noiseVarEst/2,2);
                % Combine CSI of symbols and apply
                if nargin==4 % with CSI
                    csiComb = sqpskCombine(csi,k,pk);
                    softBits = wlan.internal.applyCSI(softBits,csiComb,2);
                end
            case 2 % MCS 15-17               
                [k,pk] = wlan.internal.dmgTonePairingIndices(cfgDMG.TonePairingType,cfgDMG.DTPGroupPairIndex); 
                if nargin==3 % No CSI
                    softBits = wlan.internal.dmgQPSKDemodulate(sym,noiseVarEst,k,pk);
                else % with CSI
                    softBits = wlan.internal.dmgQPSKDemodulate(sym,noiseVarEst,k,pk,csi);
                end
            otherwise % MCS 18-24
                % Demap tones and then demap symbols
                demappedData = toneDemapping(sym,mcsTable.NBPSCS);
                softBits = wlanConstellationDemap(demappedData,noiseVarEst,mcsTable.NBPSCS);
                % Demap CSI tones and apply
                if nargin==4 % With CSI
                    csiComb = toneDemapping(csi,mcsTable.NBPSCS);
                    softBits = wlan.internal.applyCSI(softBits,csiComb,mcsTable.NBPSCS);
                end
        end
    case 'SC'
        % Remove pi/2 rotation
        sym = wlan.internal.dmgDerotate(sym);
        if mcsTable.NCBPS==2
            % pi/2-QPSK
            softBits = wlanConstellationDemap(sym,noiseVarEst,mcsTable.NCBPS,-pi/4);
        else
            % pi/2-BPSK, pi/2-16QAM
            softBits = wlanConstellationDemap(sym,noiseVarEst,mcsTable.NCBPS);
        end
          
    otherwise % Control PHY
        % DBPSK demodulation
        softBits = wlan.internal.dbpskDemodulate(sym,noiseVarEst);
end
        
end

function y = sqpskCombine(x,k,pk)
    y = (x(k+1,:)+conj(x(pk+1,:)))/2;
end

function y = toneDemapping(x,nsbps)
    if isreal(x)
        y = coder.nullcopy(zeros(size(x)));
    else
        y = coder.nullcopy(complex(zeros(size(x))));
    end
    
    switch nsbps
        case 4 % 16-QAM - 2 code blocks interleaved on a subcarrier basis
            y(1:end/2,:) = x(1:2:end,:);
            y(end/2+1:end,:) = x(2:2:end,:);
        otherwise % 64-QAM - 3 code blocks interleaved on a subcarrier basis
            ofdmInfo = wlan.internal.dmgOFDMInfo;
            m = reshape(reshape(0:(size(x,1)-1),ofdmInfo.NSD/3,3).',ofdmInfo.NSD,1);
            y(m+1,:) = x;
    end
end