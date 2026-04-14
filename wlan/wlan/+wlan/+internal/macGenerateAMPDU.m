function [ampdu, frameLength, ampduBits] = macGenerateAMPDU(mpduList, macConfig, phyConfig, varargin)
%macGenerateAMPDU Generate an A-MPDU with the given MPDUs
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [AMPDU, FRAMELENGTH] = macGenerateAMPDU(MPDULIST,MACCONFIG,PHYCONFIG)
%   generates an A-MPDU with the MPDUs given in the MPDULIST.
%
%   AMPDU is the aggregation of given MPDUs, returned as a uint8 typed
%   decimal column vector or binary-valued column vector.
%
%   FRAMELENGTH is the PSDU length for an HT format A-MPDU and APEP length
%   for a VHT format A-MPDU, returned as the number of octets.
%
%   MPDULIST is the list of MPDUs, specified as a cell array of uint8 typed
%   decimal column vectors or binary-valued column vectors where each
%   vector represents an MPDU.
% 
%   MACCONFIG is the frame configuration object of type <a href="matlab:help('wlanMACFrameConfig')">wlanMACFrameConfig</a>.
%
%   PHYCONFIG is an object of type <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>, 
%   <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>, or <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> matching the FrameFormat 
%   specified in the MACCONFIG object.
%
%   [..., AMPDUBITS] = macGenerateAMPDU(...) outputs A-MPDU bits in
%   addition to the output arguments described above.
%
%   [...] = macGenerateAMPDU(...,Name=Value) specifies additional
%   name-value arguments described below. When a name-value pair is not
%   specified, its default value is used.
%
%   'InputFormat'   - Specify the format of input MPDUs. If input MPDUs
%                     are uint8 typed decimal octet vectors, specify this
%                     value as 'octets'. If input MPDUs are uint8 typed
%                     binary-valued vectors, specify this value as 'bits'.
%                     The default value is 'octets'.
%
%   'OutputFormat'  - Specify the format of output AMPDU. To generate AMPDU
%                     as uint8 typed decimal vector, specify this value as
%                     'octets'. To generate AMPDU as uint8 typed
%                     binary-valued vector, specify this value as 'bits'.
%                     The default value is 'octets'.

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

narginchk(3, 7);

if isa(phyConfig, 'wlanNonHTConfig')
    % Checking non-HT config for codegen
    ampdu = uint8([]);
    frameLength = 0;
    return;
end

% Validate NV pairs
[inputFormat, outputFormat] = validateNVPairs(varargin);

% Get number of A-MPDU subframes to be prepared
numMPDUs = numel(mpduList);

% Refer section 9.3.1.9.3 in Std IEEE 802.11-2016. A maximum of 64
% subframes are allowed in an HT/VHT A-MPDU that requires a response, a
% maximum of 256 subframes in an HE A-MPDU that requires a response, and a
% maximum of 1024 subframes in an EHT A-MPDU that requires a response.
% AMPDU expects Block Acknowledgment (BA) frame as an acknowledgment. The
% size of acknowledgment bitmap in BA is limited to 64-bits for HT/VHT
% frames, 256-bits for HE frames, and 1024-bits for EHT frames (Each bit
% represents acknowledgment of an AMPDU subframe). Maximum number of MPDUs
% are limited in an A-MPDU because of this bitmap.
if strcmp(macConfig.FrameFormat, "EHT-SU")
  maxMPDUs = 1024;
elseif any(strcmp(macConfig.FrameFormat, {'HE-SU','HE-EXT-SU'}))
  maxMPDUs = 256;
else % 'HT-Mixed', 'VHT'
  maxMPDUs = 64;
end

if (numMPDUs > maxMPDUs) && ~strcmp(macConfig.AckPolicy, 'No Ack')
  if macConfig.MSDUAggregation
    coder.internal.error('wlan:wlanMACFrame:AMPDUWithAMSDUsLimitExceeded', macConfig.FrameFormat, maxMPDUs);
  else
    coder.internal.error('wlan:wlanMACFrame:AMPDUWithMSDUsLimitExceeded', macConfig.FrameFormat, maxMPDUs);
  end
end

subFrame = cell(1, numMPDUs);

psduLengthCounter = 0;
frameLength = 0;

for i = 1:numMPDUs
  mpdu = mpduList{i};

  if strcmp(inputFormat, 'octets')
    % Convert decimal octets to bits
    mpdu =  uint8(reshape(de2biOptimized(mpduList{i}, 8)', [], 1));
  else
    if isrow(mpdu)
      mpdu = mpdu';
    end
  end

  mpduLen = size(mpdu,1); 

  % Non-final subframe
  if (i ~= numMPDUs)
    % Generate delimiter of the MPDU
    mpduDelimiter = generateMPDUDelimiter(macConfig.FrameFormat, mpduLen/8, false);
    mpduDelimiterLen = 32; % Number of bits in MPDU delimiter
    
    % Each non-final A-MPDU subframe in an A-MPDU may have padding octets
    % appended to make the subframe a multiple of 4 octets (32-bits) in length
    padLen = wnet.internal.padLength((mpduLen+mpduDelimiterLen), 32);
    nonFinalSubFrame = [mpduDelimiter; mpdu; zeros(padLen,1,'uint8')];

    % Calculate minimum MPDU start spacing between consecutive MPDUs
    minSpacePadding = wlan.internal.macMinimumMPDUSpacingOctets(macConfig.MinimumMPDUStartSpacing, phyConfig, numel(nonFinalSubFrame)/8);
    % Add minimum start space padding
    ampduSubFrame = addZeroDelimiterPadding(nonFinalSubFrame, minSpacePadding, 0);
    psduLengthCounter = psduLengthCounter + numel(ampduSubFrame)/8;
    
  else % Final subframe
    if isa(phyConfig, 'wlanHTConfig')
      % Generate delimiter for the final MPDU in the A-MPDU
      mpduDelimiter = generateMPDUDelimiter(macConfig.FrameFormat, mpduLen/8, false);
        
      ampduSubFrame = [mpduDelimiter; mpdu];
      psduLengthCounter = psduLengthCounter + numel(ampduSubFrame)/8;
      validateFrameLength(psduLengthCounter, macConfig.FrameFormat);
      frameLength = psduLengthCounter;
      
    else % VHT, HE-SU, HE-EXT-SU, EHT-SU
      if numMPDUs == 1
        % Set EOF bit in the delimiter for S-MPDU
        eof = 1;
      else
        eof = 0;
      end
      
      % Generate delimiter for the final MPDU in the A-MPDU
      mpduDelimiter = generateMPDUDelimiter(macConfig.FrameFormat, mpduLen/8, eof);
      
      % Add padding for final subframe in case of VHT/HE frames      
      padLen = wnet.internal.padLength(mpduLen, 32);
      finalSubFrame = [mpduDelimiter; mpdu; zeros(padLen,1,'uint8')];
      psduLengthCounter = psduLengthCounter + numel(finalSubFrame)/8;
      validateFrameLength(psduLengthCounter, macConfig.FrameFormat);
      
      % Return APEP length
      frameLength = psduLengthCounter;
      userIndexSU = 1; % Assume single user
      if isa(phyConfig, 'wlanEHTMUConfig')
          phyConfig.User{userIndexSU}.APEPLength = frameLength;
      else
          phyConfig.APEPLength = frameLength;
      end

      % Get PSDU length corresponding to the APEP length and PHY
      % configuration. PHY configuration returns PSDU length as an array
      % representing the PSDU length of each user in case of multi-user.
      % Get PSDU length of the single user.
      if isa(phyConfig, 'wlanEHTMUConfig')
        % For codegen: psduLength returns a 1xn sized variable vector.
        tmp = phyConfig.psduLength;
        psduLengthCounter = tmp(1);
      elseif isa(phyConfig, 'wlanHESUConfig')
        % For codegen: getPSDULength returns a 1xn sized variable vector.
        tmp = phyConfig.getPSDULength;
        psduLengthCounter = tmp(1);
      else
        psduLengthCounter = phyConfig.PSDULength(1);
      end
      
      % The difference between PSDU length and APEP length must be filled
      % with the EOF padding.
      % EOF_padding = (PSDU_Length - APEP_Length)
      eofPadding = psduLengthCounter - frameLength;
      
      % Add EOF Padding for VHT/HE A-MPDU
      % For a VHT/HE A-MPDU, EOF Padding includes the following:
      % 1) EOF padding subframes: One or more zero-delimiters indicating EOF
      % 2) EOF padding octets: [0 - 3] octets after EOF subframes
      %
      % Refer Section: 9.7.1 in Std IEEE 802.11-2016.
      ampduSubFrame = addZeroDelimiterPadding(finalSubFrame, eofPadding, 1);
    end
  end
  subFrame{i} = ampduSubFrame;
end

% Append all subframes to an array to form A-MPDU
% Pre-allocate the buffer for A-MPDU 
ampduBits = zeros(psduLengthCounter*8, 1);
pos = 1;
for i = 1:numMPDUs
  % Add each subframe to the A-MPDU buffer
  % Note: Last subframe includes EOF padding in case of VHT A-MPDU
  ampduBits(pos : pos+numel(subFrame{i})-1) = subFrame{i};
  pos = pos + numel(subFrame{i});
end

if strcmp(outputFormat, 'octets')
  % Convert bits to decimal octets
  ampdu = uint8(wnet.internal.bits2octets(ampduBits, false));
else
  ampdu = ampduBits;
end
end

% Return an MPDU delimiter for given frame-format and frame-length
function mpduDelimiter = generateMPDUDelimiter(frameFormat, mpduLength, eof)
  persistent crcCfg

  if isempty(crcCfg)
    crcCfg = crcConfig(Polynomial=[8 2 1 0], InitialConditions=[1 1 1 1 1 1 1 1], DirectMethod=true, FinalXOR=1);
  end

  % Delimiter Signature (8-bits) (Constant value - 0x4E)
  delimiterSignature = [0;1;1;1;0;0;1;0];

  if strcmp(frameFormat, 'HT-Mixed')    
    % Reserved (4-bits)
    reserved = zeros(4, 1);

    % MPDU Length (12-bits)
    mpduLength = de2biOptimized(mpduLength, 12)';

    % Add CRC (8-bits)
    mpduDelimiter = crcGenerate([reserved; mpduLength], crcCfg);
  else % VHT, HE-SU, HE-EXT-SU, EHT-SU
    % Reserved (1-bit)
    reserved = 0;

    % MPDU Length (14-bits)
    tmp = de2biOptimized(mpduLength, 14)';
    mpduLength = [tmp(13:14); tmp(1:12)];

    % Add CRC (8-bits)
    mpduDelimiter = crcGenerate([double(eof); reserved; mpduLength], crcCfg);
  end
  mpduDelimiter = uint8([mpduDelimiter; delimiterSignature]);
end

% Add zero-delimiter padding to the given subframe
function paddedSubFrame = addZeroDelimiterPadding(subFrame, reqPadding, eof)
  delimiterLength = 4;

  % Zero-Delimiter and EOF Zero-Delimiter are constant for any MPDU. Refer
  % Figure 9-744 in Std IEEE 802.11-2016.
  if eof
    % EOF zero delimiter - [1; 0; 121; 78]
    delimiter = [1;0;0;0;0;0;0;0;zeros(8, 1);1;0;0;1;1;1;1;0;0;1;1;1;0;0;1;0];
  else
    % Zero delimiter - [0; 0; 20; 78]
    delimiter = [zeros(16, 1);0;0;1;0;1;0;0;0;0;1;1;1;0;0;1;0];
  end
  % Add zero-delimiters as padding if required padding is greater than or
  % equal to delimiter length.
  numReqDelimiters = floor(reqPadding/delimiterLength);

  delimiterPadding = repmat(delimiter, numReqDelimiters, 1);

  % Update the remaining length of padding after adding the zero-delimiters
  reqPadding = reqPadding - numReqDelimiters*delimiterLength;
  % Add [0 - 3] octets zero padding
  if reqPadding > 0
    paddedSubFrame = [subFrame; delimiterPadding; zeros(reqPadding*8,1,'uint8')];
  else
    paddedSubFrame = [subFrame; delimiterPadding];
  end
end

% Validate frame-length limits
% Refer Table 9-19 in Std IEEE 802.11-2016
function validateFrameLength(ampduLength, frameFormat)
  maxHTAMPDULength = 65535;
  maxVHTAMPDULength = 1048575;
  maxHEAMPDULength = 6500631;
  maxEHTAMPDULength = 15523198;

  % HT format A-MPDU length validation
  coder.internal.errorIf(strcmp(frameFormat, 'HT-Mixed') && (ampduLength > maxHTAMPDULength), 'wlan:wlanMACFrame:HTAMPDUSizeExceeded');

  % VHT format A-MPDU length validation
  coder.internal.errorIf(strcmp(frameFormat, 'VHT') && (ampduLength > maxVHTAMPDULength), 'wlan:wlanMACFrame:VHTAMPDUSizeExceeded');

  % HE format A-MPDU length validation
  coder.internal.errorIf(any(strcmp(frameFormat, {'HE-SU', 'HE-EXT-SU'})) && (ampduLength > maxHEAMPDULength), 'wlan:wlanMACFrame:HEAMPDUSizeExceeded');

  % EHT format A-MPDU length validation
  coder.internal.errorIf(strcmp(frameFormat, 'EHT-SU') && (ampduLength > maxEHTAMPDULength), 'wlan:wlanMACFrame:EHTAMPDUSizeExceeded');
end

% Validate input name-value pairs
function [inputFormat, outputFormat] = validateNVPairs(nvArgs)

  % Default values
  defaultParams = struct('InputFormat', 'octets', 'OutputFormat', 'octets');
  expectedFormatValues = {'bits', 'octets'};

  if numel(nvArgs) == 0
    useParams = defaultParams;
  else
    % Extract each P-V pair
    if isempty(coder.target) % Simulation path
      p = inputParser;

      % Get values for the P-V pair or set defaults for the optional arguments
      addParameter(p, 'InputFormat', defaultParams.InputFormat);
      % Get values for the P-V pair or set defaults for the optional arguments
      addParameter(p, 'OutputFormat', defaultParams.OutputFormat);
      % Parse inputs
      parse(p, nvArgs{:});

      useParams = p.Results;

    else % Codegen path
      pvPairs = struct('InputFormat', uint32(0), 'OutputFormat', uint32(0));

      % Select parsing options
      popts = struct('PartialMatching', true);

      % Parse inputs
      pStruct = coder.internal.parseParameterInputs(pvPairs, popts, nvArgs{:});

      % Get values for the P-V pair or set defaults for the optional arguments
      useParams = struct;
      useParams.InputFormat = coder.internal.getParameterValue(pStruct.InputFormat, defaultParams.InputFormat, nvArgs{:});
      useParams.OutputFormat = coder.internal.getParameterValue(pStruct.OutputFormat, defaultParams.OutputFormat, nvArgs{:});
    end
  end

  inputFormat = validatestring(useParams.InputFormat, expectedFormatValues, mfilename);
  outputFormat = validatestring(useParams.OutputFormat, expectedFormatValues, mfilename);
end

function bin = de2biOptimized(dec, n)
    bin = comm.internal.utilities.de2biBase2RightMSB(double(dec), n);
end