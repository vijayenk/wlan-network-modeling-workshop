function c = heTimingRelatedConstants(varargin)
%heTimingRelatedConstants HE timing related constants
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   P = heTimingRelatedConstants(CFG) returns a structure containing timing
%   related constants as per IEEE Std 802.11ax-2021, Table 27-12.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>, or 
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>.
%
%   P = heTimingRelatedConstants(GI,LTFDURATION,PREFECPADDINGFACTOR,NPP,NUMOFDMSYM)
%   returns timing related constants given the guard interval, LTF
%   duration, Pre-FEC padding factor, Nominal packet padding duration and
%   Number of OFDM symbols. The Nominal packet padding duration and Number
%   of OFDM symbols are needed for PE duration calculation

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

nominalPacketPadding = 0; % For codegen
preFECPaddingFactor = 0;
NumOFDMSym = 0;
if nargin==1
    cfg = varargin{1};
    GI = cfg.GuardInterval;
    LTFDuration = cfg.HELTFType;
    if ~isa(cfg,'wlanHERecoveryConfig')
        calcTPEflag = 1;
        paddingParams = wlan.internal.heCodingParameters(cfg);
        preFECPaddingFactor = paddingParams.PreFECPaddingFactor;
        nominalPacketPadding = wlan.internal.heNominalPacketPadding(cfg);
        NumOFDMSym = paddingParams.NSYM;
    else
        calcTPEflag = 0;
    end
else
    GI = varargin{1};
    LTFDuration = varargin{2};
    preFECPaddingFactor  = varargin{3};
    if nargin>4
        calcTPEflag = 1;
        nominalPacketPadding = varargin{4};
        NumOFDMSym = varargin{5};
    else
        calcTPEflag = 0;
    end
end

c = struct;

% Times in ns. IEEE Std 802.11ax-2021, Table 27-12. The time in us is
% converted to ns, this is to avoid inaccuracies in the calculation of
% L-SIG length due to the ceil operation in IEEE Std 802.11ax-2021,
% Equation 27-11.
TDFTPreHE = 3200;
c.TDFTPreHE = TDFTPreHE;
TDFTHE = 12800;
c.TDFTHE = TDFTHE;
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

TSYM1 = TDFTHE+TGI1Data;
TSYM2 = TDFTHE+TGI2Data;
TSYM4 = TDFTHE+TGI4Data;
c.TSYM1 = TSYM1;
c.TSYM2 = TSYM2;
c.TSYM4 = TSYM4;

switch GI
    case 0.8
        TGIHELTF = TGI1Data;
        c.TGIData = TGI1Data;
        c.TSYM = TSYM1;
    case 1.6
        TGIHELTF = TGI2Data;
        c.TGIData = TGI2Data;
        c.TSYM = TSYM2;
    otherwise % 3.2
        TGIHELTF = TGI4Data;
        c.TGIData = TGI4Data;
        c.TSYM = TSYM4;
end
c.TGIHELTF = TGIHELTF;

c.TLSTF = 10*TDFTPreHE/4;
c.TLLTF = 2*TDFTPreHE+TGILLTF;
c.TLSIG = 4000;
c.TRLSIG = 4000;
c.THESIGA = 8000;
c.THESIGAR = 16000;
c.THESTFT = 8000;
c.THESTFNT = 4000;
THELTF1X = 3200;
THELTF2X = 6400;
THELTF4X = 12800;
c.THELTF1X = THELTF1X;
c.THELTF2X = THELTF2X;
c.THELTF4X = THELTF4X;

switch LTFDuration
    case 1
        THELTF = THELTF1X;
    case 2
        THELTF = THELTF2X;
    otherwise % 4
        THELTF = THELTF4X;
end
c.THELTF = THELTF;
c.THELTFSYM = THELTF+TGIHELTF;
c.THESIGB = TDFTPreHE+TGILegacyPreamble;
c.TSYML = 4000;
c.TPE = 0;

if calcTPEflag
    % IEEE Std 802.11ax-2021, Table 27.46
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
        end
    end

    if (NumOFDMSym~=0)
        TPE = max(TPEnominal);
    else
        TPE = 4000; % NDP 
    end

    c.TPE = TPE;
    
end
