function y = heSTSPerUser(psdu,scramInitBits,postFECPaddingBits,ruSize,params)
%heSTSPerUser Encode, parse and map bits to create space-time streams
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heSTSPerUser(PSDU,SCRAMINITBITS,POSTFECPADDINGBITS,RUSIZE,PARAMS)
%   performs scrambling, encoding, stream parsing, segment parsing,
%   interleaving, constellation mapping and segment deparsing to form
%   complex encoded symbols representing the space-time stream for a user.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

% SERVICE = [scrambler init = 0; Reserved = 0;]; IEEE Std 802.11ax-2021, Section 27.3.12.3
serviceBits = zeros(7+9,1,'int8');
payload = [serviceBits; psdu];

% Pre-FEC padding
preFECPaddedData = [payload; zeros(params.NPADPreFECPHY,1,'int8')];

% Scrambling
scrambData = wlanScramble(preFECPaddedData,scramInitBits);

if strcmp(params.ChannelCoding,'BCC')
    % BCC encoding
    numTailBits = 6;
    encodedData = wlanBCCEncode([scrambData; zeros(numTailBits,1,'int8')],params.Rate);
else
    % LDPC encoding
    cfg = wlan.internal.heLDPCParameters(params);
    encodedData = wlan.internal.ldpcEncode(scrambData,cfg);
end

% Post-FEC padding
postFECpaddedData = postFECPadding(encodedData,postFECPaddingBits,params);

% Parse encoded data into streams
streamParsedData = wlanStreamParse(postFECpaddedData,params.NSS,params.NCBPS,params.NBPSCS) ;

% Segment parsing
if ruSize==2*996
    nes = 1; % Only 1 encoder stream in 11ax
    parsedData = wlan.internal.segmentParseBitsCore(streamParsedData,nes,params.NCBPS,params.NBPSCS);
else
    parsedData = streamParsedData;
end
numSeg = size(parsedData,3);

% BCC interleaving (if applicable)
if strcmp(params.ChannelCoding,'BCC')
    % BCC interleaving
    numSeg = 1; % BCC only valid for RU<=242 therefore 1 segment. IEEE Std 802.11ax-2021, Section 27.3.12.8
    NCBPSSI = params.NCBPS/params.NSS/numSeg;
    interleavedData = wlan.internal.heBCCInterleave(parsedData,ruSize,params.NBPSCS,NCBPSSI,params.DCM,params.NCBPSLAST);
else % LDPC
    interleavedData = parsedData;
end

% Reshape to form OFDM symbols   
interleavedSym = reshape(interleavedData,params.NCBPS/(params.NSS*numSeg),params.NSYM,params.NSS,numSeg);

% Constellation mapping (with optional DCM)
dataSym = wlan.internal.heConstellationMap(interleavedSym,params.NBPSCS,params.DCM); % [Nsd,Nsym,Nss]

% LDPC tone mapping (if applicable)
if strcmp(params.ChannelCoding,'BCC')
    mappedData = dataSym;
else % LDPC
    % LDPC tone mapping
    mappingInd = wlan.internal.heLDPCToneMappingIndices(ruSize,params.DCM);
    mappedData = coder.nullcopy(complex(zeros(size(dataSym))));
    mappedData(mappingInd,:,:,:) = dataSym;
end

% Frequency segment deparsing
if ruSize==2*996 % NOT 80+80
    ssPerUser = wlan.internal.segmentDeparseSymbolsCore(mappedData); % [Nsd,Nsym,Nss]
else
    ssPerUser = mappedData(:,:,:,1); % index for codegen
end

% STBC encoding
if params.mSTBC==2
    numSTS = 2*params.NSS;
    y = wlan.internal.stbcEncode(ssPerUser,numSTS);  % [Nsd,Nsym,Nsts]
else
    y = ssPerUser;
end

end

function postFECpaddedData = postFECPadding(encodedData,postFECpadBits,params)
    NSYM = params.NSYM;
    NDBPS = params.NDBPS;
    Rate = params.Rate;
    mSTBC = params.mSTBC;
    NCBPS = params.NCBPS;
    ChannelCoding = params.ChannelCoding;

    % Information from IEEE 802.11-15/0810
        
    % Boundary of last OFDM symbol(s) to pad
    if strcmp(ChannelCoding,'BCC')
        % This allows us to deal with the case where interleaver pads one
        % bit per symbol when NCBPS~=NDBPS/rate. This isn't so for LDPC and
        % the majority of BCC configurations.
        bitsPerSymbol = (NDBPS/Rate);
    else
        bitsPerSymbol = NCBPS;
    end
    lastSymbolStartOffset = bitsPerSymbol*(NSYM-mSTBC);
    
    % The following assumes we still need to add the extra interleave
    % padding to the last mSTBC symbols too if the pre-FEC padding boundary
    % is 4, that is the last symbol is just like a normal symbol. If we try
    % and extract the last NCBPSLAST bits then we might actually only have
    % NCBPSLAST-1 bits as the BCC interleaving will add an extra.
    
    % Extract the data bits for the last OFDM symbol(s)
    symBits = encodedData(lastSymbolStartOffset+1:end); % End due to above
 
    lastSymPaddedBits = [reshape(symBits,[],mSTBC); postFECpadBits]; % [] due to above
    postFECpaddedData = [encodedData(1:lastSymbolStartOffset); lastSymPaddedBits(:)];
end
