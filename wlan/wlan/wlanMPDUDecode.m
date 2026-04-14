function [macConfig, payload, status] = wlanMPDUDecode(mpdu, varargin)
%wlanMPDUDecode MAC protocol data unit (MPDU) decoder
%   [MACCONFIG,PAYLOAD,STATUS] = wlanMPDUDecode(MPDU) validates the FCS and
%   decodes the given MPDU. The function returns the decoded MAC frame
%   configuration object, MACCONFIG, the payload, PAYLOAD, and the decoding
%   status, STATUS.
%
%   MACCONFIG is the MAC frame configuration returned as an object of type
%   wlanMACFrameConfig.
%
%   PAYLOAD represents one or more MSDUs returned as a cell array
%   containing one or more character arrays, one for each MSDU. Each row in
%   the character array is the hexadecimal representation of an octet. For
%   all the MAC frames that do not contain data, the function returns
%   PAYLOAD as an empty cell array.
%
%   STATUS represents the result of MPDU decoding, returned as an
%   integer in the range [-31, 0]. Each value corresponds to wlanMACDecodeStatus
%   enumeration class. Any value of status other than 'Success' (0)
%   indicates that the MPDU decoding has failed. If the decoding fails, the
%   output MACCONFIG does not display any properties as it may not be valid
%   and the function returns PAYLOAD as an empty cell array.
%   
%   Specify MPDU as one of these types:
%     - A binary vector representing MPDU bits
%     - A character vector representing octets in hexadecimal format
%     - A string scalar representing octets in hexadecimal format
%     - A numeric vector, where each element is in the range [0, 255]
%       inclusive, representing octets in decimal format
%     - An n-by-2 character array, where each row represents an octet in
%       hexadecimal format
%
%   [...] = wlanMPDUDecode(MPDU,PHYFORMAT) validates the FCS and decodes
%   the given MPDU of the specified physical layer format, PHYFORMAT. The
%   function returns the decoded MAC frame configuration object, the
%   payload, and the decoding status.
%
%   PHYFORMAT is a character vector or string and must be one of 'Non-HT',
%   'HT', 'VHT', 'HE-SU', 'HE-EXT-SU', 'HE-TB', 'HE-MU', 'EHT-SU'. The
%   default is 'EHT-SU'.
%
%   [...] = wlanMPDUDecode(MPDU,PHYCONFIG) validates the FCS and decodes
%   the given MPDU. The function returns the decoded MAC frame
%   configuration object, the payload, and the decoding status.
%
%   PHYCONFIG is a format configuration object of type wlanNonHTConfig, 
%   wlanHTConfig, wlanVHTConfig, wlanHERecoveryConfig, wlanHESUConfig, 
%   wlanHETBConfig, wlanHEMUConfig, or wlanEHTMUConfig. When 
%   PHYCONFIG is an object of type wlanEHTMUConfig, the object must
%   specify the configuration for a single user transmission. The default
%   is wlanEHTMUConfig.
%
%   [...] = wlanMPDUDecode(...,Name=Value) specifies additional name-value
%   arguments described below. When a name-value argument is not specified,
%   the function uses its default value.
%
%   'DataFormat'            Specify the format of MPDU input. If MPDU input
%                           is a numeric vector of octets in decimal format
%                           or a character array or string scalar of octets
%                           in hexadecimal format, specify this value as
%                           'octets'. If MPDU input is a binary-valued
%                           vector, specify this value as 'bits'. The
%                           default value is 'bits'.
%
%   'SuppressWarnings'      Suppress warning messages, specified as true or
%                           false. The default value is false. To suppress
%                           warning messages, specify this input as true.
%
%   'IsMeshFrame'           Specify this input as true to decode MPDU sent
%                           by a mesh station in a mesh BSS. This input is
%                           applicable only for 'QoS Data' and 'QoS Null'
%                           frames. The default value is false.

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

narginchk(1, 12);
persistent macCfg

if isempty(macCfg)
    % For codegen: Assigning the return data types to the properties whose
    % default values are of different data type.
    mgmtConfig = wlanMACManagementConfig(Timestamp=uint64(0), AdditionalRates={'1 Mbps'});
    macCfg = wlanMACFrameConfig(ManagementConfig=mgmtConfig, DisableHexValidation=true);
end

macConfig = macCfg;
macConfig = isDecodedConfig(macConfig, true);
payload = cell(1, 0);
% Refer Table 9-19 in IEEE Std 802.11-2016 for frame length limits.
maxVHTorHEorEHTMPDULength = 11454;
maxHTorNonHTMMPDULength = 2304;

% Determine PHY config based on number on inputs
numArgs = numel(varargin)+1;
if mod(numArgs,2)
    % Function signatures with odd number of arguments:
    % wlanMPDUDecode(MPDU)
    % wlanMPDUDecode(MPDU, NAME1, VALUE1, ….)
    phyConfig = 'EHT-SU';
    nvPair = varargin;
else
    % Function signatures with even number of arguments:
    % wlanMPDUDecode(MPDU, PHYCONFIG)
    % wlanMPDUDecode(MPDU, PHYCONFIG, NAME1, VALUE1, ….)
    phyConfig = varargin{1};
    nvPair = {varargin{2:end}};
end

% Validate other input arguments
[status, mpduColVector, suppressWarns, isMeshFrame, outDecOctets, decodeEHTVariantTriggerFields, disableValidation] = validateInputs(mpdu, nvPair{:});
if status ~= wlanMACDecodeStatus.Success
    macConfig.DecodeFailed = true;
    return;
end

% Validate PHY config and convert to PHY format
isAMPDU = false;
[phyFormat, isAggFrame] = wlan.internal.phyConfigTophyFormat(phyConfig, disableValidation, isAMPDU);

% Frame Format
macConfig.FrameFormat = phyFormat;
% MPDU aggregation flag
macConfig.MPDUAggregation = isAggFrame;

% Validate FCS
[status, mpdu] = checkFCS(mpduColVector);
if status ~= wlanMACDecodeStatus.Success
    macConfig.DecodeFailed = true;
    return;
end

% Position of frame bits within the MPDU
pos = 1;

% Frame control (16-bits)
frameControl = mpdu(pos : pos+15);
[macConfig, status] = decodeFrameControl(macConfig, frameControl, status, suppressWarns);
if status ~= wlanMACDecodeStatus.Success
    macConfig.DecodeFailed = true;
    return;
end
pos = pos + 16;

% MPDU Length
mpduLength = numel(mpdu)/8;

% Validate MPDU length limit for VHT, HE, and EHT formats
if (mpduLength > maxVHTorHEorEHTMPDULength) && any(strcmp(macConfig.FrameFormat, {'VHT', 'HE-SU', 'HE-EXT-SU', 'EHT-SU'}))
    % Maximum length limit for an MPDU is 11454 octets for VHT or HE or EHT
    % formats.    
    status = wlanMACDecodeStatus.MaxMPDULengthExceeded;
    return;
end

% Validate MMPDU length limit for Non-HT and HT formats
if (mpduLength > maxHTorNonHTMMPDULength) && strcmp(macConfig.getType, 'Management') && (strcmp(macConfig.FrameFormat, 'Non-HT') || strcmp(macConfig.FrameFormat, 'HT-Mixed'))
    % Maximum length limit for a management frame is 2304 octets for Non-HT
    % or HT formats.
    status = wlanMACDecodeStatus.MaxMMPDULengthExceeded;
    return;
end

% Decode rest of the frame based on frame-type
switch macConfig.getType
    case 'Control'
        [macConfig, status] = decodeControlFrame(macConfig, mpdu(pos:end), status, suppressWarns, decodeEHTVariantTriggerFields);
        
    case 'Management'
        [macConfig, status] = decodeManagementFrame(macConfig, mpdu(pos:end), status, suppressWarns);
        
    otherwise % Data
        [macConfig, payload, status] = decodeDataFrame(macConfig, mpdu(pos:end), status, suppressWarns, isMeshFrame, outDecOctets);
end

if status ~= wlanMACDecodeStatus.Success
    macConfig.DecodeFailed = true;
    return;
end
end

% Decodes control frame
function [macConfig, status] = decodeControlFrame(macConfig, mpduBits, status, suppressWarns, decodeEHTVariantTriggerFields)
    pos = 1;
    minOctets = 14;
    numDataBits = numel(mpduBits);

    % The smallest control frame contains 14 octets. FCS (4 octets) and
    % Frame Control (2 octets) fields are already parsed. There should be
    % at least 8 octets more.
    if (numDataBits < 8*8)
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseFrame', minOctets, 'control');
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end

    % Duration (16 bits) (0 to 14 bits are valid for duration, 15th bit is
    % reserved)
    macConfig.Duration = bi2deOptimized(mpduBits(pos : pos+14)');
    pos = pos + 16;

    % Address1 (48 bits)
    address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
    macConfig.Address1 = reshape(address', 1, []);
    pos = pos + 48;

    % Address2 (48 bits)
    if ~strcmp(macConfig.FrameType, 'CTS') && ~strcmp(macConfig.FrameType, 'ACK')
        minOctets = minOctets + 6;
        if numDataBits >= (pos + 47)
            address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
            macConfig.Address2 = reshape(address', 1, []);
            pos = pos + 48;
        else
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'Address2', minOctets);
            status = wlanMACDecodeStatus.NotEnoughData;
            return;
        end
    end
    
    % Trigger frame-body
    if strcmp(macConfig.FrameType, 'Trigger')
        [macConfig.TriggerConfig, status] = decodeTriggerFrameBody(mpduBits, pos, suppressWarns, macConfig.TriggerConfig, status, decodeEHTVariantTriggerFields);
    end

    % Block-Ack frame body
    if strcmp(macConfig.FrameType, 'Block Ack')
        [macConfig, status] = decodeBAFrameBody(mpduBits, pos, suppressWarns, macConfig, status);
    end
end

% Decodes data frame
function [macConfig, payload, status] = decodeDataFrame(macConfig, mpduBits, status, suppressWarns, isMeshFrame, outDecOctets)
    pos = 1;
    minOctets = 28;
    payload = cell(1, 0);
    numDataBits = numel(mpduBits);

    % A minimum data frame contains at least 28 octets. FCS (4 octets) and
    % Frame Control (2 octets) fields are already parsed. There should be
    % at least 22 octets more.
    if (numDataBits < 22*8)
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseFrame', minOctets, 'Data')
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end

    % Duration (16 bits) (0 to 14 bits are valid for duration, 15th bit is
    % reserved)
    macConfig.Duration = bi2deOptimized(mpduBits(pos : pos+14)');
    pos = pos + 16;

    % Address1 (48 bits)
    address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
    macConfig.Address1 = reshape(address', 1, []);
    pos = pos + 48;

    % Address2 (48 bits)
    address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
    macConfig.Address2 = reshape(address', 1, []);
    pos = pos + 48;

    % Address3 (48 bits)
    address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
    macConfig.Address3 = reshape(address', 1, []);
    pos = pos + 48;

    % Sequence Control (16 bits)
    sequenceControl = mpduBits(pos : pos+15)';
    pos = pos + 16;
    macConfig.SequenceNumber = bi2deOptimized(sequenceControl(5 : 16));

    % Address4 field (48 bits)
    if macConfig.ToDS && macConfig.FromDS
        minOctets = minOctets + 6;

        % Address4 field
        if numDataBits >= (pos + 47)
            address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
            macConfig.Address4 = reshape(address', 1, []);
            pos = pos + 48;
        else
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'Address4', minOctets);
            status = wlanMACDecodeStatus.NotEnoughData;
            return;
        end
    end

    % Decode the fields applicable to QoS frames
    if strcmp(macConfig.FrameType, 'QoS Data') || strcmp(macConfig.FrameType, 'QoS Null')
        minOctets = minOctets + 2;

        % QoS Control (16 bits)
        if (numDataBits >= (pos + 15))
            qosControl = mpduBits(pos : pos+15)';
            pos = pos + 16;
            % TID
            tid = bi2deOptimized(qosControl(1 : 3));
            macConfig.TID = tid;

            % EOSP flag
            macConfig.EOSP = double(qosControl(5));

            % AckPolicy
            ackPolicy = bi2deOptimized(qosControl(6 : 7));
            switch ackPolicy
                case 0
                    macConfig.AckPolicy = 'Normal Ack/Implicit Block Ack Request';
                case 1
                    macConfig.AckPolicy = 'No Ack';
                case 2
                    macConfig.AckPolicy = 'No explicit acknowledgment/PSMP Ack/HTP Ack';
                otherwise
                    macConfig.AckPolicy = 'Block Ack';
            end

            % AMSDUPresent flag
            macConfig.MSDUAggregation = double(qosControl(8));

            if isMeshFrame
                macConfig.IsMeshFrame = true;

                % Mesh Control Present subfield
                macConfig = decodedMeshControl(macConfig, logical(qosControl(9)));

                % SleepMode
                if double(qosControl(10))
                    macConfig.SleepMode = 'Deep';
                else
                    macConfig.SleepMode = 'Light';
                end

                % ReceiverServicePeriodInitiated flag
                macConfig.ReceiverServicePeriodInitiated = double(qosControl(11));
            end
        else
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'QoS Control', minOctets);
            status = wlanMACDecodeStatus.NotEnoughData;
            return;
        end

        % HT Control (32 bits)
        if macConfig.HTControlPresent && ~strcmp(macConfig.FrameFormat, 'Non-HT')
            minOctets = minOctets + 4;

            if numDataBits >= (pos + 31)
                htControl = dec2hex(bi2deOptimized(mpduBits(pos : pos+31)'), 8);
                macConfig.HTControl = htControl;
                pos = pos + 32;
            else
                optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'HT Control', minOctets);
                status = wlanMACDecodeStatus.NotEnoughData;
                return;
            end
        end
    end
    
    % Frame is protected
    if macConfig.ProtectedFrame
        % Extract the protected data
        if (numDataBits >= pos)
            payloadDecOctets = wnet.internal.bits2octets(mpduBits(pos:end), false);
            if outDecOctets
                payload{end + 1} = payloadDecOctets;
            else
                payload{end + 1} = dec2hex(payloadDecOctets, 2);
            end
        end
        return;
    end

    % A-MSDU subframe header length
    minAMSDUSubframeHdrLen = 14;
    % Mesh Control field has a fixed length of 6 octets and variable length
    % of 0, 6 or 12 octets.
    minMeshControlOverhead = 6;
    if macConfig.HasMeshControl
        minAMSDUSubframeHdrLen = minAMSDUSubframeHdrLen + minMeshControlOverhead;
    end
    % Maximum length limits of MSDU and A-MSDU to be validated. Refer Table
    % 9-19 in IEEE Std 802.11-2016 for frame length limits.
    maxNonHTAMSDULength = 4065; % in octets
    maxHTAMSDULength = 7935; % in octets
    maxMSDULength = 2304; % in octets

    msduCount = 0;
    % Initialize per MSDU parameters present
    % Max MPDU length = 11454 octets. This will give maximum A-MSDU
    % length = 11454 - minimum MAC header (30) = 11424 octets.
    % Assuming MSDU length as 1 byte, minimum length of each A-MSDU
    % subframe is A-MSDU subframe header (14 octets) + MSDU length
    % (1 octet) + padding (1 octet) = 16 octets. Therefore we can
    % aggregate a maximum of 11424/16 = 714 MSDUs.
    maxMSDUs = 714;
    meshTTL = zeros(maxMSDUs, 1);
    meshSequenceNumber = zeros(maxMSDUs, 1, 'uint32');
    % Each address contains 12 characters
    sourceAddress = repmat('0', maxMSDUs, 12);
    destAddress = repmat('0', maxMSDUs, 12);
    meshControlAddress4 = repmat('0', maxMSDUs, 12);
    meshControlAddress5 = repmat('0', maxMSDUs, 12);
    meshControlAddress6 = repmat('0', maxMSDUs, 12);

    % Frame Body (variable)
    if macConfig.MSDUAggregation && strcmp(macConfig.FrameType, 'QoS Data')
        % A-MSDU length
        amsduLength = numel(mpduBits(pos:end))/8;

        % Validate A-MSDU length
        if (amsduLength > maxNonHTAMSDULength) && strcmp(macConfig.FrameFormat, 'Non-HT')
            % Max A-MSDU length for Non-HT format is 4065 octets
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:MaxAMSDULengthExceeded', 'Non-HT', maxNonHTAMSDULength);
            status = wlanMACDecodeStatus.MaxAMSDULengthExceeded;
            return;
        elseif (amsduLength > maxHTAMSDULength) && strcmp(macConfig.FrameFormat, 'HT-Mixed')
            % Max A-MSDU length for HT format is 7935 octets
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:MaxAMSDULengthExceeded', 'HT', maxHTAMSDULength);
            status = wlanMACDecodeStatus.MaxAMSDULengthExceeded;
            return;
        end

        % Decode the A-MSDU: Iterate over the MSDUs in the A-MSDU
        while numDataBits >= (pos + (minAMSDUSubframeHdrLen*8) - 1)
            msduCount = msduCount + 1;

            % A-MSDU Destination Address (6 octets)
            address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
            destAddress(msduCount, :) = reshape(address', 1, []);
            pos = pos + 48;
            minOctets = minOctets + 6;

            % A-MSDU Source Address (6 octets)
            address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
            sourceAddress(msduCount, :) = reshape(address', 1, []);
            pos = pos + 48;
            minOctets = minOctets + 6;

            % MSDU length (2 octets)
            msduLength = bi2deOptimized([mpduBits(pos+8 : pos+15)' mpduBits(pos : pos+7)']);
            pos = pos + 16;
            minOctets = minOctets + 2;

            % A-MSDU subframe header length
            amsduSubframeHdrLen = minAMSDUSubframeHdrLen;

            % Mesh Control field (6 octets minimum)
            if macConfig.HasMeshControl
                minOctets = minOctets + 6; % Mesh Flags + Mesh TTL + Mesh sequence number
                [macConfig, status, pos, minOctets] = decodeMeshControl(macConfig, mpduBits, pos, minOctets, status, suppressWarns);
                if status ~= wlanMACDecodeStatus.Success
                    macConfig.DecodeFailed = true;
                    return;
                end
                meshTTL(msduCount) = macConfig.MeshTTL;
                meshSequenceNumber(msduCount) = macConfig.MeshSequenceNumber;
                if ~(macConfig.ToDS && macConfig.FromDS) && macConfig.AddressExtensionMode == 1
                    meshControlAddress4(msduCount, :) = macConfig.Address4;
                    % Variable length of 6 octets (Address4) in A-MSDU subframe header
                    amsduSubframeHdrLen = minAMSDUSubframeHdrLen + 6;
                elseif macConfig.AddressExtensionMode == 2
                    meshControlAddress5(msduCount, :) = macConfig.Address5;
                    meshControlAddress6(msduCount, :) = macConfig.Address6;
                    % Variable length of 12 octets (Address5 & Address6) in A-MSDU subframe header
                    amsduSubframeHdrLen = minAMSDUSubframeHdrLen + 12;
                end
            end

            if msduLength
                % Validate MSDU length
                if msduLength > maxMSDULength
                    status = wlanMACDecodeStatus.MaxMSDULengthExceeded;
                    payload = cell(1, 0);
                    return;
                end

                % Extract the MSDUs
                if (numDataBits >= (pos + msduLength*8-1))
                    payloadDecOctets = wnet.internal.bits2octets(mpduBits(pos : pos + msduLength*8-1), false);
                    if outDecOctets
                        payload{end + 1} = payloadDecOctets;
                    else
                        payload{end + 1} = dec2hex(payloadDecOctets, 2);
                    end
                    pos = pos + msduLength*8;
                    minOctets = minOctets + msduLength;
                else
                    status = wlanMACDecodeStatus.MalformedAMSDULength;
                    payload = cell(1, 0);
                    return;
                end
            end

            % Skip subframe padding
            pad = abs(mod((amsduSubframeHdrLen + msduLength), -4));
            if pad
                pos = pos + pad*8;
                minOctets = minOctets + pad;
            end
        end

        % Fill per MSDU parameters
        macConfig.AMSDUDestinationAddress = destAddress(1:msduCount, :);
        macConfig.AMSDUSourceAddress = sourceAddress(1:msduCount, :);
        if macConfig.HasMeshControl
            macConfig.MeshTTL = meshTTL(1:msduCount);
            macConfig.MeshSequenceNumber = meshSequenceNumber(1:msduCount);
            if ~(macConfig.ToDS && macConfig.FromDS) && macConfig.AddressExtensionMode == 1
                macConfig.Address4 = meshControlAddress4(1:msduCount, :);
            elseif macConfig.AddressExtensionMode == 2
                macConfig.Address5 = meshControlAddress5(1:msduCount, :);
                macConfig.Address6 = meshControlAddress6(1:msduCount, :);
            end
        end

    elseif strcmp(macConfig.FrameType, 'Data') || strcmp(macConfig.FrameType, 'QoS Data')
        % Mesh Control field
        if macConfig.HasMeshControl
            minOctets = minOctets + 6; % Mesh Flags + Mesh TTL + Mesh sequence number
            [macConfig, status, pos, ~] = decodeMeshControl(macConfig, mpduBits, pos, minOctets, status, suppressWarns);
            if status ~= wlanMACDecodeStatus.Success
                macConfig.DecodeFailed = true;
                return;
            end
        end

        % MSDU length
        msduLength = (numDataBits-pos+1)/8;

        % Validate MSDU length
        if msduLength > maxMSDULength
            status = wlanMACDecodeStatus.MaxMSDULengthExceeded;
            return;
        end

        % Extract the MSDU
        if (numDataBits >= pos)
            payloadDecOctets = wnet.internal.bits2octets(mpduBits(pos:end), false);
            if outDecOctets
                payload{end + 1} = payloadDecOctets;
            else
                payload{end + 1} = dec2hex(payloadDecOctets, 2);
            end
        end
    end
end

% Decodes management frame
function [macConfig, status] = decodeManagementFrame(macConfig, mpduBits, status, suppressWarns)
    pos = 1;
    minOctets = 28;
    numDataBits = numel(mpduBits);

    % The smallest management frame contains 28 octets. FCS (4 octets) and
    % Frame Control (2 octets) fields are already parsed. There should be
    % at least 22 octets more.
    if (numDataBits < 22*8)
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseFrame', minOctets, 'management');
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end

    % Duration (16 bits) (0 to 14 bits are valid for duration, 15th bit is
    % reserved)
    macConfig.Duration = bi2deOptimized(mpduBits(pos : pos+14)');
    pos = pos + 16;

    % Address1 (48 bits)
    address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
    macConfig.Address1 = reshape(address', 1, []);
    pos = pos + 48;

    % Address2 (48 bits)
    address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
    macConfig.Address2 = reshape(address', 1, []);
    pos = pos + 48;

    % Address3 (48 bits)
    address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
    macConfig.Address3 = reshape(address', 1, []);
    pos = pos + 48;

    % Sequence Control (16 bits)
    sequenceControl = mpduBits(pos : pos+15)';
    macConfig.SequenceNumber = bi2deOptimized(sequenceControl(5 : 16));
    pos = pos + 16;

    % Frame Body (variable) - Only Beacon frame is supported. So the
    % frame-body corresponds to the beacon frame.
    
    % Beacon frame is not a robust management frame, and hence protected
    % bit is not expected to be set. Refer sections 12.2.7 and 12.2.8 in
    % IEEE Std 802.11-2016.
    if macConfig.ProtectedFrame
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnexpectedProtectedFrame', 'beacon');
        status = wlanMACDecodeStatus.UnexpectedProtectedFrame;
        return;
    end
    
    % Timestamp (64-bits)
    minOctets = minOctets + 8;
    if numDataBits >= (pos + 63)
        timestampLSB = uint64(bi2deOptimized(mpduBits(pos : pos + 31)'));
        timestampMSB = uint64(bi2deOptimized(mpduBits(pos + 32 : pos + 63)'));
        macConfig.ManagementConfig.Timestamp = bitor(timestampLSB, bitshift(timestampMSB, 32));
        pos = pos + 64;
    else
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'Timestamp', minOctets);
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end

    % Beacon Interval (16-bits)
    minOctets = minOctets + 2;
    if numDataBits >= (pos + 15)
        macConfig.ManagementConfig.BeaconInterval = bi2deOptimized(mpduBits(pos : pos+15)');
        pos = pos + 16;
    else
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'Beacon Interval', minOctets);
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end

    % Capability Information field (16-bits)
    minOctets = minOctets + 2;
    if numDataBits >= (pos + 15)
        macConfig.ManagementConfig.ESSCapability = double(mpduBits(pos));
        pos = pos + 1;
        macConfig.ManagementConfig.IBSSCapability = double(mpduBits(pos));
        pos = pos + 1;
        pos = pos + 1; % CF-Pollable
        pos = pos + 1; % CF-Poll Request
        macConfig.ManagementConfig.Privacy = double(mpduBits(pos));
        pos = pos + 1;
        macConfig.ManagementConfig.ShortPreamble = double(mpduBits(pos));
        pos = pos + 1;
        pos = pos + 1; % Reserved
        pos = pos + 1; % Reserved
        macConfig.ManagementConfig.SpectrumManagement = double(mpduBits(pos));
        pos = pos + 1;
        macConfig.ManagementConfig.QoSSupport = double(mpduBits(pos));
        pos = pos + 1;
        macConfig.ManagementConfig.ShortSlotTimeUsed = double(mpduBits(pos));
        pos = pos + 1;
        macConfig.ManagementConfig.APSDSupport = double(mpduBits(pos));
        pos = pos + 1;
        macConfig.ManagementConfig.RadioMeasurement = double(mpduBits(pos));
        pos = pos + 1;
        pos = pos + 1; % Reserved
        macConfig.ManagementConfig.DelayedBlockAckSupport = double(mpduBits(pos));
        pos = pos + 1;
        macConfig.ManagementConfig.ImmediateBlockAckSupport = double(mpduBits(pos));
        pos = pos + 1;
    else
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'Capability Information', minOctets);
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end

    % Flags for tracking mandatory IEs
    ssidIEPresent = false;
    supportedRatesIEPresent = false;

    while numDataBits >= (pos + 15)
        % Element ID (1 octet)
        elementID = bi2deOptimized(mpduBits(pos : pos+7)');
        pos = pos + 8;

        % Element Length (1 octet)
        ieLength = bi2deOptimized(mpduBits(pos : pos+7)');
        pos = pos + 8;

        % Information field (variable)
        if (numDataBits >= pos+ieLength*8-1)
            elementIDExtension = 0;

            % Element ID Extension
            if elementID == 255
                elementIDExtension = bi2deOptimized(mpduBits(pos : pos+7)');
                % IE length includes the extension ID. Refer section
                % 9.4.2.1 of IEEE Std 802.11-2016
                ieLength = ieLength - 1;
                pos = pos + 8;
            end

            % IE information
            if ieLength > 0
                informationOctets = wnet.internal.bits2octets(mpduBits(pos : pos+ieLength*8-1), false);
                pos = pos + ieLength*8;
            else
                % If IE length is 0, return a 0-by-1 empty double array
                % that will be converted to a 1-by-0 char array in the
                % following steps.
                informationOctets = zeros(0, 1);
            end

            if elementID == 0
                % SSID must not exceed 32 octets
                if ieLength > 32
                    status = wlanMACDecodeStatus.MalformedSSID;
                    return;
                end

                % SSID IE (variable)
                macConfig.ManagementConfig.SSID = char(informationOctets)';
                ssidIEPresent = true;

            elseif elementID == 1
                % Number of supported rates must not exceed 8 rates
                if (ieLength < 1) || (ieLength > 8)
                    optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:MalformedSupportedRatesIE', 'Beacon', ieLength);
                    status = wlanMACDecodeStatus.MalformedSupportedRatesIE;
                    return;
                end

                % Supported Rates IE (variable)
                rates = informationOctets;
                basicRates = cell(1, 0);
                additionalRates = cell(1, 0);
                for i = 1:numel(rates)
                    % Basic Rates: If the encoded rate has most significant
                    % bit set to 1, it is considered as a basic rate.
                    if (bitand(rates(i), 128) == 128)
                        datarate = getDataRate(bitand(rates(i), 127), suppressWarns);
                        if ~isempty(datarate)
                            basicRates{end + 1} = datarate;
                        end
                    else % Additional Rates
                        datarate = getDataRate(bitand(rates(i), 127), suppressWarns);
                        if ~isempty(datarate)
                            additionalRates{end + 1} = datarate;
                        end
                    end
                end
                macConfig.ManagementConfig.BasicRates = basicRates;
                macConfig.ManagementConfig.AdditionalRates = additionalRates;
                supportedRatesIEPresent = true;

            else
                % IE information
                information = reshape(dec2hex(informationOctets, 2)', 1, []);

                % Fill the IE information in the management configuration
                if elementID == 255
                    % IEs with element ID extension
                    macConfig.ManagementConfig = macConfig.ManagementConfig.addIE([elementID elementIDExtension], information);
                else
                    % IEs without element ID extension
                    macConfig.ManagementConfig = macConfig.ManagementConfig.addIE(elementID, information);
                end
            end
        else
            % Decoded IE length is found invalid. The specified length is more
            % than the remaining data.
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:MalformedIELength', 'Beacon', elementID);
            status = wlanMACDecodeStatus.MalformedIELength;
            return;
        end
    end

    % SSID and Supported Rates IEs are mandatory for a beacon frame. If any
    % of these IEs are missing, consider it as a malformed packet.
    if ~ssidIEPresent || ~supportedRatesIEPresent
        status = wlanMACDecodeStatus.MissingMandatoryIEs;
        return;
    end
end

% Decodes frame control field
function [macConfig, status] = decodeFrameControl(macConfig, frameControl, status, suppressWarns)
    pos = 1;

    % Protocol Version (2-bits)
    protocolVersion = bi2deOptimized(frameControl(pos : pos+1)');
    if (protocolVersion ~= 0)
        status = wlanMACDecodeStatus.InvalidProtocolVersion;
        return;
    end
    pos = pos + 2;

    % Type (2-bits)
    [type, status] = getType(frameControl(pos : pos+1), status, suppressWarns);
    if status ~= wlanMACDecodeStatus.Success
        return;
    end
    pos = pos + 2;

    % Subtype (4-bits)
    [subtype, status]= getSubtype(frameControl(pos : pos+3), type, status, suppressWarns);
    if status ~= wlanMACDecodeStatus.Success
        return;
    end
    macConfig.FrameType = subtype;
    pos = pos + 4;

    % ToDS (1-bit)
    macConfig.ToDS = double(frameControl(pos));
    pos = pos + 1;

    % FromDS (1-bit)
    macConfig.FromDS = double(frameControl(pos));
    pos = pos + 1;

    % MoreFragments (1-bit)
    pos = pos + 1;

    % Retransmission (1-bit)
    macConfig.Retransmission = double(frameControl(pos));
    pos = pos + 1;

    % Power Management (1-bit)
    macConfig.PowerManagement = double(frameControl(pos));
    pos = pos + 1;

    % More Data (1-bit)
    macConfig.MoreData = double(frameControl(pos));
    pos = pos + 1;

    % Protected Frame (1-bit)
    macConfig.ProtectedFrame = double(frameControl(pos));
    pos = pos + 1;

    % Order (1-bit)
    order = double(frameControl(pos));

    if (strcmp(macConfig.FrameType, 'QoS Data') || strcmp(macConfig.FrameType, 'QoS Null')) && ~strcmp(macConfig.FrameFormat, 'Non-HT')
        % +HTC (1-bit)
        macConfig.HTControlPresent = order;
    end
end

% Decode mesh control field
function [macConfig, status, pos, minOctets] = decodeMeshControl(macConfig, mpduBits, pos, minOctets, status, suppressWarns)
    numMPDUBits = numel(mpduBits);

    if (numMPDUBits >= (pos + 47))
        % Extract address extension mode (2 bits) from Mesh flags
        % field (1 octet) and the remaining 6 bits are reserved
        addressExtMode = bi2deOptimized(mpduBits(pos : pos+1)');
        if addressExtMode == 3
            status = wlanMACDecodeStatus.UnknownAddressExtMode;
            return;
        end
        macConfig.AddressExtensionMode = addressExtMode;
        pos = pos + 8;

        % Extract mesh TTL value from Mesh TTL field (1 octet)
        macConfig.MeshTTL = bi2deOptimized(mpduBits(pos : pos+7)');
        pos = pos + 8;

        % Extract mesh sequence number from Mesh Sequence Number
        % field (4 octets)
        macConfig.MeshSequenceNumber = uint32(bi2deOptimized(mpduBits(pos : pos+31)'));
        pos = pos + 32;

        % Address Extension Mode:
        % 0 - indicates no extra addresses
        % 1 - indicates 1 extra address
        % 2 - indicates 2 extra addresses
        % 3 - reserved (This value doesn't occur and is validated before)
        minOctets = minOctets + macConfig.AddressExtensionMode*6;
        if numMPDUBits >= pos + macConfig.AddressExtensionMode*6 - 1
            if macConfig.AddressExtensionMode == 1
                if ~(macConfig.ToDS && macConfig.FromDS)
                    % Address4 (48 bits) present in Mesh Control field
                    address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
                    macConfig.Address4 = reshape(address', 1, []);
                    pos = pos + 48;
                else
                    % Display a warning specifying that when ToDS and
                    % FromDS are 1, the Address4 property in the decoded
                    % configuration object represents Address4 present in
                    % MAC header.
                    optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:InvalidAddressExtMode');
                end
            elseif macConfig.AddressExtensionMode == 2
                % Address5 (48 bits)
                address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
                macConfig.Address5 = reshape(address', 1, []);
                pos = pos + 48;

                % Address6 (48 bits)
                address = dec2hex(wnet.internal.bits2octets(mpduBits(pos : pos+47), false), 2);
                macConfig.Address6 = reshape(address', 1, []);
                pos = pos + 48;
            end
        else
            % Not enough data to extract mesh address extension
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'Mesh Control', minOctets);
            status = wlanMACDecodeStatus.NotEnoughData;
            return;
        end
    else
        % Not enough data to extract mesh control and the payload
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'Mesh Control', minOctets);
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end
end

% Checks FCS
function [status, mpdu] = checkFCS(mpduWithFCS)
    persistent crcCfg

    % CRC Detector object
    if isempty(crcCfg)
        % Refer section 9.2.48 in IEEE Std 802.11-2016 for FCS calculation.
        crcCfg = crcConfig(Polynomial=[32 26 23 22 16 12 11 10 8 7 5 4 2 1 0], InitialConditions=1, DirectMethod=true, FinalXOR=1);
    end

    % Validate the FCS
    [mpdu, err] = crcDetect(double(mpduWithFCS), crcCfg);
    mpdu = reshape(mpdu, [], 1);

    % Update status
    if err
        status = wlanMACDecodeStatus.FCSFailed;
    else
        status = wlanMACDecodeStatus.Success;
    end
end

% Return frame type code
function [type, status] = getType(typeCode, status, suppressWarns)
    code = bi2deOptimized(typeCode');
    switch code
        case 0
            type = 'Management';
        case 1
            type = 'Control';
        case 2
            type = 'Data';
        otherwise
            % For codegen
            type = '';
            % Display a warning specifying the code of the unsupported frame
            % type and also mention the list of supported frame type codes.
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnsupportedFrameType', code);
            status = wlanMACDecodeStatus.UnsupportedFrameType;
    end
end

% Return frame subtype code
function [subtype, status] = getSubtype(subtypeCode, type, status, suppressWarns)
    code = bi2deOptimized(subtypeCode');

    if strcmp(type, 'Management')
        if (code == 8)
            subtype = 'Beacon';
        else
            % For codegen
            subtype = '';
            % Display a warning specifying the code of the unsupported
            % management subtype and also mention the list of supported
            % subtype codes.
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnsupportedFrameSubtype', code, 'management', '8');
            status = wlanMACDecodeStatus.UnsupportedFrameSubtype;
        end
    elseif strcmp(type, 'Data')
        switch code
            case 0
                subtype = 'Data';
            case 4
                subtype = 'Null';
            case 8
                subtype = 'QoS Data';
            case 12
                subtype = 'QoS Null';
            otherwise
                % For codegen
                subtype = '';
                % Display a warning specifying the code of the unsupported
                % data subtype and also mention the list of supported
                % subtype codes.
                optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnsupportedFrameSubtype', code, ...
                        'data', '0, 4, 8, and 12');
                status = wlanMACDecodeStatus.UnsupportedFrameSubtype;
        end
    else % Control
        switch code
            case 11
                subtype = 'RTS';
            case 12
                subtype = 'CTS';
            case 13
                subtype = 'ACK';
            case 14
                subtype = 'CF-End';
            case 9
                subtype = 'Block Ack';
            case 2
                subtype = 'Trigger';
            otherwise
                % For codegen
                subtype = '';
                % Display a warning specifying the code of the unsupported
                % control subtype and also mention the list of supported
                % subtype codes
                optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnsupportedFrameSubtype', ...
                        code, 'control', '2, 9, 11, 12, and 13');
                status = wlanMACDecodeStatus.UnsupportedFrameSubtype;
        end
    end
end

% Returns the data rate for the given code
function rate = getDataRate(code, suppressWarns)
    % Refer Table-18.4 in Std IEEE 802.11-2016
    switch(code)
        case 2
            rate = '1 Mbps';
        case 4
            rate = '2 Mbps';
        case 11
            rate = '5.5 Mbps';
        case 12
            rate = '6 Mbps';
        case 18
            rate = '9 Mbps';
        case 22
            rate = '11 Mbps';
        case 24
            rate = '12 Mbps';
        case 36
            rate = '18 Mbps';
        case 48
            rate = '24 Mbps';
        case 72
            rate = '36 Mbps';
        case 96
            rate = '48 Mbps';
        case 108
            rate = '54 Mbps';
        otherwise
            % For codegen
            rate = '';
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnknownRateReceived', code);
    end
end

function [triggerConfig, status] = decodeTriggerFrameBody(mpduBits, pos, suppressWarns, triggerConfig, status, decodeEHTVariantTriggerFields)
    minOctets = 14;
    numDataBits = numel(mpduBits);

    % Common Info (64 bits)
    minOctets = minOctets + 8;
    if numDataBits >= (pos + 63)
        % Common Info Variant
        bit54 = double(mpduBits(pos + 54));
        bit55 = double(mpduBits(pos + 55));
        isEHTCommonInfo = false;
        if bit54 && bit55
            triggerConfig.CommonInfoVariant = 'HE';
        elseif decodeEHTVariantTriggerFields
            triggerConfig.CommonInfoVariant = 'EHT';
            isEHTCommonInfo = true;
        end

        % Trigger Type (4 bits)
        triggerType = bi2deOptimized(mpduBits(pos : pos+3)');
        switch (triggerType)
            case 0
                triggerConfig.TriggerType = 'Basic';
            case 2
                triggerConfig.TriggerType = 'MU-BAR';
            case 3
                triggerConfig.TriggerType = 'MU-RTS';
            otherwise
                optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnsupportedTriggerType', triggerType);
                status = wlanMACDecodeStatus.UnsupportedTriggerType;
                return;
        end
        pos = pos + 4;

        isMURTS = strcmp(triggerConfig.TriggerType, 'MU-RTS');
        % UL Length (12 bits)
        if ~isMURTS
            ulLength = bi2deOptimized(mpduBits(pos : pos+11)');
            if mod(ulLength,3)~=1
                optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:InvalidLSIGLength', ulLength); 
                status = wlanMACDecodeStatus.InvalidLSIGLength;
                return;
            end
            triggerConfig.LSIGLength = ulLength;
        end
        pos = pos + 12;

        % More TF (1 bit)
        triggerConfig.MoreTF = double(mpduBits(pos));
        pos = pos + 1;

        % CS Required (1 bit)
        triggerConfig.CSRequired = double(mpduBits(pos));
        pos = pos + 1;

        % UL Bandwidth (2 bits)
        ulBW = bi2deOptimized(mpduBits(pos : pos+1)');
        switch(ulBW)
            case 0
                triggerConfig.ChannelBandwidth = 'CBW20';
            case 1
                triggerConfig.ChannelBandwidth = 'CBW40';
            case 2
                triggerConfig.ChannelBandwidth = 'CBW80';
            otherwise % 3
                triggerConfig.ChannelBandwidth = 'CBW80+80 or CBW160';
        end
        pos = pos + 2;

        if isMURTS
            % Skip TXS Sharing mode since its unsupported
            pos = pos + 2;

            % Skip remaining fields (Bits 22 to 53 are not applicable for MU-RTS)
            pos = pos + 32;

            % Bits 54 to 63
            if isEHTCommonInfo
                % HE/EHT P160 (1-bit)
                triggerConfig.HEorEHTP160 = double(mpduBits(pos));
                pos = pos + 1;

                % Special User Info Field Flag (1-bit)
                triggerConfig.SpecialUserInfoPresent = ~double(mpduBits(pos));
                pos = pos + 1;

                % Skip EHT Reserved bits (7-bits) and Reserved bit (1-bit)
                pos = pos + 8;
            else
                % Skip remaining fields (Bits 54 to 63 are not applicable for MU-RTS)
                pos = pos + 10;
            end
        else
            % GI and LTF Type (2 bits)
            LTFTypeAndGI = bi2deOptimized(mpduBits(pos : pos+1)');
            if ~isEHTCommonInfo % Skip LTF Type and GI bits for EHT variant common info
                switch(LTFTypeAndGI)
                    case 0
                        triggerConfig.HELTFTypeAndGuardInterval = '1x HE-LTF + 1.6 us GI';
                    case 1
                        triggerConfig.HELTFTypeAndGuardInterval = '2x HE-LTF + 1.6 us GI';
                    case 2
                        triggerConfig.HELTFTypeAndGuardInterval = '4x HE-LTF + 3.2 us GI';
                    otherwise % 3
                        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnknownHELTFTypeAndGI', LTFTypeAndGI);
                        status = wlanMACDecodeStatus.UnknownHELTFTypeAndGI;
                        return;
                end
            end
            pos = pos + 2;

            % MU-MIMO LTF Mode (1 bit)
            triggerConfig.SingleStreamPilots = ~double(mpduBits(pos));
            pos = pos + 1;

            % Number of HE-LTF Symbols / Midamble Periodicity (3 bits)
            % Assign this value appropriately based on the doppler
            % subfield value
            numHELTForMidamblePeriodicity = bi2deOptimized(mpduBits(pos: pos+2)');
            pos = pos + 3;

            % UL STBC (1 bit)
            triggerConfig.STBC = double(mpduBits(pos));
            pos = pos + 1;

            % LDPC Extra Symbol Segment (1 bit)
            triggerConfig.LDPCExtraSymbol = double(mpduBits(pos));
            pos = pos + 1;

            % AP Tx Power (6 bits)
            apTxPower = bi2deOptimized(mpduBits(pos : pos+5)');
            if apTxPower <= 60
                triggerConfig.APTransmitPower = apTxPower-20;
            else
                optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnknownAPTxPower', apTxPower);
                status = wlanMACDecodeStatus.UnknownAPTxPower;
                return;
            end
            pos = pos + 6;

            % Pre-FEC Padding Factor (2 bits)
            preFECPaddingFactor = bi2deOptimized(mpduBits(pos : pos+1)');
            if preFECPaddingFactor == 0
                triggerConfig.PreFECPaddingFactor = 4;
            else
                triggerConfig.PreFECPaddingFactor = preFECPaddingFactor;
            end
            pos = pos + 2;

            % PE Disambiguity (1 bit)
            triggerConfig.PEDisambiguity = double(mpduBits(pos));
            pos = pos + 1;

            % UL Spatial Reuse (16 bits)
            triggerConfig.SpatialReuse1 = bi2deOptimized(mpduBits(pos : pos+3)');
            pos = pos + 4;
            triggerConfig.SpatialReuse2 = bi2deOptimized(mpduBits(pos : pos+3)');
            pos = pos + 4;
            triggerConfig.SpatialReuse3 = bi2deOptimized(mpduBits(pos : pos+3)');
            pos = pos + 4;
            triggerConfig.SpatialReuse4 = bi2deOptimized(mpduBits(pos : pos+3)');
            pos = pos + 4;

            % Doppler (1 bit)
            triggerConfig.HighDoppler = double(mpduBits(pos));
            if triggerConfig.HighDoppler
                tmp = double(numHELTForMidamblePeriodicity > 3);
                switch (numHELTForMidamblePeriodicity)
                    case {0, 4}
                        triggerConfig.NumHELTFSymbols = 1;
                        triggerConfig.MidamblePeriodicity = 10+tmp*10;
                    case {1, 2, 5, 6}
                        triggerConfig.NumHELTFSymbols = 2*mod(numHELTForMidamblePeriodicity, 4);
                        triggerConfig.MidamblePeriodicity = 10+tmp*10;
                    otherwise % 3 or 7
                        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:ReservedNumHELTFMidamblePeriodicity', numHELTForMidamblePeriodicity);
                end
            else
                switch (numHELTForMidamblePeriodicity)
                    case 0
                        triggerConfig.NumHELTFSymbols = 1;
                    case {1, 2, 3, 4}
                        triggerConfig.NumHELTFSymbols = 2*numHELTForMidamblePeriodicity;
                    otherwise % 5-7
                        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:ReservedNumHELTFMidamblePeriodicity', numHELTForMidamblePeriodicity);
                end
            end
            pos = pos + 1;

            % UL HE-SIGA2 Reserved field (9 bits)
            triggerConfig.HESIGAReservedBits = mpduBits(pos : pos+8);
            pos = pos + 9;

            % Reserved (1 bit)
            pos = pos + 1;
        end

        % User-info fields
        noUserInfo = true;
        userInfoCount = 1;
        while numDataBits >= (pos + 39)
            % User-info (40 bits)
            cfgUserInfo = wlanMACTriggerUserConfig;
            cfgUserInfo.TriggerType = triggerConfig.TriggerType;
            % AID12 (12 bits)
            aid = bi2deOptimized(mpduBits(pos : pos+11)');
            if (aid > 2007) && ~any(aid == [2045, 2046, 4095])
                optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnknownAID12Value', aid);
                status = wlanMACDecodeStatus.UnknownAID12Value;
                return;
            end
            if aid == 4095
                % Indicates the start of padding
                return;
            end
            noUserInfo = false;
            cfgUserInfo.AID12 = aid;
            pos = pos + 12;

            if triggerConfig.SpecialUserInfoPresent && userInfoCount == 1 % First user info field in the list is special user info
                cfgUserInfo.UserInfoVariant = 'Special';

                % Skip PHY Version Identifier (3 bits)
                pos = pos + 3;

                % UL Bandwidth Extension (2 bits)
                cfgUserInfo.ULBandwidthExtension = bi2deOptimized(mpduBits(pos : pos+1)');
                pos = pos + 2;

                % Skip EHT Spatial Reuse 1 (4 bits) and EHT Spatial Reuse 2 (4 bits)                
                pos = pos + 8;

                % Skip U-SIG Disregard and Validate (12 bits)
                pos = pos + 12;

                % Skip remaining fields (Reserved - 3 bits and Trigger Dependent User Info)
                pos = pos + 3;

                % Add user config to trigger config object
                triggerConfig = addSpecialUserInfo(triggerConfig, cfgUserInfo);
            else
                if triggerConfig.SpecialUserInfoPresent
                    cfgUserInfo.UserInfoVariant = 'EHT';
                else
                    cfgUserInfo.UserInfoVariant = 'HE';
                end
                % RU Allocation (8 bits)
                % B0 of RU Allocation
                ruAllocationRegion = double(mpduBits(pos));
                if strcmp(triggerConfig.ChannelBandwidth, 'CBW80+80 or CBW160') && ~isMURTS
                    if ruAllocationRegion
                        cfgUserInfo.RUAllocationRegion = 'secondary 80MHz';
                    else
                        cfgUserInfo.RUAllocationRegion = 'primary 80MHz';
                    end
                end
                pos = pos + 1;
                % B1-B7 of RU Allocation
                ruAllocation = bi2deOptimized(mpduBits(pos : pos+6)');
                if ruAllocation <= 68
                    [ruSize, ruIndex] = getRUInfo(ruAllocation);
                    cfgUserInfo.RUSize = ruSize;
                    if cfgUserInfo.RUSize == 1992
                        % If RUSize is 2*996, station should ignore B0. So
                        % forcing RUAllocationRegion to default value. Refer
                        % section 9.3.1.22.1 of IEEE Std 802.11ax-2021.
                        cfgUserInfo.RUAllocationRegion = 'primary 80MHz';
                    end
                    cfgUserInfo.RUIndex = ruIndex;
                elseif ruAllocation ~= 69
                    optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnknownRUAllocation', ruAllocation);
                    status = wlanMACDecodeStatus.UnknownRUAllocation;
                    return;
                end
                pos = pos + 7;

                if isMURTS
                    if triggerConfig.SpecialUserInfoPresent
                        % Skip remaining fields (Bits 20 to 38 are not applicable for MU-RTS)
                        pos = pos + 19;

                        % PS160 (1 bit)
                        cfgUserInfo.PS160 = bi2deOptimized(mpduBits(pos));
                        pos = pos + 1;
                    else
                        % Skip remaining fields (Bits 20 to 39 are not applicable for MU-RTS)
                        pos = pos + 20;
                    end
                elseif (aid == 2046)
                    % Skip remaining fields (not applicable for AID-2046)
                    switch (cfgUserInfo.TriggerType)
                        case 'Basic'
                            pos = pos + 28;
                        otherwise % MU-BAR
                            pos = pos + 52;
                    end
                else % Basic, MU-BAR
                    % UL FEC Coding Type (1 bit)
                    fecCoding = double(mpduBits(pos));
                    if fecCoding
                        cfgUserInfo.ChannelCoding = 'LDPC';
                    else
                        cfgUserInfo.ChannelCoding = 'BCC';
                    end
                    pos = pos + 1;

                    % UL MCS (4 bits)
                    mcs = bi2deOptimized(mpduBits(pos : pos+3)');
                    if mcs <= 11
                        cfgUserInfo.MCS = mcs;
                    else
                        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnknownULMCS', mcs);
                        status = wlanMACDecodeStatus.UnknownULMCS;
                        return;
                    end
                    pos = pos + 4;

                    % UL DCM (1 bit)
                    cfgUserInfo.DCM = double(mpduBits(pos));
                    pos = pos + 1;

                    % SS Allocation / RA-RU Information (6 bits)
                    if any(cfgUserInfo.AID12 == [0, 2045])
                        % RA-RU Information
                        % Num RA RU (5 bits)
                        cfgUserInfo.NumRARU = bi2deOptimized(mpduBits(pos : pos+4)')+1;
                        pos = pos + 5;

                        % More RA-RU (1 bit)
                        cfgUserInfo.MoreRARU = double(mpduBits(pos));
                        pos = pos + 1;
                    else
                        % SS Allocation
                        % Starting spatial stream (3 bits)
                        cfgUserInfo.StartingSpatialStream = bi2deOptimized(mpduBits(pos : pos+2)')+1;
                        pos = pos + 3;

                        % Number of spatial streams (3 bits)
                        cfgUserInfo.NumSpatialStreams = bi2deOptimized(mpduBits(pos : pos+2)')+1;
                        pos = pos + 3;
                    end

                    % UL Target RSSI (7 bits)
                    targetRSSI = bi2deOptimized(mpduBits(pos : pos+6)');
                    if (targetRSSI == 127)
                        cfgUserInfo.UseMaxTransmitPower = true;
                    elseif (targetRSSI >= 0) && (targetRSSI <= 90)
                        cfgUserInfo.UseMaxTransmitPower = false;
                        cfgUserInfo.TargetRSSI = targetRSSI-110;
                    else
                        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnknownTargetRSSI', targetRSSI);
                        status = wlanMACDecodeStatus.UnknownTargetRSSI;
                        return;
                    end
                    pos = pos + 7;

                    % Reserved (1 bit)
                    pos = pos + 1;

                    % Trigger Dependent User-Info
                    switch (cfgUserInfo.TriggerType)
                        case 'Basic'
                            % MPDU MU Spacing Factor (2 bits)
                            cfgUserInfo.MPDUMUSpacingFactor = bi2deOptimized(mpduBits(pos : pos+1)');
                            pos = pos + 2;

                            % TID Aggregation Limit (3 bits)
                            cfgUserInfo.TIDAggregationLimit = bi2deOptimized(mpduBits(pos : pos+2)');
                            pos = pos + 3;

                            % Reserved (1 bit)
                            pos = pos + 1;

                            % Preferred AC (2 bits)
                            cfgUserInfo.PreferredAC = bi2deOptimized(mpduBits(pos : pos+1)');
                            pos = pos + 2;

                        otherwise % 'MU-BAR'
                            % BAR Control (16 bits)
                            % BAR Ack Policy (1 bit)
                            pos = pos + 1;

                            % BAR Type (4 bits)
                            barType = bi2deOptimized(mpduBits(pos : pos+1)');
                            if barType ~= 2
                                optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnsupportedBARType', barType);
                                status = wlanMACDecodeStatus.UnsupportedBARType;
                                return;
                            end
                            pos = pos + 4;

                            % Reserved (7 bits)
                            pos = pos + 7;

                            % TID INFO (4 bits) (Only [0-7] are valid values)
                            cfgUserInfo.TID = bi2deOptimized(mpduBits(pos : pos+2)');
                            pos = pos + 4;

                            % BAR Information
                            % Fragment number (4-bits)
                            pos = pos + 4;

                            % Sequence number (12 bits)
                            cfgUserInfo.StartingSequenceNum = bi2deOptimized(mpduBits(pos : pos+11)');
                            pos = pos + 12;
                    end
                end
                triggerConfig = addUserInfo(triggerConfig, cfgUserInfo);
            end
            userInfoCount = userInfoCount + 1;
        end

        if noUserInfo
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:MissingUserInfo');
            status = wlanMACDecodeStatus.MissingUserInfo;
            return;
        end
    else
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'Common Info', minOctets);
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end
end

function [macConfig, status] = decodeBAFrameBody(mpduBits, pos, suppressWarns, macConfig, status)
    minOctets = 14;
    numDataBits = numel(mpduBits);

    % BA Control field (16 bits)
    minOctets = minOctets + 2;
    if numDataBits >= (pos + 15)
        % BA Ack Policy
        pos = pos + 1;

        % Check BA variant. Only compressed BA is supported.
        baVariant = bi2deOptimized(mpduBits(pos : pos + 3)');
        % Compressed BA variant code is 2
        if (baVariant ~= 2)
            optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:UnsupportedBAVariant', baVariant);
            status = wlanMACDecodeStatus.UnsupportedBAVariant;
            return;
        end
        pos = pos + 4;

        % Skip reserved fields
        pos = pos + 7;

        % TID Info (Only TIDs [0 - 7] are supported)
        macConfig.TID = bi2deOptimized(mpduBits(pos : pos + 2)');
        pos = pos + 4;
    else
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'BA Control', minOctets);
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end

    % BA Starting Sequence Control field (16 bits)
    minOctets = minOctets + 2;
    if numDataBits >= (pos + 15)
        % Fragment Number: If bit-3 is 0 and bits-(1,2) is 0, bitmap
        % size is 8 octets. If bit-3 is 0 and bits-(1,2) is 2, bitmap
        % size is 32 octets. If bit-3 is 1 and bits-(1,2) is 0, bitmap
        % size is 64 octets. If bit-3 is 1 and bits-(1,2) is 1, bitmap
        % size is 128 octets. Other combinations are reserved.
        bit_1_2 = bi2deOptimized(mpduBits(pos+1 : pos+2)');  
        bit_3 = double(mpduBits(pos + 3));
        if (bit_3 == 0) && (bit_1_2 == 0)
            bitmapSize = 8;
        elseif (bit_3 == 0) && (bit_1_2 == 2)
            bitmapSize = 32;
        elseif (bit_3 == 1) && (bit_1_2 == 0)
            bitmapSize = 64;
        elseif (bit_3 == 1) && (bit_1_2 == 1)
            bitmapSize = 128;
        else
            status = wlanMACDecodeStatus.UnknownBitmapSize;
            return;
        end
        pos = pos + 4;

        % Sequence Number
        macConfig.SequenceNumber = bi2deOptimized(mpduBits(pos : pos + 11)');
        pos = pos + 12;
    else
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'BA Starting Sequence Control', minOctets);
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end

    % BA Bitmap field
    minOctets = minOctets + bitmapSize;
    if numDataBits >= (pos + bitmapSize*8-1)
        % BA Bitmap
        bitmapOctets = wnet.internal.bits2octets(mpduBits(pos : pos+bitmapSize*8-1), false);
        bitmapOctets = bitmapOctets(end : -1 : 1);
        macConfig.BlockAckBitmap = reshape(dec2hex(bitmapOctets, 2)', 1, []);
    else
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseField', 'BA Bitmap', minOctets);
        status = wlanMACDecodeStatus.NotEnoughData;
        return;
    end
end

function [ruSize, ruIndex] = getRUInfo(ruAllocation)
  if ruAllocation <= 36
      ruSize = 26;
      ruIndex = ruAllocation + 1;
  elseif ruAllocation <= 52
      ruSize = 52;
      ruIndex = ruAllocation - 36;
  elseif ruAllocation <= 60
      ruSize = 106;
      ruIndex = ruAllocation - 52;
  elseif ruAllocation <= 64
      ruSize = 242;
      ruIndex = ruAllocation - 60;
  elseif ruAllocation <= 66
      ruSize = 484;
      ruIndex = ruAllocation - 64;
  elseif ruAllocation == 67
      ruSize = 996;
      ruIndex = 1;
  else % ruAllocation == 68
      ruSize = 1992;
      ruIndex = 1;
  end
end

% Validates the input arguments
function [status, mpduBits, suppressWarns, isMeshFrame, outputDecOctets, decodeEHTVariantTriggerFields, disableValidation] = validateInputs(mpdu, options)

    arguments
        mpdu
        options.DisableValidation = false;
        options.DecodeEHTVariantTriggerFields = false;
        options.DataFormat = 'bits';
        options.IsMeshFrame (1,1) {mustBeNumericOrLogical, mustBeReal, mustBeNonNan} = false;
        options.SuppressWarnings (1,1) {mustBeNumericOrLogical, mustBeReal, mustBeNonNan} = false;
        options.OutputDecimalOctets (1,1) logical = false;
    end

    % Initialize
    status = wlanMACDecodeStatus.Success;
    mpduLength = numel(mpdu);

    % Set outputs
    disableValidation = options.DisableValidation;
    decodeEHTVariantTriggerFields = options.DecodeEHTVariantTriggerFields;
    suppressWarns = options.SuppressWarnings;
    isMeshFrame = options.IsMeshFrame;
    outputDecOctets = options.OutputDecimalOctets;

    if disableValidation
        dataFormat = options.DataFormat;
    else
        expectedFormatValues = {'bits', 'octets'};
        dataFormat = validatestring(options.DataFormat, expectedFormatValues, mfilename);
        if isempty(mpdu) || (isstring(mpdu) && isscalar(mpdu) && (strlength(mpdu) == 0))
            coder.internal.error('wlan:shared:ExpectedNonEmptyValue');
        end
    end

    if strcmpi(dataFormat, 'bits')
        % Validate MPDU given in the form of bits
        if ~disableValidation
            validateattributes(mpdu, {'logical', 'numeric'}, {'binary', 'vector'}, '', 'MPDU');
        end
        if (rem(mpduLength, 8) ~= 0)
            coder.internal.error('wlan:shared:InvalidDataSize');
        end
        mpduBits = double(reshape(mpdu, [], 1));

    else % dataFormat == 'octets'
        % MPDU format must be in either hexadecimal or decimal octets
        if isnumeric(mpdu)
            validateattributes(mpdu, {'numeric'}, {'vector', 'integer', 'nonnegative', '<=', 255}, mfilename, 'MPDU');
            mpduBits = double(int2bit(mpdu, 8, false));

        else % char or string
            if ischar(mpdu)
                if isvector(mpdu)
                    % Convert row vector to column of octets.
                    columnOctets = reshape(mpdu, 2, [])';
                else
                    validateattributes(mpdu, {'char'}, {'2d', 'ncols', 2}, mfilename, 'MPDU', 1);
                    columnOctets = mpdu;
                end
            elseif isstring(mpdu) % string
                validateattributes(mpdu, {'string'}, {'scalar'}, mfilename, 'MPDU')

                % Convert octets to char type
                columnOctets = reshape(char(mpdu), 2, [])';
            else
                coder.internal.error('wlan:shared:UnexpectedFrameInputType', 'MPDU');
            end

            % Validate hex-digits
            wnet.internal.validateHexOctets(columnOctets, 'MPDU');

            % Converting hexadecimal format octets to integer format
            decOctets = hex2dec(columnOctets);

            mpduBits = int2bit(decOctets, 8, false);
        end
    end

    % Validate minimum length required to decode an MPDU. FCS (4 octets)
    % and Frame Control (2-octets) fields are the basic fields needed to
    % decode an MPDU.
    if (numel(mpduBits)/8 < 6)
        status = wlanMACDecodeStatus.NotEnoughData;
        optionalWarn(suppressWarns, 'wlan:wlanMPDUDecode:NotEnoughDataToParseMPDU');
    end
end

function dec = bi2deOptimized(bin)
    persistent pow2vector
    if isempty(pow2vector)
        pow2vector = 2.^(0 : 31)';
    end
    dec = bin * pow2vector(1:size(bin,2));
end

function optionalWarn(suppressWarns, warnID, varargin)
    if ~suppressWarns
        coder.internal.warning(warnID, varargin{:});
    end
end

