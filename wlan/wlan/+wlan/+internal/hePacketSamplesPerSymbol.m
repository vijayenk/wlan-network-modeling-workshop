function [Y,trc] = hePacketSamplesPerSymbol(cfg,varargin)
%hePacketSamplesPerSymbol Samples per symbol information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   [Y, TRC] = hePacketSamplesPerSymbol(CFG) returns a structure containing
%   information including the number of samples per symbol in the packet,
%   and a structure TRC containing the field timing parameters.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   [Y, TRC] = hePacketSamplesPerSymbol(CFG,OSF) returns information given
%   the oversampling factor OSF. When not specified 1 is assumed.

%   Copyright 2017-2023 The MathWorks, Inc.

%#codegen

osf = 1;
if nargin>1
    osf = varargin{1};
end

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
sf = cbw*1e-3*osf; % Scaling factor to convert bandwidth and time in ns to samples

if isa(cfg,'wlanHETBConfig')
    [trc,numDataSym] = wlan.internal.heTBTimingRelatedConstants(cfg);
else
    commonCodingParams = wlan.internal.heCodingParameters(cfg);
    numDataSym = commonCodingParams.NSYM;
    npp = wlan.internal.heNominalPacketPadding(cfg);
    trc = wlan.internal.heTimingRelatedConstants(cfg.GuardInterval,cfg.HELTFType,commonCodingParams.PreFECPaddingFactor,npp,commonCodingParams.NSYM);
end

% For each format calculate the number of samples per symbol and CP in the
% preamble fields which are format dependent
if isa(cfg,'wlanHEMUConfig')
    allocationInfo = ruInfo(cfg);
    numSIGASym = 2;
    sigbInfo = wlan.internal.heSIGBCodingInfo(cfg);
    numSIGBSym = sigbInfo.NumSymbols;
    numHELTFSym = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU));
    samplesPerSymbolPreamble = [trc.THESIGA/numSIGASym*ones(1,numSIGASym) trc.THESIGB*ones(1,numSIGBSym) trc.THESTFNT];
    cpLengthPreamble = [trc.TGILegacyPreamble*ones(1,2) trc.TGILegacyPreamble*ones(1,numSIGBSym) 0];
elseif isa(cfg,'wlanHESUConfig')
    numHELTFSym = wlan.internal.numVHTLTFSymbols(cfg.NumSpaceTimeStreams);
    switch packetFormat(cfg)
        case 'HE-SU'
            numSIGASym = 2;
            samplesPerSymbolPreamble = [trc.THESIGA/numSIGASym*ones(1,numSIGASym) trc.THESTFNT];
            cpLengthPreamble = [trc.TGILegacyPreamble*ones(1,2) 0];
        otherwise % 'HE-EXT-SU'
            numSIGASym = 4;
            samplesPerSymbolPreamble = [trc.THESIGAR/numSIGASym*ones(1,numSIGASym) trc.THESTFNT];
            cpLengthPreamble = [trc.TGILegacyPreamble*ones(1,4) 0];
    end
else % HE-TB
    numSIGASym = 2;
    numHELTFSym = cfg.NumHELTFSymbols;
    samplesPerSymbolPreamble = [trc.THESIGA/numSIGASym*ones(1,numSIGASym) trc.THESTFT];
    cpLengthPreamble = [trc.TGILegacyPreamble*ones(1,2) 0];
end

% Midamble periodicity. IEEE P802.11ax/D4.1, Section 27.3.11.16
Mma = cfg.MidamblePeriodicity;
Nma = wlan.internal.numMidamblePeriods(cfg,numDataSym); % Midamble period
if Nma>0  
    nonCPData = trc.TSYM*ones(1,numDataSym);
    nonCPHELTF = trc.THELTFSYM*ones(1,numHELTFSym);
    % Reshape data symbols till last midamble in to data symbol blocks
    data = reshape(nonCPData(1:Mma*Nma),Mma,Nma);
    % Repeat HELTF symbols for each data symbol block
    heLTF = repmat(nonCPHELTF,Nma,1).';
    % Append midamble after each data symbol block
    dataWithHELTF = [data; heLTF];
    % Reshape and append leftover data samples after the last midamble
    samplesPerSymbolData = [dataWithHELTF(:).' nonCPData(Mma*Nma+1:end)];
    
    % Cyclic prefix field
    cpLengthData = trc.TGIData*ones(1,numDataSym+numHELTFSym*Nma);
else
    samplesPerSymbolData = trc.TSYM*ones(1,numDataSym);
    cpLengthData = trc.TGIData*ones(1,numDataSym);
end

if numDataSym>0
    % Create a vector of the samples per symbol
    samplesPerSymbol = [trc.TLSTF trc.TLLTF trc.TLSIG trc.TRLSIG ...
        samplesPerSymbolPreamble ...
        trc.THELTFSYM*ones(1,numHELTFSym) ...
        samplesPerSymbolData(1:end-1) samplesPerSymbolData(end)+trc.TPE]*sf;
else
    % Create a vector of the samples per symbol
    samplesPerSymbol = [trc.TLSTF trc.TLLTF trc.TLSIG trc.TRLSIG ...
        samplesPerSymbolPreamble ...
        trc.THELTFSYM*ones(1,numHELTFSym-1) (trc.THELTFSYM+trc.TPE)]*sf;
end

% Create a vector of the CP per symbol
cpPerSymbol = [0 trc.TGILLTF trc.TGILegacyPreamble trc.TGILegacyPreamble ...
    cpLengthPreamble ...
    trc.TGIHELTF*ones(1,numHELTFSym) ...
    cpLengthData]*sf;

numPPDUSamples = sum(samplesPerSymbol);
Y = struct('NumSamplesPerSymbol', samplesPerSymbol, ...
           'CPPerSymbol', cpPerSymbol, ...
           'ExtensionPerSymbol', [zeros(1,length(samplesPerSymbol)-1) trc.TPE*sf], ...
           'NumPacketSamples', numPPDUSamples);

end
