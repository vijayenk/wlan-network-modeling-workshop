function softBits = dmgHeaderDemap(sym,noiseVarEst,varargin)
%dmgHeaderDemap DMG Header field Demodulation for OFDM, SC and Control PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   SOFTBITS = dmgHeaderDemap(SYM,NOISEVAREST,CFGDMG) performs demapping of
%   the symbols SYM given the noise variance NOISEVAREST and the DMG
%   configuration object CFGDMG.
%
%   SOFTBITS = dmgHeaderDemap(SYM,NOISEVAREST,CSI,CFGDMG) performs
%   demapping of the symbols with additional CSI information. The CSI can
%   only be used for the OFDM PHY.

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

switch phyType(cfgDMG) % Validation and input parsing
    case 'SC'
        % Validate input size for SC PHY
        Ngi = 64; % Number of samples in guard interval
        blkSize = 512; % Number of samples in block
        Nblks = 2;
        numDataSymPerBlk = blkSize-Ngi; % Block size
        if any(size(sym,1) ~= numDataSymPerBlk)
            coder.internal.error('wlan:shared:IncorrectSCNsym',size(sym,1));
        end
        if any(size(sym,2) < Nblks)
            coder.internal.error('wlan:shared:IncorrectSCNblks',Nblks,size(sym,2));
        end
        sym = sym(:,1:Nblks); % Extract the minimum input signal length required to process the SC PHY
    case 'OFDM'
        % Validate input size for OFDM PHY
        ofdmInfo = wlan.internal.dmgOFDMInfo();
        if any(size(sym,1) ~= ofdmInfo.NSD)
            coder.internal.error('wlan:shared:IncorrectOFDMSC',size(sym,1));
        end
        
        % Validate CSI input
        if csiFlag
            validateattributes(csi,{'double'},{'real','column','finite'},mfilename,'CSI');
            if size(csi,1) ~= ofdmInfo.NSD
                coder.internal.error('wlan:shared:InvalidCSISize',size(csi,1));
            end
        end
        sym = sym(:,1); % Extract the minimum input signal length required to process the OFDM PHY
    otherwise
        % Validate input size for Control PHY
        headerIndex = wlanFieldIndices(cfgDMG,'DMG-Header');
        headerLength = headerIndex(2)-headerIndex(1)+1; % Header field length
        SF = 32; % Spreading factor
        minInputLength = double(headerLength/SF);
        if size(sym,1) < minInputLength
            coder.internal.error('wlan:shared:IncorrectControlSym',minInputLength,size(sym,1));
        end
        sym = sym(1:minInputLength,1); % Extract the minimum input signal length required to process the Control PHY
end

switch phyType(cfgDMG) % Demapping
    case 'OFDM'
        [k,pk] = wlan.internal.dmgTonePairingIndices('Static');
        if nargin==3 % No CSI
            softBits = wlan.internal.dmgQPSKDemodulate(sym,noiseVarEst,k,pk);
        else % with CSI
            softBits = wlan.internal.dmgQPSKDemodulate(sym,noiseVarEst,k,pk,csi);
        end
    case 'SC'    
        % Constellation demodulation, pi/2-BPSK
        % Remove pi/2 rotation
        sym = wlan.internal.dmgDerotate(sym);
        demodHeader1 = wlanConstellationDemap(sym((1:448).'),noiseVarEst,1);
        demodHeader2 = wlanConstellationDemap(-sym(448+(1:448).'),noiseVarEst,1);
        softBits = demodHeader1+demodHeader2;
    otherwise % Control PHY
        % DBPSK demodulation
        softBits = wlan.internal.dbpskDemodulate(sym,noiseVarEst);
end

end
