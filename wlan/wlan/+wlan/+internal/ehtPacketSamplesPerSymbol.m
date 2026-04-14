function [Y,trc] = ehtPacketSamplesPerSymbol(cfg,osf)
%ehtPacketSamplesPerSymbol Samples per symbol information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y,TRC] = ehtPacketSamplesPerSymbol(CFG,OSF) returns a structure
%   containing information including the number of samples per symbol in
%   the packet, and a structure TRC containing the field timing parameters.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or 
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.
%
%   OSF is the oversampling factor.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen
cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
sf = cbw*1e-3*osf; % Scaling factor to convert bandwidth and time in ns to samples

% Calculate the number of samples per symbol and CP in the preamble fields
allocationInfo = ruInfo(cfg);
numUSIGSym = 2;
isEHTTB = isa(cfg,'wlanEHTTBConfig');
if isEHTTB
    [trc,numDataSym] = wlan.internal.ehtTBTimingRelatedConstants(cfg);
    numEHTLTFSym = cfg.NumEHTLTFSymbols;
    samplesPerSymbolPreamble = [trc.TUSIG/numUSIGSym*ones(1,numUSIGSym) trc.TEHTSTFT];
    cpLengthPreamble = [trc.TGILegacyPreamble*ones(1,2) 0];
else % EHT MU
    commonCodingParams = wlan.internal.ehtCodingParameters(cfg);
    numDataSym = commonCodingParams.NSYM;
    npp = wlan.internal.heNominalPacketPadding(cfg);
    trc = wlan.internal.ehtTimingRelatedConstants(cfg.ChannelBandwidth,cfg.GuardInterval,cfg.EHTLTFType,commonCodingParams.PreFECPaddingFactor,npp,commonCodingParams.NSYM);

    sigInfo = wlan.internal.ehtSIGCodingInfo(cfg);
    numEHTSIGSym = sigInfo.NumSIGSymbols;
    numEHTLTFSym = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU))+cfg.NumExtraEHTLTFSymbols;
    samplesPerSymbolPreamble = [trc.TUSIG/numUSIGSym*ones(1,numUSIGSym) trc.TEHTSIG*ones(1,numEHTSIGSym) trc.TEHTSTFNT];
    cpLengthPreamble = [trc.TGILegacyPreamble*ones(1,2) trc.TGILegacyPreamble*ones(1,numEHTSIGSym) 0];
end

samplesPerSymbolData = trc.TSYM*ones(1,numDataSym);
cpLengthData = trc.TGIData*ones(1,numDataSym);

if numDataSym>0
    % Create a vector of the samples per symbol
    samplesPerSymbol = [trc.TLSTF trc.TLLTF trc.TLSIG trc.TRLSIG ...
        samplesPerSymbolPreamble ...
        trc.TEHTLTFSYM*ones(1,numEHTLTFSym) ...
        samplesPerSymbolData(1:end-1) samplesPerSymbolData(end)+trc.TPE]*sf;
else
    % Create a vector of the samples per symbol
    samplesPerSymbol = [trc.TLSTF trc.TLLTF trc.TLSIG trc.TRLSIG ...
        samplesPerSymbolPreamble ...
        trc.TEHTLTFSYM*ones(1,numEHTLTFSym-1) (trc.TEHTLTFSYM+trc.TPE)]*sf;
end

% Create a vector of the CP per symbol
cpPerSymbol = [0 trc.TGILLTF trc.TGILegacyPreamble trc.TGILegacyPreamble ...
    cpLengthPreamble ...
    trc.TGIEHTLTF*ones(1,numEHTLTFSym) ...
    cpLengthData]*sf;

if any(floor(cpPerSymbol)~=cpPerSymbol)
    error('The specified oversampling factor %f results in a non-integer cyclic prefix length',osf)
end

numPPDUSamples = sum(samplesPerSymbol);
Y = struct('NumSamplesPerSymbol',samplesPerSymbol, ...
           'CPPerSymbol',cpPerSymbol, ...
           'ExtensionPerSymbol', [zeros(1,length(samplesPerSymbol)-1) trc.TPE*sf], ...
           'NumPacketSamples',numPPDUSamples);
end
