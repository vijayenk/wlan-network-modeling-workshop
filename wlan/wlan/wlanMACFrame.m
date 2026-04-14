function [frame, frameLength] = wlanMACFrame(varargin)
%wlanMACFrame WLAN MAC frame generation (MPDU or A-MPDU)
%   [FRAME,FRAMELENGTH] = wlanMACFrame(MACCONFIG) generates a WLAN MAC
%   frame for the specified frame configuration.
%
%   FRAME is the generated MAC frame, returned as a character array where
%   each row contains the hexadecimal representation of an octet or an int8
%   typed binary column vector.
%
%   FRAMELENGTH is the PSDU length of the frame for Non-HT and HT format
%   frames. For VHT, HE, or EHT format frames, FRAMELENGTH specifies the
%   APEP length. The function returns this value as the number of octets.
%
%   MACCONFIG is an object of type wlanMACFrameConfig.
%
%   [FRAME,FRAMELENGTH] = wlanMACFrame(PAYLOAD,MACCONFIG) generates a MAC
%   frame containing the specified PAYLOAD for frames of type 'Data' and
%   'QoS Data'. For other frame types, the function does not use the
%   PAYLOAD input.
%
%   PAYLOAD represents one or more MSDUs. For non-aggregated frames,
%   PAYLOAD is a single MSDU specified as one of these types:
%       - A character vector representing octets in hexadecimal format
%       - A string scalar representing octets in hexadecimal format
%       - A numeric vector, where each element is in the range [0, 255]
%         inclusive, representing octets in decimal format
%       - An n-by-2 character array, where each row represents an octet in
%         hexadecimal format
%   For aggregated frames, PAYLOAD can contain multiple MSDUs specified as
%   one of these types:
%       - A cell array of character vectors, where each vector is an MSDU
%       - A string vector, where each element is an MSDU
%       - A cell array of numeric vectors, where each vector is an MSDU
%
%   [FRAME,FRAMELENGTH] = wlanMACFrame(PAYLOAD,MACCONFIG,PHYCONFIG)
%   generates a MAC frame containing the specified PAYLOAD for VHT, HE, or 
%   EHT SU format frames and HT format aggregated frames.
%
%   PHYCONFIG is an object of type wlanHTConfig, wlanVHTConfig, 
%   wlanHESUConfig, or wlanEHTMUConfig which must match the FrameFormat 
%   value specified in the MACCONFIG input. When FrameFormat is set to
%   "EHT-SU" in the MACCONFIG, the wlanEHTMUConfig must indicate the
%   configuration for a single user transmission. The function uses PHY
%   configuration PHYCONFIG for ensuring that the frame does not exceed the
%   transmission time limit, for EOF padding in VHT, HE, or EHT format
%   frames, and for maintaining minimum start spacing between the MPDUs in
%   an A-MPDU. The function uses the PHYCONFIG input only when generating
%   VHT, HE, or EHT format frames and HT format aggregated frames.
%
%   [FRAME,FRAMELENGTH] = wlanMACFrame(MACCONFIG,PHYCONFIG) generates a MAC
%   trigger frame. PHYCONFIG is an object of type wlanNonHTConfig, used for
%   calculating the padding required for trigger frame.
%
%   [FRAME,FRAMELENGTH] = wlanMACFrame(...,OutputFormat=FORMAT) specifies
%   the output format based on FORMAT. To generate the MAC frame as a
%   character array in which each row represents an octet in hexadecimal
%   format, specify FORMAT as 'octets'. To generate the MAC frame as an
%   int8 binary-valued column vector, specify FORMAT as 'bits'. The default
%   value is 'octets'.

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

narginchk(1, 5);
% Validate inputs
[payload, macConfig, phyConfig, outputFormat] = validateInputs(varargin{:});

% Handle MPDU frame generation
if strcmp(macConfig.FrameType, 'QoS Data')
  if macConfig.MPDUAggregation
    % A-MPDU generation
    [frameOctets, frameLength] = generateAMPDU(payload, macConfig, phyConfig);
    
    % Validate transmission time of the frame with the given PHY
    % configuration. Non-HT config is not applicable for A-MPDU, but
    % checking for codegen support.
    if isa(phyConfig, 'wlanEHTMUConfig')
      userIndexSU = 1; % Assume single user
      phyConfig.User{userIndexSU}.APEPLength = frameLength;
    elseif isa(phyConfig, 'wlanVHTConfig') || isa(phyConfig, 'wlanHESUConfig')
      phyConfig.APEPLength = frameLength;
    else % isa(phyConfig, 'wlanHTConfig') || isa(phyConfig, 'wlanNonHTConfig')
      phyConfig.PSDULength = frameLength;
    end
    validateConfig(phyConfig, 'MCS');
    
  elseif macConfig.MSDUAggregation
    % QoS Data with A-MSDU
    amsdu = generateAMSDU(payload, macConfig);
    frameOctets = wlan.internal.macGenerateMPDU(amsdu, macConfig, phyConfig);
    frameLength = numel(frameOctets);
    
    % Validate transmission time of the frame with the given PHY
    % configuration
    if isa(phyConfig, 'wlanHTConfig')
      phyConfig.PSDULength = frameLength;
      validateConfig(phyConfig, 'MCS');
    end
    
  else
    data = [];
    % For codegen
    if ~isempty(payload)
      data = payload{1};
    end
    
    % QoS Data with MSDU
    frameOctets = wlan.internal.macGenerateMPDU(data, macConfig, phyConfig);
    frameLength = numel(frameOctets);
  end
  
elseif strcmp(macConfig.FrameType, 'Data')
  data = [];
  % For codegen
  if ~isempty(payload)
    data = payload{1};
  end
  
  % QoS Data with MSDU
  frameOctets = wlan.internal.macGenerateMPDU(data, macConfig, phyConfig);
  frameLength = numel(frameOctets);

else
  % All other frames (without higher-layer payload)
  frameOctets = wlan.internal.macGenerateMPDU([], macConfig, phyConfig);
  frameLength = numel(frameOctets);
end

if strcmp(outputFormat, 'bits')
    frame = int8(int2bit(frameOctets, 8, false));
else
    frame = dec2hex(frameOctets, 2);
end
end

% Generate an A-MSDU frame
function amsdu = generateAMSDU(payload, macConfig)
    % Number of MSDUs in the payload input
    numMSDUs = numel(payload);

    % Create a list of MSDU structures, containing MSDU payload, DA, SA and
    % Mesh Control field (if present) of the A-MSDU subframes
    msduList = cell(1, numMSDUs);
    subframeStruct = struct('MSDU', [], 'DestinationAddress', char(''), ...
        'SourceAddress', char(''), 'MeshTTL', [], 'MeshSequenceNumber', uint32([]), ...
        'AddressExtensionMode', 0, 'Address4', char(''), 'Address5', char(''), 'Address6', char(''));
    for i = 1:numMSDUs
        subframeStruct.MSDU = payload{i};
        subframeStruct.DestinationAddress = macConfig.AMSDUDestinationAddress(i, :);
        subframeStruct.SourceAddress = macConfig.AMSDUSourceAddress(i, :);
        if macConfig.HasMeshControl
            subframeStruct.MeshTTL = macConfig.MeshTTL(i);
            subframeStruct.MeshSequenceNumber = macConfig.MeshSequenceNumber(i);
            subframeStruct.AddressExtensionMode = macConfig.AddressExtensionMode;
            if macConfig.AddressExtensionMode == 1
                % Address4 is present in Mesh Control field in A-MSDU
                % subframe header instead of MAC header, when
                % AddressExtensionMode is 1 and ToDS is 0 and FromDS is 1
                subframeStruct.Address4 = macConfig.Address4(i, :);
            elseif macConfig.AddressExtensionMode == 2
                % Address5 and Address6 are present in Mesh Control field
                % in A-MSDU subframe header, when AddressExtensionMode is 2
                subframeStruct.Address5 = macConfig.Address5(i, :);
                subframeStruct.Address6 = macConfig.Address6(i, :);
            end
        end
        msduList{i} = subframeStruct;
    end
    % Generate an A-MSDU frame
    amsdu = wlan.internal.macGenerateAMSDU(msduList, macConfig);
end

% Generate an A-MPDU frame
function [ampdu, frameLength] = generateAMPDU(payloadInput, macConfig, phyConfig)
    % Maximum length of HT format A-MSDU
    maxHTAMSDULength = 4065;
    % Maximum length of a VHT or HE format A-MSDU
    maxHEorVHTAMSDULength = 11424;

    % Considering empty cell array as a zero-sized MSDU
    if isempty(payloadInput)
        payload = {[]};
    else
        payload = payloadInput;
    end
    
    % Initialize count
    numMPDUs = 0;
    % Number of MSDUs given in the payload
    numMSDUs = numel(payload);

    % Include A-MSDUs in the A-MPDU
    if macConfig.MSDUAggregation
        % A-MSDU subframe header length
        amsduSubframeHdrLength = 14;
        % Mesh Control field has a fixed length of 6 octets and variable
        % length of 0, 6 or 12 octets.
        meshControlOverhead = 6 + macConfig.AddressExtensionMode*6;
        if macConfig.HasMeshControl
            amsduSubframeHdrLength = amsduSubframeHdrLength + meshControlOverhead;
        end

        if strcmp(macConfig.FrameFormat, 'HT-Mixed')
            maxAMSDULength = maxHTAMSDULength;
        else
            maxAMSDULength = maxHEorVHTAMSDULength;
        end

        % HT Control takes up 4 octets in the MAC header
        if macConfig.HTControlPresent
            maxAMSDULength = maxAMSDULength - 4;
        end

        amsduLength = 0;

        % For codegen
        msduList = repmat({struct('MSDU', [], 'DestinationAddress', char(''), ...
            'SourceAddress', char(''), 'MeshTTL', [], 'MeshSequenceNumber', uint32([]), ...
            'AddressExtensionMode', 0, 'Address4', char(''), 'Address5', char(''), 'Address6', char(''))}, 1, numMSDUs);

        msduCount = 0;
        mpduList = cell(1, 0);
        subframeStruct = struct('MSDU', [], 'DestinationAddress', char(''), ...
            'SourceAddress', char(''), 'MeshTTL', [], 'MeshSequenceNumber', uint32([]), ...
            'AddressExtensionMode', 0, 'Address4', char(''), 'Address5', char(''), 'Address6', char(''));

        for i = 1:numMSDUs
            msduCount = msduCount + 1;
            subframeStruct.MSDU = payload{i};
            subframeStruct.DestinationAddress = macConfig.AMSDUDestinationAddress(i, :);
            subframeStruct.SourceAddress = macConfig.AMSDUSourceAddress(i, :);
            if macConfig.HasMeshControl
                subframeStruct.MeshTTL = macConfig.MeshTTL(i);
                subframeStruct.MeshSequenceNumber = macConfig.MeshSequenceNumber(i);
                subframeStruct.AddressExtensionMode = macConfig.AddressExtensionMode;
                if macConfig.AddressExtensionMode == 1
                    % Address4 is present in Mesh Control field in A-MSDU
                    % subframe header instead of MAC header, when
                    % AddressExtensionMode is 1 and ToDS is 0 and FromDS is 1
                    subframeStruct.Address4 = macConfig.Address4(i, :);
                elseif macConfig.AddressExtensionMode == 2
                    % Address5 and Address6 are present in Mesh Control field
                    % in A-MSDU subframe header, when AddressExtensionMode is 2
                    subframeStruct.Address5 = macConfig.Address5(i, :);
                    subframeStruct.Address6 = macConfig.Address6(i, :);
                end
            end
            msduList{msduCount} = subframeStruct;
            amsduLength = amsduLength + numel(payload{i}) + amsduSubframeHdrLength;

            if (i == numMSDUs) || ((amsduLength + numel(payload{i+1}) + amsduSubframeHdrLength) > maxAMSDULength)
                % For codegen
                amsduSubFrames = cell(1, msduCount);
                for j = 1:numel(amsduSubFrames)
                    amsduSubFrames{j} = msduList{j};
                end

                % Generate MPDU containing A-MSDU
                numMPDUs = numMPDUs + 1;
                amsdu = wlan.internal.macGenerateAMSDU(amsduSubFrames, macConfig);
                mpduList{end+1} = wlan.internal.macGenerateMPDU(amsdu, macConfig, phyConfig);

                % Increment sequence number for the next MPDU
                macConfig.SequenceNumber = mod((macConfig.SequenceNumber + 1), 4096);

                % Continue forming A-MSDUs until all the given input MSDUs
                % are finished
                amsduLength = 0;
                msduCount = 0;
            end
        end
        [ampdu, frameLength] = wlan.internal.macGenerateAMPDU(mpduList, macConfig, phyConfig);

    else % Form A-MPDU, without MSDU aggregation
        % Each MSDU will be put into an MPDU. So, (num of MSDUs) = (num of
        % MPDUs)
        numMPDUs = numMSDUs;

        % Initialize for codegen
        mpduList = cell(1, numMPDUs);
        meshTTL = zeros(numMSDUs, 1);
        meshSequenceNumbers = zeros(numMSDUs, 1, 'uint32');
        meshControlAddress4 = repmat('0', numMSDUs, 12);
        meshControlAddress5 = repmat('0', numMSDUs, 12);
        meshControlAddress6 = repmat('0', numMSDUs, 12);

        % Store per MSDU mesh parameters
        if macConfig.HasMeshControl
            meshTTL = macConfig.MeshTTL;
            meshSequenceNumbers = macConfig.MeshSequenceNumber;
            if macConfig.AddressExtensionMode == 1
                meshControlAddress4 = macConfig.Address4;
            elseif macConfig.AddressExtensionMode == 2
                meshControlAddress5 = macConfig.Address5;
                meshControlAddress6 = macConfig.Address6;
            end
        end

        % Generate individual MPDUs to be put into the A-MPDU
        for i = 1:numMPDUs
            % Get the MSDU
            msdu = payload{i};

            % Get MeshTTL and MeshSequenceNumber of the MSDU
            if macConfig.HasMeshControl
                macConfig.MeshTTL = meshTTL(i);
                macConfig.MeshSequenceNumber = meshSequenceNumbers(i);
                if macConfig.AddressExtensionMode == 1
                    % Address4 is present in Mesh Control field instead of MAC header, when
                    % AddressExtensionMode is 1 and ToDS is 0 and FromDS is 1
                    macConfig.Address4 = meshControlAddress4(i, :);
                elseif macConfig.AddressExtensionMode == 2
                    % Address5 and Address6 are present in Mesh Control
                    % field when AddressExtensionMode is 2
                    macConfig.Address5 = meshControlAddress5(i, :);
                    macConfig.Address6 = meshControlAddress6(i, :);
                end
            end

            mpduList{i} = wlan.internal.macGenerateMPDU(msdu, macConfig, phyConfig);

            % Increment sequence number for the next MPDU
            macConfig.SequenceNumber = mod((macConfig.SequenceNumber + 1), 4096);
        end
        [ampdu, frameLength] = wlan.internal.macGenerateAMPDU(mpduList, macConfig, phyConfig);
    end
end

% Validate input arguments
function [payload, macConfig, phyConfig, outputFormat] = validateInputs(varargin)
    payloadLength = 0;
    maxMSDULength = 2304;

    % Function signature: wlanMACFrame(macConfig)
    if nargin == 1
        % Validate MAC frame configuration input
        coder.internal.errorIf(~isa(varargin{1}, 'wlanMACFrameConfig') || (numel(varargin{1}) > 1), 'wlan:wlanMACFrame:MACConfigRequired');
        macConfig = varargin{1};
        payload = {};
        outputFormat = 'octets';

        if coder.target('MATLAB')
            phyConfig = [];
        else % Codegen path
            % For codegen: assign default PHY configuration
            phyConfig = wlanVHTConfig;
        end

        % Payload is required to generate 'Data' or 'QoS Data' frames
        coder.internal.errorIf(any(strcmp(macConfig.FrameType, {'Data', 'QoS Data'})), ...
            'wlan:wlanMACFrame:PayloadInputRequired');
        isTriggerFrame = strcmp(macConfig.FrameType, 'Trigger');
        coder.internal.errorIf(isTriggerFrame, 'wlan:wlanMACFrame:NonHTConfigRequired');

    % Function signatures:
    %   wlanMACFrame(payload, macConfig)
    %   wlanMACFrame(macConfig, phyConfig)
    %   wlanMACFrame(payload, macConfig, phyConfig)
    %   wlanMACFrame(macConfig, 'OutputFormat', format)
    %   wlanMACFrame(macConfig, phyConfig, 'OutputFormat', format)
    %   wlanMACFrame(payload, macConfig, 'OutputFormat', format)
    %   wlanMACFrame(payload, macConfig, phyConfig, 'OutputFormat', format)
    else
        % Function signatures:
        %   wlanMACFrame(payload, macConfig)
        %   wlanMACFrame(payload, macConfig, phyConfig)
        %   wlanMACFrame(payload, macConfig, 'OutputFormat', format)
        %   wlanMACFrame(payload, macConfig, phyConfig, 'OutputFormat', format)
        if isa(varargin{2}, 'wlanMACFrameConfig')
            validateattributes(varargin{2}, {'wlanMACFrameConfig'}, {'scalar'}, 'wlanMACFrame', 'MAC frame configuration object');
            macConfig = varargin{2};
            payloadInput = varargin{1};
            if (nargin >= 4)
                outputFormat = validateNVPair(varargin{nargin-1:nargin});
            else
                outputFormat = 'octets';
            end

        else
          % Function_signature: 
          %   wlanMACFrame(macConfig, phyConfig)
          %   wlanMACFrame(macConfig, 'OutputFormat', format)
          %   wlanMACFrame(macConfig, phyConfig, 'OutputFormat', format)

            coder.internal.errorIf(~isa(varargin{1}, 'wlanMACFrameConfig') || (numel(varargin{1}) > 1), 'wlan:wlanMACFrame:InvalidFunctionSignature');
            macConfig = varargin{1};
            % Payload is required to generate 'Data' or 'QoS Data' frames
            coder.internal.errorIf(any(strcmp(macConfig.FrameType, {'Data', 'QoS Data'})), ...
                'wlan:wlanMACFrame:PayloadInputRequired');
            coder.internal.errorIf((nargin > 4), 'wlan:wlanMACFrame:InvalidFunctionSignature');

            payloadInput = [];
            switch nargin
                case 2
                    outputFormat = 'octets';
                case 3
                    outputFormat = validateNVPair(varargin{2:3});
                otherwise % nargin = 4
                    outputFormat = validateNVPair(varargin{3:4});
            end
        end
        
        % Validate payload
        if iscell(payloadInput) || isstring(payloadInput)
            % Number of MSDUs in the payload input
            numMSDUs = numel(payloadInput);

            % Single MSDU is expected for non-aggregated frame
            coder.internal.errorIf((strcmp(macConfig.FrameType, 'Data') || (strcmp(macConfig.FrameType, 'QoS Data') && ...
                (strcmp(macConfig.FrameFormat, 'Non-HT') && ~macConfig.MSDUAggregation))) && ...
                (numMSDUs > 1), 'wlan:wlanMACFrame:SingleMSDUExpected');
            coder.internal.errorIf((strcmp(macConfig.FrameType, 'QoS Data') && ...
                (strcmp(macConfig.FrameFormat, 'HT-Mixed') && ~macConfig.MPDUAggregation && ...
                ~macConfig.MSDUAggregation)) && (numMSDUs > 1), 'wlan:wlanMACFrame:SingleMSDUExpected');

            % Convert given payload into decimal octets and update the frame
            % length
            payload = cell(1, numMSDUs);
            for i = 1:numMSDUs
                if iscell(payloadInput)
                    msdu = payloadInput{i};
                    coder.internal.errorIf(isstring(msdu), 'wlan:wlanMACFrame:StringInCellNotAccepted');
                else % string
                    msdu = payloadInput(i);
                end
                msduOctets = validatePayloadFormat(msdu);
                coder.internal.errorIf(numel(msduOctets) > maxMSDULength, 'wlan:wlanMACFrame:MSDUSizeExceededMultiple', i);
                payloadLength = payloadLength + numel(msduOctets);
                payload{i} = msduOctets;
            end

        else
            payload = cell(1, 1);
            payload{1} = validatePayloadFormat(payloadInput);
            payloadLength = numel(payload{1});
            coder.internal.errorIf(payloadLength > maxMSDULength, 'wlan:wlanMACFrame:MSDUSizeExceededSingle');
        end

        % Validate ToDS and FromDS setting for mesh data frames
        if macConfig.IsMeshFrame && strcmp(macConfig.FrameType, 'QoS Data')
            coder.internal.errorIf(~macConfig.FromDS, 'wlan:wlanMACFrame:InvalidFromDS');
            % Validate ToDS and FromDS setting based on Address1
            bits = bitget(hex2dec(macConfig.Address1(1:2)), 1:8);
            isGroupAddress = bits(1); % Group bit
            if isGroupAddress
                coder.internal.errorIf(~(~macConfig.ToDS && macConfig.FromDS), 'wlan:wlanMACFrame:InvalidToDSFromDSGroupAddress');
            else
                coder.internal.errorIf(~(macConfig.ToDS && macConfig.FromDS), 'wlan:wlanMACFrame:InvalidToDSFromDSUnicastAddress');
            end
        end

        % Number of MSDUs in the payload input
        numMSDUs = 0;
        if ~isempty(payloadInput)
            if iscell(payloadInput) || isstring(payloadInput)
                numMSDUs = numel(payloadInput);
            else
                numMSDUs = 1;
            end
        end

        % Validate MeshTTL and MeshSequenceNumber parameters if HasMeshControl
        % flag is set to true.
        if macConfig.HasMeshControl
            % Single MSDU
            if numMSDUs == 1
                % MeshTTL and MeshSequenceNumber are expected to be scalars
                coder.internal.errorIf(~isscalar(macConfig.MeshTTL), 'wlan:wlanMACFrame:ScalarMeshParameterExpected', 'MeshTTL');
                coder.internal.errorIf(~isscalar(macConfig.MeshSequenceNumber), 'wlan:wlanMACFrame:ScalarMeshParameterExpected', 'MeshSequenceNumber');

            elseif numMSDUs > 1
                if isscalar(macConfig.MeshTTL)
                    % Use the same value of MeshTTL for all MSDUs if scalar is given
                    macConfig.MeshTTL = repmat(macConfig.MeshTTL, numMSDUs, 1);
                else
                    % MeshTTL is expected to be a vector with number of elements
                    % same as number of MSDUs
                    coder.internal.errorIf(~isvector(macConfig.MeshTTL) || ~(numel(macConfig.MeshTTL) == numMSDUs), ...
                        'wlan:wlanMACFrame:MeshParameterSizeMismatch', 'MeshTTL');
                end

                if isscalar(macConfig.MeshSequenceNumber)
                    meshSequenceNumber = zeros(numMSDUs, 1, 'uint32');
                    meshSequenceNumber(1) = macConfig.MeshSequenceNumber;
                    % Increment for the subsequent MSDUs
                    for seqNumIdx = 2:numMSDUs
                        meshSequenceNumber(seqNumIdx) = mod((meshSequenceNumber(seqNumIdx - 1) + 1), intmax('uint32'));
                    end
                    macConfig.MeshSequenceNumber = meshSequenceNumber;
                else
                    % MeshSequenceNumber is expected to be a vector with number of elements
                    % same as number of MSDUs
                    coder.internal.errorIf(~isvector(macConfig.MeshSequenceNumber) || ...
                        ~(numel(macConfig.MeshSequenceNumber) == numMSDUs), ...
                        'wlan:wlanMACFrame:MeshParameterSizeMismatch', 'MeshSequenceNumber');
                end
            end
        end

        % Validate AMSDUSourceAddress and AMSDUDestinationAddress, if MSDUAggregation
        % is enabled
        if macConfig.MSDUAggregation
            macConfig = validateAddressField(macConfig, numMSDUs, 'AMSDUDestinationAddress');
            macConfig = validateAddressField(macConfig, numMSDUs, 'AMSDUSourceAddress');
        end

        % Validate AddressExtensionMode and additional addresses (Address4, Address5 and Address6)
        if strcmp(macConfig.FrameType, 'QoS Data') && macConfig.IsMeshFrame
            % AddressExtensionMode must be set to 1 only when ToDS is false
            % and FromDS is true
            coder.internal.errorIf(~(~macConfig.ToDS && macConfig.FromDS) && macConfig.AddressExtensionMode == 1, ...
                'wlan:wlanMACFrame:InvalidAddressExtModeValue1');
            % AddressExtensionMode must be set to 2 only when both ToDS and
            % FromDS are set to true
            coder.internal.errorIf(~(macConfig.ToDS && macConfig.FromDS) && macConfig.AddressExtensionMode == 2, ...
                'wlan:wlanMACFrame:InvalidAddressExtModeValue2');
            if macConfig.AddressExtensionMode == 1
                % Address4 is present in Mesh Control field when AddressExtensionMode is set to 1
                macConfig = validateAddressField(macConfig, numMSDUs, 'Address4');
            elseif macConfig.AddressExtensionMode == 2
                % Address5 and Address6 are present in Mesh Control field when AddressExtensionMode is set to 2
                macConfig = validateAddressField(macConfig, numMSDUs, 'Address5');
                macConfig = validateAddressField(macConfig, numMSDUs, 'Address6');
            end
        end

        isAggregatedFrame = strcmp(macConfig.FrameType, 'QoS Data') && (any(strcmp(macConfig.FrameFormat, {'VHT', 'HE-SU', 'HE-EXT-SU', 'EHT-SU'})) || ...
                (strcmp(macConfig.FrameFormat, 'HT-Mixed') && (macConfig.MSDUAggregation || macConfig.MPDUAggregation)));
        isTriggerFrame = strcmp(macConfig.FrameType, 'Trigger');

        % PHY configuration
        if (nargin >= 2) && ~isstring(varargin{2}) && ~ischar(varargin{2})
            if ~isa(varargin{2}, 'wlanMACFrameConfig')
                % Function signatures:
                %   wlanMACFrame(macConfig, phyConfig)
                %   wlanMACFrame(macConfig, phyConfig, 'OutputFormat', format)

                phyConfig = varargin{2};
                validatePHYConfig(macConfig, phyConfig);
            elseif (nargin >= 3) && ~isstring(varargin{3}) && ~ischar(varargin{3})
                % Function signatures:
                %   wlanMACFrame(payload, macConfig, phyConfig)
                %   wlanMACFrame(payload, macConfig, phyConfig, 'OutputFormat', format)

                phyConfig = varargin{3};
                validatePHYConfig(macConfig, phyConfig);
            else
                % Function signatures:
                %   wlanMACFrame(payload, macConfig)
                %   wlanMACFrame(payload, macConfig, 'OutputFormat', format)

                coder.internal.errorIf(isAggregatedFrame, 'wlan:wlanMACFrame:PHYConfigRequired');
                coder.internal.errorIf(isTriggerFrame, 'wlan:wlanMACFrame:NonHTConfigRequired');
                if coder.target('MATLAB')
                    phyConfig = [];
                else % Codegen path
                    % For codegen: assign default PHY configuration
                    phyConfig = wlanVHTConfig;
                end
            end
        else
            % Function signatures:
            %   wlanMACFrame(macConfig, 'OutputFormat', format)

            coder.internal.errorIf(isAggregatedFrame, 'wlan:wlanMACFrame:PHYConfigRequired');
            coder.internal.errorIf(isTriggerFrame, 'wlan:wlanMACFrame:NonHTConfigRequired');
            
            if coder.target('MATLAB')
                phyConfig = [];
            else % Codegen path
                % For codegen: assign default PHY configuration
                phyConfig = wlanVHTConfig;
            end
        end
    end
    
    % Validate the MAC trigger configuration
    if isTriggerFrame
        cfgTrigger = macConfig.TriggerConfig;
        validateConfig(cfgTrigger);
        % See section 9.3.1.22.1 of IEEE Std 802.11ax-2021
        coder.internal.errorIf(((cfgTrigger.NumUserInfo > 1) || ((cfgTrigger.NumUserInfo == 1) && any(cfgTrigger.UserInfo{1}.AID12 == [0,2045])) || strcmp(cfgTrigger.TriggerType, 'MU-RTS')) ...
            && ~strcmp(macConfig.Address1, 'FFFFFFFFFFFF'), 'wlan:wlanMACFrame:TriggerBroadcastExpected');
    end

    if any(strcmp(macConfig.FrameFormat, {'VHT', 'HE-SU', 'HE-EXT-SU', 'EHT-SU'})) && strcmp(macConfig.FrameType, 'QoS Data')
        % VHT, HE, and EHT format data frames are always sent as A-MPDUs
        macConfig.MPDUAggregation = true;
    elseif strcmp(macConfig.FrameFormat, 'Non-HT')
        % Non-HT format frame cannot be an A-MPDU
        macConfig.MPDUAggregation = false;
        % Non-HT format frames do not contain HT-Control field
        macConfig.HTControlPresent = false;
    end

    % Generation of protected frames is not supported
    coder.internal.errorIf(macConfig.ProtectedFrame, 'wlan:wlanMACFrame:ProtectedNotSupported');
    
    % Warn if a decoded config is used for frame generation
    if macConfig.Decoded
        coder.internal.warning('wlan:wlanMACFrame:DecodedConfigUsed');
    end

    % Address4 is only supported for QoS Data and QoS Null (and not applicable for control frames)
    coder.internal.errorIf(~(strcmp(macConfig.getType, 'Control') || any(strcmp(macConfig.getSubtype, {'QoS Data', 'QoS Null'}))) && ...
        (macConfig.ToDS && macConfig.FromDS), 'wlan:wlanMACFrame:ToDSAndFromDS');

    % Address4 is present in MAC header when ToDS and FromDS are set to true
    coder.internal.errorIf(macConfig.ToDS && macConfig.FromDS && ~(size(macConfig.Address4, 1) == 1), ...
        'wlan:wlanMACFrame:SingleAddress4Expected');

    % IsMeshFrame is applicable only for 'QoS Data' and 'QoS Null' frames
    if ~any(strcmp(macConfig.FrameType, {'QoS Data', 'QoS Null'}))
        macConfig.IsMeshFrame = false;
    end

    % VHT, HE, or EHT format QoS Null is not supported
    coder.internal.errorIf(any(strcmp(macConfig.FrameFormat, {'VHT', 'HE-SU', 'HE-EXT-SU', 'EHT-SU'})) && strcmp(macConfig.FrameType, 'QoS Null'), 'wlan:wlanMACFrame:UnsupportedQoSNullFormat', macConfig.FrameFormat);
    
    
    % Only one of ESSCapability and IBSSCapability must be true for Beacon
    coder.internal.errorIf(strcmp(macConfig.FrameType, 'Beacon') && ...
        (macConfig.ManagementConfig.ESSCapability && macConfig.ManagementConfig.IBSSCapability), 'wlan:wlanMACFrame:ESSAndIBSS');
end

% Validate payload input and return payload octets in decimal format
function decOctets = validatePayloadFormat(payload)
    if isempty(payload)
        decOctets = [];
        return;
    end

    % Validate payload format
    validateattributes(payload, {'char', 'numeric', 'string'}, {}, 'wlanMACFrame', 'payload')

    if ischar(payload)
        % Validate hex-digits
        wnet.internal.validateHexOctets(payload, 'payload');

        if isvector(payload)
            validateattributes(payload, {'char'}, {'row'}, 'validatePayloadFormat', 'payload', 1);
            % Convert row vector to column of octets
            columnOctets = reshape(payload, 2, [])';
        else
            validateattributes(payload, {'char'}, {'2d', 'ncols', 2}, 'validatePayloadFormat', 'payload', 1);
            columnOctets = payload;
        end

        % Converting hexadecimal format octets to integer format
        decOctets = hex2dec(columnOctets);

    elseif isstring(payload)
        if payload == ""
            decOctets = [];
            return;
        end
        validateattributes(payload, {'string'}, {'scalar'}, 'wlanMACFrame', 'payload');

        % Convert octets to char type
        hexOctets = char(payload);

        % Validate hex-digits
        wnet.internal.validateHexOctets(hexOctets, 'payload');

        % Converting hexadecimal format octets to decimal format
        decOctets = hex2dec(reshape(hexOctets, 2, [])');

    else % numeric
        if iscolumn(payload)
            payloadRow = payload;
        else
            % Convert row vector to column vector
            payloadRow = payload';
        end
        % Payload byte values should be a non-negative number <= 255
        validateattributes(payloadRow, {'numeric'}, {'vector', 'integer', 'nonnegative', '<=', 255}, 'wlanMACFrame', 'payload octets');

        decOctets = double(payloadRow);
    end
end

function validatePHYConfig(macConfig, phyConfig)
    % Only wlanNonHTConfig allowed for trigger frame
    coder.internal.errorIf(strcmp(macConfig.FrameType, 'Trigger') && ~isa(phyConfig, 'wlanNonHTConfig'), 'wlan:wlanMACFrame:NonHTConfigExpected');

    % Validate phyConfig object
    validateattributes(phyConfig, {'wlanNonHTConfig', 'wlanHTConfig', 'wlanVHTConfig', 'wlanHESUConfig', 'wlanEHTMUConfig'}, {'scalar'}, 'wlanMACFrame', 'phyConfig');

    if strcmp(macConfig.FrameType, 'QoS Data')
        % Validate wlanHTConfig object for HT format
        coder.internal.errorIf((macConfig.MSDUAggregation || macConfig.MPDUAggregation) && ...
            strcmp(macConfig.FrameFormat, 'HT-Mixed') && ~isa(phyConfig, 'wlanHTConfig'), 'wlan:wlanMACFrame:InvalidPHYConfig', ...
            'HT-Mixed', 'wlanHTConfig');

        % Validate wlanVHTConfig object for VHT format
        coder.internal.errorIf(strcmp(macConfig.FrameFormat, 'VHT') && ...
            ~isa(phyConfig, 'wlanVHTConfig'), 'wlan:wlanMACFrame:InvalidPHYConfig', 'VHT', 'wlanVHTConfig');

        % Validate wlanHESUConfig object for HE format
        coder.internal.errorIf(any(strcmp(macConfig.FrameFormat, {'HE-SU', 'HE-EXT-SU'})) && ...
            ~isa(phyConfig, 'wlanHESUConfig'), 'wlan:wlanMACFrame:InvalidPHYConfig', 'HE', 'wlanHESUConfig');

        % Validate wlanEHTMUConfig object for EHT format
        coder.internal.errorIf(strcmp(macConfig.FrameFormat, 'EHT-SU') && ...
            (~isa(phyConfig, 'wlanEHTMUConfig') || (isa(phyConfig, 'wlanEHTMUConfig') && (numel(phyConfig.User) ~= 1))), 'wlan:wlanMACFrame:InvalidEHTPHYConfig');

        % Validate unsupported EHT DUP format
        coder.internal.errorIf(isa(phyConfig, 'wlanEHTMUConfig') && phyConfig.EHTDUPMode, 'wlan:wlanMACFrame:EHTDUPModeNotSupported');

        % Validate HE-SU and HE-EXT-SU formats
        coder.internal.errorIf(isa(phyConfig, 'wlanHESUConfig') && ~strcmp(phyConfig.packetFormat, macConfig.FrameFormat), 'wlan:wlanMACFrame:HEFormatMismatch');
    end
end

% Validate Name-Value pair
function outputFormat = validateNVPair(name, value)
    coder.internal.errorIf(~ischar(name) && ~isstring(name), 'wlan:wlanMACFrame:InvalidFunctionSignature');

    if coder.target('MATLAB')
        % Default values
        defaultParams = struct('OutputFormat', 'octets');
        expectedFormatValues = {'bits', 'octets'};

        % Extract each P-V pair
        p = inputParser;
        % Get values for the P-V pair or set defaults for the optional arguments
        addParameter(p, 'OutputFormat', defaultParams.OutputFormat, @(x) any(validatestring(x, expectedFormatValues)));
        % Parse inputs
        parse(p, name, value);
        useParams = p.Results;

        outputFormat = validatestring(useParams.OutputFormat, expectedFormatValues, 'wlanMACFrame');
    else % codegen path 
        outputFormat = parseNVPair(name, value);
    end
end

% Validate address field
function macConfig = validateAddressField(macConfig, numMSDUs, fieldName)
    if numMSDUs == 1
        if strcmp(fieldName, 'Address4')
            coder.internal.errorIf(~(size(macConfig.(fieldName), 1) == numMSDUs), 'wlan:wlanMACFrame:SingleAddress4Expected');
        else
            coder.internal.errorIf(~(size(macConfig.(fieldName), 1) == numMSDUs), 'wlan:wlanMACFrame:SingleAddressExpected', fieldName);
        end
    elseif numMSDUs > 1
        if size(macConfig.(fieldName), 1) == 1
            % Use the same value for all MSDUs
            macConfig.(fieldName) = repmat(macConfig.(fieldName), numMSDUs, 1);
        else
            coder.internal.errorIf(~(size(macConfig.(fieldName), 1) == numMSDUs), 'wlan:wlanMACFrame:NumAddressMismatch', fieldName);
        end
    end
end

function outputFormat = parseNVPair(name, value)
    % Check parameter name - 'OutputFormat'
    coder.internal.errorIf(~strcmpi(name, 'OutputFormat'), 'wlan:wlanMACFrame:InvalidNVPair');
    % Check value - 'bits' | 'octets'
    coder.internal.errorIf(~(ischar(value) || isstring(value)) || ~any(strcmpi(value, {'bits', 'octets'})), 'wlan:wlanMACFrame:InvalidParamValue');
    
    if strcmpi(value, 'bits')
        outputFormat = 'bits';
    else
        outputFormat = 'octets';
    end
end

