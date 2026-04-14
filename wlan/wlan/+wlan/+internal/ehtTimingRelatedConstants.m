function c = ehtTimingRelatedConstants(varargin)
%ehtTimingRelatedConstants EHT timing related constants
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   P = ehtTimingRelatedConstants(CFG) returns a structure containing
%   timing related constants as per IEEE 802.11be/D2.0, Table 36-18
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or 
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>
%
%   P = ehtTimingRelatedConstants(CBW,GI,LTFDURATION,PREFECPADDINGFACTOR,NPP,NUMOFDMSYM)
%   returns timing related constants given the channel bandwidth, guard
%   interval, LTF duration, Pre-FEC padding factor, Nominal packet padding
%   duration and Number of OFDM symbols. The Nominal packet padding
%   duration and Number of OFDM symbols are needed for PE duration
%   calculation

%   Copyright 2022 The MathWorks, Inc.

%#codegen

NumOFDMSym = 0;
if nargin==1
    cfg = varargin{1};
    GI = cfg.GuardInterval;
    LTFDuration = cfg.EHTLTFType;
    calcTPEflag = 1;
    paddingParams = wlan.internal.ehtCodingParameters(cfg);
    preFECPaddingFactor = paddingParams.PreFECPaddingFactor;
    nominalPacketPadding = wlan.internal.heNominalPacketPadding(cfg);
    NumOFDMSym = paddingParams.NSYM;
    chanBW = cfg.ChannelBandwidth;
else
    chanBW = varargin{1};
    GI = varargin{2};
    LTFDuration = varargin{3};
    preFECPaddingFactor  = varargin{4};
    if nargin>5
        calcTPEflag = 1;
        nominalPacketPadding = varargin{5};
        NumOFDMSym = varargin{6};
    else
        calcTPEflag = 0;
    end
end

c = struct;

% The time in us is converted to ns, this is to avoid inaccuracies in the
% calculation of L-SIG length due to the ceil operation.
TDFTPreEHT = 3200;
c.TDFTPreEHT = TDFTPreEHT;
TDFTEHT = 12800;
c.TDFTEHT = TDFTEHT;
TGILegacyPreamble = 800;
c.TGILegacyPreamble = TGILegacyPreamble;
TGILLTF = 1600;
c.TGILLTF = TGILLTF;

TGI1Data = 800;
TGI2Data = 1600;
TGI4Data = 3200;
c.TGI1Data = TGI1Data;
c.TGI2Data = TGI2Data;
c.TGI4Data = TGI4Data;

TSYM1 = TDFTEHT+TGI1Data;
TSYM2 = TDFTEHT+TGI2Data;
TSYM4 = TDFTEHT+TGI4Data;
c.TSYM1 = TSYM1;
c.TSYM2 = TSYM2;
c.TSYM4 = TSYM4;

switch GI
    case 0.8
        TGIEHTLTF = TGI1Data;
        c.TGIData = TGI1Data;
        c.TSYM = TSYM1;
    case 1.6
        TGIEHTLTF = TGI2Data;
        c.TGIData = TGI2Data;
        c.TSYM = TSYM2;
    otherwise % 3.2
        TGIEHTLTF = TGI4Data;
        c.TGIData = TGI4Data;
        c.TSYM = TSYM4;
end
c.TGIEHTLTF = TGIEHTLTF;

c.TLSTF = 10*TDFTPreEHT/4;
c.TLLTF = 2*TDFTPreEHT+TGILLTF;
c.TLSIG = 4000;
c.TRLSIG = 4000;
c.TUSIG = 8000;
c.TEHTSIG = 4000;
c.TEHTSTFT = 8000; % EHT-STF for EHT TB
c.TEHTSTFNT = 4000;
TEHTLTF1X = 3200;
TEHTLTF2X = 6400;
TEHTLTF4X = 12800;
c.TEHTLTF1X = TEHTLTF1X;
c.TEHTLTF2X = TEHTLTF2X;
c.TEHTLTF4X = TEHTLTF4X;

switch LTFDuration
    case 1
        TEHTLTF = TEHTLTF1X;
    case 2
        TEHTLTF = TEHTLTF2X;
    otherwise % 4
        TEHTLTF = TEHTLTF4X;
end
c.TEHTLTF = TEHTLTF;
c.TEHTLTFSYM = TEHTLTF+TGIEHTLTF;
c.TEHTSIG = TDFTPreEHT+TGILegacyPreamble;
c.TSYML = 4000;
c.TPE = 0;

if calcTPEflag
    % IEEE P802.11be/D2.0, Table 36-61
    TPEnominal = zeros(size(nominalPacketPadding));

    for u = 1:numel(nominalPacketPadding)
        switch nominalPacketPadding(u)
            case 0
                switch preFECPaddingFactor
                    case 1
                        TPEnominal(u) = 0;
                    case 2
                        TPEnominal(u) = 0;
                    case 3
                        TPEnominal(u) = 0;
                    case 4
                        TPEnominal(u) = 0;
                end
            case 8
                switch preFECPaddingFactor
                    case 1
                        TPEnominal(u) = 0;
                    case 2
                        TPEnominal(u) = 0;
                    case 3
                        TPEnominal(u) = 4000;
                    case 4
                        TPEnominal(u) = 8000;
                end
            case 16
                switch preFECPaddingFactor
                    case 1
                        TPEnominal(u) = 4000;
                    case 2
                        TPEnominal(u) = 8000;
                    case 3
                        TPEnominal(u) = 12000;
                    case 4
                        TPEnominal(u) = 16000;
                end
            otherwise % 20 us
                switch preFECPaddingFactor
                    case 1
                        TPEnominal(u) = 8000;
                    case 2
                        TPEnominal(u) = 12000;
                    case 3
                        TPEnominal(u) = 16000;
                    case 4
                        TPEnominal(u) = 20000;
                end
        end
    end

    if (NumOFDMSym~=0)
        TPE = max(TPEnominal);
    else
        % NDP
        if wlan.internal.cbwStr2Num(chanBW)==320 % CBW320
            TPE = 8000; % IEEE P802.11be/D2.0, Section 36.3.14
        else
            TPE = 4000;
        end
    end
    c.TPE = TPE;
end