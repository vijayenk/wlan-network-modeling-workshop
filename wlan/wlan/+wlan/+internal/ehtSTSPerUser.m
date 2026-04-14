function y = ehtSTSPerUser(psdu,scramInitBits,postFECPaddingBits,ruSize,params)
%ehtSTSPerUser Encode, parse and map bits to create space-time streams
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = ehtSTSPerUser(PSDU,SCRAMINITBITS,POSTFECPADDINGBITS,RUSIZE,PARAMS)
%   performs scrambling, encoding, stream parsing, segment parsing,
%   interleaving, constellation mapping and segment deparsing to form
%   complex encoded symbols representing the space-time stream for a user.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

% SERVICE = [scrambler init = 0; Reserved = 0;]; IEEE P802.11be/D1.5, Section 36.3.13.1
serviceBits = zeros(11+5,1,'int8');
payload = [serviceBits; psdu];

% Pre-FEC padding
preFECPaddedData = [payload; zeros(params.NPADPreFECPHY,1,'int8')];

% Scrambling
scrambData = wlan.internal.ehtScramble(preFECPaddedData,scramInitBits);

if params.ChannelCoding==wlan.type.ChannelCoding.bcc
    % BCC encoding
    numTailBits = 6;
    encodedData = wlanBCCEncode([scrambData; zeros(numTailBits,1,'int8')],params.Rate);
else
    % LDPC encoding
    cfg = wlan.internal.heLDPCParameters(params);
    encodedData = wlan.internal.ldpcEncode(scrambData,cfg);
end

% Post-FEC padding
postFECpaddedData = postFECPadding(encodedData,postFECPaddingBits,params); % NCBPS*NSYM

% Parse encoded data into streams
streamParsedData = wlanStreamParse(postFECpaddedData,params.NSS,params.NCBPS,params.NBPSCS); % NCBPSS*NSYM-by-NSS where NCSPSS->(NCBPS/NSS)

% Halve the RU size defined for CBW80, CBW160, and CBW320 for EHT DUP
% (MCS-14). Segment parsing and constellation mapping is performed on bits
% required for half the RU size for the given channel bandwidth. The
% remaining half of the RU has symbols generated from frequency domain
% duplication as defined in Section 36.3.13.10 of IEEE P802.11be/D1.5.
if params.EHTDUPMode
    ruSize = ruSize/2;
end

% Segment parsing
if sum(ruSize)>=1480 % Parsing is applicable for MRU/RU size >= 996+484
    [parsedData,p] = wlan.internal.ehtSegmentParseBits(streamParsedData,params.NCBPS,params.NBPSCS,ruSize,params.DCM); % NCBPSS*NSYM-by-NSS (for the L)
    L = size(parsedData,2); % Number of 80 MHz frequency segments/blocks
    ruSize80MHzSubblock = p.RUSizePer80MHz; % RU size per 80 MHz segment
    ncbpssl = p.Ncbpssl; % NumParsing is applicable for MRU/RU size >= 996+484. NCBPSSL of coded bits per spatial streams per frequency segments/blocks
else % No segment parsing
    L = 1; % Number of 80 MHz frequency segments/blocks
    ncbpssl = params.NCBPS/params.NSS; % Number of coded bits per spatial stream
    parsedData = {streamParsedData}; % NSD*NSYM-by-NSS
    ruSize80MHzSubblock = sum(ruSize); % Sum RUs if its an MRU
end

% BCC interleaving (if applicable)
if params.ChannelCoding==wlan.type.ChannelCoding.bcc
    % BCC interleaving
    assert(L==1); % BCC only valid for RU<=242 therefore 1 segment. IEEE P802.11be/D1.5, Section 36.3.13.3.1
    NCBPSSI = params.NCBPS/params.NSS/L;
    interleavedData = {wlan.internal.heBCCInterleave(parsedData{1},ruSize80MHzSubblock(1),params.NBPSCS,NCBPSSI,params.DCM,params.NCBPSLAST)}; % NCBPSS*NSYM-by-NSS
else % LDPC
    interleavedData = parsedData;
end

dataSym = cell(1,L);
for l=1:L
    % Reshape to form OFDM symbols
    interleavedSym = reshape(interleavedData{l},ncbpssl(l),params.NSYM,params.NSS); % NCBPSS*NSYM-by-NSS (for L=1) or Ncbpssl-by-NSYM-by-NSS (for L>1)
    % Constellation mapping (with optional DCM)
    dataSym{l} = wlan.internal.heConstellationMap(interleavedSym,params.NBPSCS,params.DCM); % NSD-by-NSYM-by-NSS
end

% LDPC tone mapping (if applicable)
mappedData = cell(1,L);
if params.ChannelCoding==wlan.type.ChannelCoding.bcc
    mappedData = dataSym;
else % LDPC
    for l=1:L
        dataSymPerSegment = coder.nullcopy(complex(zeros(size(dataSym{l}))));
        mappingInd = wlan.internal.ehtLDPCToneMappingIndices(ruSize80MHzSubblock(l),params.DCM);
        dataSymPerSegment(mappingInd,:,:) = dataSym{l};
        mappedData{l} = dataSymPerSegment; % Nsd-by-Nsym-by-Nss
    end
end

% Frequency segment deparsing
if sum(ruSize)>=1480 % Deparsing is applicable for MRU/RU size >= 996+484
    y = ehtSegmentDeparseSymbols(mappedData,L); % NSD-by-NSYM-by-NSS for all L
else
    y = mappedData{1};
end

% Frequency domain duplication for EHT DUP mode, MCS-14 as defined in
% Section 36.3.13.10 of IEEE P802.11be/D1.5
if params.EHTDUPMode
    halfColumnLength = size(y,1)/2;
    y = [y; y(1:halfColumnLength,:,:)*-1; y(1+halfColumnLength:end,:,:)]; % Equation 36-78 and 36-79
end

end

function postFECpaddedData = postFECPadding(encodedData,postFECpadBits,params)
    NSYM = params.NSYM;
    NDBPS = params.NDBPS;
    Rate = params.Rate;
    mSTBC = params.mSTBC;
    NCBPS = params.NCBPS;

    % Information from IEEE 802.11-15/0810
        
    % Boundary of last OFDM symbol(s) to pad
    if params.ChannelCoding==wlan.type.ChannelCoding.bcc
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

function y = ehtSegmentDeparseSymbols(x,L)
%ehtSegmentDeparseSymbols Segment deparser of data subcarriers
%
%   Y = segmentDeparseSymbols(X) performs segment deparsing on the
%   input X.
%
%   Y is an array of size Nsd-by-Nsym-by-Nss containing the deparsed
%   frequency segments for all subblocks, L. Nsd is the number of data
%   subcarriers, Nsym is the number of OFDM symbols, and Nss is the number
%   of spatial streams.
%
%   X is a cell array of size L, where each cell is of size
%   Nsd-by-Nsym-by-Nss containing the frequency segments to deparse.
%
%   L is the number of frequency subblocks.

y = zeros(false,0);
coder.varsize('y',[3920 396 8],[1 1 1]); % For Codegen
for l=1:L
   y = [y; x{l}]; %#ok<AGROW>
end

end
