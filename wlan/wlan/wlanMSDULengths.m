function msduLengths = wlanMSDULengths(frameLength, macConfig, varargin)
%wlanMSDULengths Calculate MSDU lengths
%
%   MSDULENGTHS = wlanMSDULengths(FRAMELENGTH,MACCONFIG) creates a vector
%   of MSDU lengths that can be used to generate a MAC data frame of
%   specified length and MAC frame configuration. MSDU(s) refer to the
%   payload of a MAC data frame. This function returns multiple MSDU
%   lengths for an aggregated data frame.
%
%   MSDULENGTHS represents the suggested MSDU lengths in octets, returned
%   as a vector where each element represents the length of an MSDU in
%   octets.
%
%   FRAMELENGTH is the desired MAC frame length in octets, specified as a
%   number in the range [28, 15523198]. The maximum allowed value for frame
%   length varies depending on the MAC and PHY configuration.
%
%   MACCONFIG is the MAC frame configuration, specified as an object of
%   type wlanMACFrameConfig.
%
%   MSDULENGTHS = wlanMSDULengths(FRAMELENGTH,MACCONFIG,PHYCONFIG) creates
%   a vector of MSDU lengths that can be used to generate HE, VHT, or EHT
%   SU format frames and HT format aggregated frames.
%
%   PHYCONFIG is an object of type wlanHTConfig, wlanVHTConfig, 
%   wlanHESUConfig, or wlanEHTMUConfig matching the frame format in the 
%   MACCONFIG input. When FrameFormat is set to "EHT-SU" in the MACCONFIG,
%   the wlanEHTMUConfig must indicate the configuration for a single user
%   transmission. The function uses this input to ensure that the frame
%   does not exceed the transmission time limit, for EOF padding in VHT,
%   HE, or EHT format frames, and for maintaining minimum start spacing
%   between the MPDUs in an A-MPDU.

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

narginchk(2,3);
[frameLength, macConfig, phyConfig] = validateInputs(frameLength, macConfig, varargin{:});

% (Basic MAC header + FCS) = 28 octets
macHeaderFCSOverhead = 28;

if strcmp(macConfig.FrameType, 'QoS Data')
    % Address4 overhead (6 octets)
    if macConfig.ToDS && macConfig.FromDS
        macHeaderFCSOverhead = macHeaderFCSOverhead + 6;
    end
    
    % QoS Control overhead (2 octets)
    macHeaderFCSOverhead = macHeaderFCSOverhead + 2;
    
    if macConfig.HTControlPresent
        % HT Control overhead (4 octets)
        macHeaderFCSOverhead = macHeaderFCSOverhead + 4;
    end
    
    % A-MPDU
    if macConfig.MPDUAggregation
        % Calculate MSDU lengths to form an A-MPDU
        msduLengths = getAMPDUSubframeLengths(frameLength, macConfig, phyConfig);
        
    else % MPDU
        % MPDU contains A-MSDU
        if macConfig.MSDUAggregation
            % Calculate A-MSDU length
            amsduLength = (frameLength - macHeaderFCSOverhead);
            
            % Calculate MSDU lengths to form an MPDU with A-MSDU
            msduLengths = getAMSDUSubframeLengths(amsduLength, macConfig);
        else % MPDU contains MSDU
            % Calculate MSDU length
            msduLengths = frameLength - macHeaderFCSOverhead;
        end
    end
elseif strcmp(macConfig.FrameType, 'Data')
    % Calculate MSDU length
    msduLengths = frameLength - macHeaderFCSOverhead;
else
    % No MSDU payload for other frame types
    msduLengths = 0;
end
end

% Returns a vector of MSDU lengths required to form A-MSDU of a given length
function msduLengths = getAMSDUSubframeLengths(amsduLength, macConfig)
% A-MSDU subframe header length
amsduSubframeHdrLength = amsduSubframeHeaderLength(macConfig);
% Maximum MSDU length
maxMSDULength = 2304;

% In order to get a subframe aligned to 4 octets (without padding),
% (msduLength + subframeHeader) must be a multiple of 4 octets.
% ---------------------------------
% |   Header     |     MSDU       |
% | (14-octets)  |  (variable) ?  |
% ---------------------------------
% The total A-MSDU length is divided into equal parts. Each part is
% chosen such that the MSDU is of maximum possible length that results in
% a subframe aligned to 4 octets. The length of the last subframe is
% variable.
% The length of each part (excluding last subframe) is =
%                                 ((maxMSDULength-2) + subframeHeader)
maxLengthOfEachSubframe = (maxMSDULength-(rem(maxMSDULength + amsduSubframeHdrLength, 4))) + ...
    amsduSubframeHdrLength;
numMSDUs = ceil(amsduLength / maxLengthOfEachSubframe);

% Total random payload length that needs to be generated
totalRandomLength = (amsduLength - (numMSDUs)*amsduSubframeHdrLength);

% Each non-final MSDU length
nonFinalMSDULength = (maxLengthOfEachSubframe - amsduSubframeHdrLength);
% Final MSDU length

% If non-final MSDU lengths alone result in >= amsduLength, minimize
% the second last MSDU length to accommodate at least the header part
% of last MSDU
if totalRandomLength <= (numMSDUs - 1)*nonFinalMSDULength
    difference = (numMSDUs - 1)*nonFinalMSDULength - totalRandomLength;
    if abs(mod(difference, -4)) == 0
        numBytesToRemoveFromSecondLastMSDU = 4;
    else
        numBytesToRemoveFromSecondLastMSDU = abs(mod(difference, -4));
    end
    secondLastMSDULength = nonFinalMSDULength - (difference + numBytesToRemoveFromSecondLastMSDU);
else
    secondLastMSDULength = nonFinalMSDULength;
end

finalMSDULength = totalRandomLength - (numMSDUs - 2)*nonFinalMSDULength - secondLastMSDULength;

% Initialize with non-final MSDU length
msduLen = nonFinalMSDULength;

% Maximum number of A-MSDU subframes = ceil(11424/2304) = 5
msduLengthsBuffer = zeros(1, 5);
idx = 1;

for i = 1:numMSDUs
    if i == (numMSDUs - 1)
        msduLen = secondLastMSDULength;
    elseif i == numMSDUs
        msduLen = finalMSDULength;
    end
    msduLengthsBuffer(idx) = msduLen;
    idx = idx+1;
end
msduLengths = msduLengthsBuffer(1:idx-1);
end

% Returns a vector of MSDU lengths required to form an A-MPDU of a given length
function msduLengths = getAMPDUSubframeLengths(ampduLength, macConfig, phyConfig)
% Maximum length of an HT A-MSDU
maxHTAMSDULength = 4065;
% Maximum length of a HE, VHT, or EHT MPDU
maxHEorVHTorEHTMPDULength = 11454;
% (QoS Data header + FCS) = 30 octets
macHeaderFCSOverhead = 30;
% MPDU delimiter length is 4 octets
mpduDelimiterLength = 4;
% Maximum length of an MSDU
maxMSDULength = 2304;
% Mesh Control field has a fixed length of 6 octets and variable length of
% 0, 6 or 12 octets.
meshControlOverhead = 6 + macConfig.AddressExtensionMode*6;
% A-MSDU subframe header length
amsduSubframeHdrLen = amsduSubframeHeaderLength(macConfig);
% Indicates if next possible length exceeds the desired length (other than 4 byte alignment)
nexPossibleLengthExceedingDesiredLength = 0;

if any(strcmp(macConfig.FrameType, {'QoS Data', 'QoS Null'})) && macConfig.HTControlPresent
    % HT Control overhead (4 octets)
    macHeaderFCSOverhead = macHeaderFCSOverhead + 4;
    
    % Maximum MPDU length must not exceed 4095 in an A-MPDU. If the MAC
    % header size is 30, maximum A-MSDU possible is 4065. If HT Control
    % field is present, maximum A-MSDU size must be restricted to 4061
    maxHTAMSDULength = maxHTAMSDULength - 4;
end

if macConfig.ToDS && macConfig.FromDS
    % Address4 overhead (6 octets)
    macHeaderFCSOverhead = macHeaderFCSOverhead + 6;

    % Maximum MPDU length must not exceed 4095 in an A-MPDU. If the MAC
    % header size is 30, maximum A-MSDU possible is 4065. If Address4
    % field is present, maximum A-MSDU size must be restricted to 4059
    maxHTAMSDULength = maxHTAMSDULength - 6;
end

% For codegen
eachMPDULength = 0;
% Minimum overhead for each A-MPDU subframe
minOverheadPerAMPDUSubframe = macHeaderFCSOverhead + mpduDelimiterLength;

% Precalculate the length of MPDUs
if macConfig.MSDUAggregation
    minOverheadPerAMPDUSubframe = minOverheadPerAMPDUSubframe + amsduSubframeHdrLen;
    if any(strcmp(macConfig.FrameFormat, {'HE-SU', 'HE-EXT-SU', 'VHT', 'EHT-SU'}))
        eachMPDULength = maxHEorVHTorEHTMPDULength;
    elseif strcmp(macConfig.FrameFormat, 'HT-Mixed')
        eachMPDULength = maxHTAMSDULength + macHeaderFCSOverhead;
    end
else % If user does not want to include A-MSDUs in A-MPDU
    eachMPDULength = maxMSDULength + macHeaderFCSOverhead;
    if macConfig.HasMeshControl
        eachMPDULength = maxMSDULength + macHeaderFCSOverhead + meshControlOverhead;
        minOverheadPerAMPDUSubframe = minOverheadPerAMPDUSubframe + meshControlOverhead;
    end
end
% Max possible MPDU length
maxMPDULength = eachMPDULength;
% Make the MPDU length a multiple of 4 octets to avoid padding
eachMPDULength = eachMPDULength - rem(eachMPDULength, 4);

% Calculate minimum MPDU start spacing between consecutive MPDUs for the
% chosen MPDU length (eachMPDULength)
minSpacingOctets = wlan.internal.macMinimumMPDUSpacingOctets(macConfig.MinimumMPDUStartSpacing, ...
    phyConfig, (eachMPDULength + mpduDelimiterLength));

% Total A-MPDU length is divided into equal parts such that each MPDU
% is of the maximum possible length that is a multiple of 4 octets. The
% last part of an A-MPDU varies in length
%
% In order to get a subframe aligned to 4 octets (without padding),
% (mpduLength + delimiter) must be a multiple of 4 octets
% ---------------------------------
% |   Delimiter  |     MPDU       |
% |  (4-octets)  |  (variable) ?  |
% ---------------------------------
% The length of each part (except last subframe) is =
%    (maxMPDULength + mpduDelimiterLength + minSpacingOctets)
maxLengthOfEachSubframe = eachMPDULength + mpduDelimiterLength + minSpacingOctets;
numMPDUs = ceil(ampduLength / maxLengthOfEachSubframe);

% A maximum of 64 subframes are allowed in an HT/VHT A-MPDU that requires a
% response, a maximum of 256 subframes in an HE A-MPDU that requires a
% response, and a maximum of 1024 subframes in an EHT A-MPDU that requires
% a response. AMPDU expects Block Acknowledgment (BA) frame as an
% acknowledgment. The size of acknowledgment bitmap in BA is limited to
% 64-bits for HT/VHT frames, 256-bits for HE frames, and 1024-bits for EHT
% frames (Each bit represents acknowledgment of an AMPDU subframe). Maximum
% number of MPDUs are limited in an A-MPDU because of this bitmap.
%
% Refer section 9.3.1.8.2 in Std IEEE 802.11-2020, section 9.3.1.8.2 in Std
% IEEE 802.11ax-2021, and section 9.3.1.8.2 in Std IEEE 802.11be Draft 4.0.
if strcmp(macConfig.FrameFormat, "EHT-SU")
  maxMPDUs = 1024;
elseif any(strcmp(macConfig.FrameFormat, {'HE-SU','HE-EXT-SU'}))
  maxMPDUs = 256;
else % 'HT-Mixed', 'VHT'
  maxMPDUs = 64;
end

if (numMPDUs > maxMPDUs) && ~strcmp(macConfig.AckPolicy, 'No Ack')
    coder.internal.errorIf(~macConfig.MSDUAggregation, 'wlan:wlanMACFrame:AMPDUWithMSDUsLimitExceeded', macConfig.FrameFormat, maxMPDUs);
    coder.internal.errorIf(macConfig.MSDUAggregation, 'wlan:wlanMACFrame:AMPDUWithAMSDUsLimitExceeded', macConfig.FrameFormat, maxMPDUs);
end

% Non-final MSDU length
nonFinalMSDULength = eachMPDULength - macHeaderFCSOverhead;

if minSpacingOctets > 0
    % Mandatory minimum spacing between the start of two subframes when
    % MPDU and delimiter lengths are not considered
    mandatorySpaceBetweenMPDUs = maxLengthOfEachSubframe;

    % Calculate the remainder length from the given A-MPDU length and the
    % mandatory minimum spacing length
    remainingLength = rem(ampduLength, mandatorySpaceBetweenMPDUs);

    % The remainder length must be at least > (header + delimiter) length
    % to form a valid A-MPDU with the given minimum spacing configuration
    coder.internal.errorIf(remainingLength <= (macHeaderFCSOverhead + mpduDelimiterLength), 'wlan:wlanMACFrame:IncompatibleLength', (macHeaderFCSOverhead + mpduDelimiterLength - remainingLength + 1));
    
    % If the remainder length is between (max MSDU + header +
    % delimiter) and (mandatory minimum spacing between MPDUs), a valid
    % A-MPDU cannot be formed. To create a valid A-MPDU, we'll need at
    % least N octets to cover up the minimum spacing and also a last
    % subframe with at least 1 octet data
    coder.internal.errorIf((remainingLength > (2304 + macHeaderFCSOverhead + mpduDelimiterLength)) && (remainingLength < mandatorySpaceBetweenMPDUs), 'wlan:wlanMACFrame:IncompatibleLength', (maxLengthOfEachSubframe + macHeaderFCSOverhead + mpduDelimiterLength - remainingLength + 1));
    
    % Calculate the last and second last MSDU lengths
    finalMSDULength = remainingLength - macHeaderFCSOverhead - mpduDelimiterLength;
    secondLastMSDULength = nonFinalMSDULength;
else
    % Total random payload length that needs to be generated
    totalRandomLength = (ampduLength - numMPDUs*(macHeaderFCSOverhead + mpduDelimiterLength));
    
    % If non-final MSDU lengths alone result in >= ampduLength, minimize
    % the second last MSDU length to accommodate at least the header part
    % of last MSDU
    if (totalRandomLength <= (numMPDUs - 1)*nonFinalMSDULength)        
        if macConfig.MSDUAggregation
            % If MSDU aggregation is enabled, do not adjust the second last
            % AMPDU subframe length, since wlanMACFrame tries to
            % concatenate all MSDUs until max A-MSDU length is reached.
            % Instead, try these 2 things:
            %   1. Check if N-1 MPDUs can accommodate desired length by
            %   adjusting the last AMPDU subframe length.
            %   2. If the above case is not possible, output MSDU lengths
            %   that result in the next possible AMPDU length - which may
            %   exceed the desired input length due to an additional MPDU.

            % Check if N-1 MPDUs can fit in the required length without
            % exceeding the max MPDU length.
            numMPDUs = numMPDUs-1;
            totalRandomLength = (ampduLength - numMPDUs*(macHeaderFCSOverhead + mpduDelimiterLength));
            secondLastMSDULength = nonFinalMSDULength;
            finalMSDULength = totalRandomLength - (numMPDUs - 2)*nonFinalMSDULength - secondLastMSDULength;
            anticipatedMPDULength = finalMSDULength + macHeaderFCSOverhead;

            % If N-1 MPDUs cannot fit in the required length without
            % exceeding the max MPDU length, the next possible length
            % requires at least one more MPDU, which means the output
            % length exceeds the given length. Provide a warning stating
            % this and displaying the anticipated length.
            if anticipatedMPDULength > maxMPDULength
                numMPDUs =  numMPDUs + 1;
                secondLastMSDULength = nonFinalMSDULength;
                finalMSDULength = 4 + amsduSubframeHdrLen;
                nexPossibleLengthExceedingDesiredLength = (numMPDUs-1)*nonFinalMSDULength + numMPDUs*(macHeaderFCSOverhead + mpduDelimiterLength) + finalMSDULength;
                if mod(nexPossibleLengthExceedingDesiredLength,4)
                    nexPossibleLengthExceedingDesiredLength = nexPossibleLengthExceedingDesiredLength + 4 - rem(nexPossibleLengthExceedingDesiredLength , 4);
                end
                coder.internal.warning('wlan:wlanMACFrame:InsufficientLengthForOverhead', nexPossibleLengthExceedingDesiredLength);
            end
        else
            difference = (numMPDUs - 1)*nonFinalMSDULength - totalRandomLength;
            if abs(mod(difference, -4)) == 0
                numBytesToRemoveFromSecondLastMSDU = 4;
            else
                numBytesToRemoveFromSecondLastMSDU = abs(mod(difference, -4));
            end
            secondLastMSDULength = nonFinalMSDULength - (difference + numBytesToRemoveFromSecondLastMSDU);
            finalMSDULength = totalRandomLength - (numMPDUs - 2)*nonFinalMSDULength - secondLastMSDULength;
        end

        % If the calculated second MSDU length has minimum spacing greater
        % than zero, a valid A-MPDU of given length cannot be formed with
        % specified minimum spacing configuration
        secondLastMinSpacing = wlan.internal.macMinimumMPDUSpacingOctets(macConfig.MinimumMPDUStartSpacing, ...
            phyConfig, (secondLastMSDULength + macHeaderFCSOverhead + mpduDelimiterLength));
        coder.internal.errorIf(secondLastMinSpacing > 0, 'wlan:wlanMACFrame:IncompatibleLength', secondLastMinSpacing);
    else
        secondLastMSDULength = nonFinalMSDULength;
        finalMSDULength = totalRandomLength - (numMPDUs - 2)*nonFinalMSDULength - secondLastMSDULength;
        if macConfig.MSDUAggregation
            diff = ampduLength - (numMPDUs-1)*maxLengthOfEachSubframe;
            isLengthInsufficientForOverhead = (diff <= minOverheadPerAMPDUSubframe);
            % If length is insufficient with the overhead of AMSDUs
            % considered, calculate the next possible length with the
            % minimum required overhead (4 byte payload + AMSDU header
            % overhead).
            if isLengthInsufficientForOverhead
                finalMSDULength = 4 + amsduSubframeHdrLen;
                nexPossibleLengthExceedingDesiredLength = (numMPDUs-1)*nonFinalMSDULength + numMPDUs*(macHeaderFCSOverhead + mpduDelimiterLength) + finalMSDULength;
                if mod(nexPossibleLengthExceedingDesiredLength,4)
                    nexPossibleLengthExceedingDesiredLength = nexPossibleLengthExceedingDesiredLength + 4 - rem(nexPossibleLengthExceedingDesiredLength , 4);
                end
                coder.internal.warning('wlan:wlanMACFrame:InsufficientLengthForOverhead', nexPossibleLengthExceedingDesiredLength);
            end
        end
    end
end

% Initialize with non-final MSDU length
msduLen = nonFinalMSDULength;

% To form a MAC frame of specific length, we try to put max-sized MSDUs
% into the MAC frame.
%   maxNumOfMSDUs = (max MAC frame size)/(max A-MPDU subframe size without A-MSDU)
%   * Max MAC frame-size (A-MPDU) is 15523198 octets
%   * Max AMPDU subframe size with single MSDU is 2336 octets
%    (2302 [max MSDU size used] + 30 [minimum MAC header] + 4 [MPDU delimiter])
%   maxNumOfMSDUs = ceil(15523198/ 2336) = 6646
msduLengthsBuffer = zeros(1, 6646);
idx = 1;

for i = 1:numMPDUs
    if i == (numMPDUs - 1)
        msduLen = secondLastMSDULength;
    elseif i == numMPDUs
        msduLen = finalMSDULength;
    end
    
    % Put A-MSDUs into MPDU
    if macConfig.MSDUAggregation
        amsduSubframeLengths = getAMSDUSubframeLengths(msduLen, macConfig);
        msduLengthsBuffer(idx: idx+numel(amsduSubframeLengths)-1) = amsduSubframeLengths;
        idx = idx+numel(amsduSubframeLengths);
    else % Put MSDUs into MPDU
        if macConfig.HasMeshControl
            msduLen = msduLen - meshControlOverhead;
        end
        msduLengthsBuffer(idx) = msduLen;
        idx = idx+1;
    end
end
msduLengths = msduLengthsBuffer(1:idx-1);

if ~nexPossibleLengthExceedingDesiredLength && any(strcmp(macConfig.FrameFormat, {'VHT', 'HE-SU', 'HE-EXT-SU', 'EHT-SU'})) && (rem(ampduLength, 4) > 0)
    coder.internal.warning('wlan:wlanMACFrame:ResultsInWordAlignedAMPDU');
end

end

% Validate the inputs
function [frameLength, macConfig, phyConfig] = validateInputs(frameLength, macConfig, phyConfig)
% Refer section 9.7.1 in IEEE Std 802.11be Draft 4.0 for A-MPDU length
% limits. In addition to these limits, EHT format A-MPDU length is limited
% to 15523198 due to PSDU length limit restriction specified in Table 36-70
% of IEEE Std 802.11be Draft 4.0

maxHTAMPDULength = 65535;
maxVHTAMPDULength = 1048575;
maxHEAMPDULength = 6500631;
maxEHTAMPDULength = 15523198;

validateattributes(frameLength, {'numeric'}, {'scalar', 'integer'}, 'wlanMSDULengths', 'argument-1');
validateattributes(macConfig, {'wlanMACFrameConfig'}, {}, 'wlanMSDULengths', 'argument-2');

if nargin == 3 % phyConfig is an optional input
    % Validate phyConfig object
    validateattributes(phyConfig, {'wlanHTConfig', 'wlanVHTConfig', 'wlanHESUConfig', 'wlanEHTMUConfig'}, {'scalar'}, 'wlanMSDULengths', 'argument-3');
    
    if strcmp(macConfig.FrameType, 'QoS Data')
        % Validate wlanHTConfig object for HT format
        coder.internal.errorIf(strcmp(macConfig.FrameFormat, 'HT-Mixed') && ~isa(phyConfig, 'wlanHTConfig'), ...
            'wlan:wlanMACFrame:InvalidPHYConfig', 'HT-Mixed', 'wlanHTConfig');
        
        % Validate wlanVHTConfig object for VHT format
        coder.internal.errorIf(strcmp(macConfig.FrameFormat, 'VHT') && ~isa(phyConfig, 'wlanVHTConfig'), ...
            'wlan:wlanMACFrame:InvalidPHYConfig', 'VHT', 'wlanVHTConfig');
        
        % Validate wlanHESUConfig object for HE format
        coder.internal.errorIf(any(strcmp(macConfig.FrameFormat, {'HE-SU', 'HE-EXT-SU'})) && ~isa(phyConfig, 'wlanHESUConfig'), ...
            'wlan:wlanMACFrame:InvalidPHYConfig', 'HE', 'wlanHESUConfig');
        
        % Validate wlanEHTMUConfig object for EHT format
        coder.internal.errorIf(strcmp(macConfig.FrameFormat, 'EHT-SU') && (~isa(phyConfig, 'wlanEHTMUConfig') || (isa(phyConfig, 'wlanEHTMUConfig') && (numel(phyConfig.User) ~= 1))), 'wlan:wlanMACFrame:InvalidEHTPHYConfig');

        % Validate unsupported EHT DUP format
        coder.internal.errorIf(isa(phyConfig, 'wlanEHTMUConfig') && phyConfig.EHTDUPMode, 'wlan:wlanMACFrame:EHTDUPModeNotSupported');

        % Validate HE-SU and HE-EXT-SU formats
        coder.internal.errorIf(isa(phyConfig, 'wlanHESUConfig') && ~strcmp(phyConfig.packetFormat, macConfig.FrameFormat), 'wlan:wlanMACFrame:HEFormatMismatch');
    end
                
    % HT Format A-MPDU Maximum length validation
    coder.internal.errorIf((strcmp(macConfig.FrameFormat, 'HT-Mixed') && (frameLength > maxHTAMPDULength)), ...
        'wlan:wlanMACFrame:MoreThanMaxLimit', maxHTAMPDULength, 'HT-Mixed format frame');
    
    % VHT format A-MPDU Maximum length validation
    coder.internal.errorIf((strcmp(macConfig.FrameFormat, 'VHT') && (frameLength > maxVHTAMPDULength)), ...
        'wlan:wlanMACFrame:MoreThanMaxLimit', maxVHTAMPDULength, 'VHT format frame');
    
    % HE format A-MPDU Maximum length validation
    coder.internal.errorIf((any(strcmp(macConfig.FrameFormat, {'HE-SU', 'HE-EXT-SU'})) && (frameLength > maxHEAMPDULength)), ...
        'wlan:wlanMACFrame:MoreThanMaxLimit', maxHEAMPDULength, 'HE format frame');

    % EHT format A-MPDU Maximum length validation
    coder.internal.errorIf((strcmp(macConfig.FrameFormat, 'EHT-SU') && (frameLength > maxEHTAMPDULength)), ...
        'wlan:wlanMACFrame:MoreThanMaxLimit', maxEHTAMPDULength, 'EHT format frame');
    
    % Validate frame transmission time
    if isa(phyConfig, 'wlanHTConfig')
        phyConfig.PSDULength = frameLength;
    elseif isa(phyConfig, 'wlanEHTMUConfig')
        userIndexSU = 1; % Assume single user
        phyConfig.User{userIndexSU}.APEPLength = frameLength;
    else % HE-SU, HE-EXT-SU or VHT
        phyConfig.APEPLength = frameLength;
    end
    validateConfig(phyConfig, 'MCS');
else
    coder.internal.errorIf(strcmp(macConfig.FrameType, 'QoS Data') && ...
        (any(strcmp(macConfig.FrameFormat, {'VHT', 'HE-SU', 'HE-EXT-SU', 'EHT-SU'})) || ...
        (strcmp(macConfig.FrameFormat, 'HT-Mixed') && (macConfig.MSDUAggregation || macConfig.MPDUAggregation))), ...
        'wlan:wlanMACFrame:PHYConfigRequired');

    if coder.target('MATLAB')
        phyConfig = [];
    else % Codegen path
        % For codegen: assign default PHY configuration
        phyConfig = wlanVHTConfig;
    end
end

if any(strcmp(macConfig.FrameFormat, {'VHT', 'HE-SU', 'HE-EXT-SU', 'EHT-SU'})) && ...
        strcmp(macConfig.FrameType, 'QoS Data')
    % HE and VHT format data frames are always sent as A-MPDUs
    macConfig.MPDUAggregation = true;
elseif strcmp(macConfig.FrameFormat, 'Non-HT')
    % Non-HT format frame cannot be an A-MPDU
    macConfig.MPDUAggregation = false;
    % Non-HT format frames do not contain HT-Control field
    macConfig.HTControlPresent = false;
end

% Only one of ESSCapability and IBSSCapability must be true for Beacon
coder.internal.errorIf(strcmp(macConfig.FrameType, 'Beacon') && ...
    (macConfig.ManagementConfig.ESSCapability && macConfig.ManagementConfig.IBSSCapability), 'wlan:wlanMACFrame:ESSAndIBSS');

headerFCSOverhead = 28;
delimiterLength = 4;
amsduSubframeHeaderLen = 14;
% Mesh Control field has a fixed length of 6 octets and variable length of
% 0, 6 or 12 octets.
meshControlOverhead = 6 + macConfig.AddressExtensionMode*6;
if macConfig.HasMeshControl
    amsduSubframeHeaderLen = amsduSubframeHeaderLen + meshControlOverhead;
end
% Refer table 9-19 in IEEE Std 802.11ax Draft 3.1 for MSDU/A-MSDU length
% limits
maxMSDULength = 2304;
maxNonHTAMSDULength = 4065;
maxHTAMSDULength = 7935;

% Validate frame length for each data frame type
switch(macConfig.FrameType)
    case 'Data'
        % Minimum length
        coder.internal.errorIf(strcmp(macConfig.FrameType, 'Data') && (frameLength < headerFCSOverhead), 'wlan:wlanMACFrame:LessThanMinLimit', ...
            headerFCSOverhead, 'Data frame');
        
        % Maximum length
        maxLength = (headerFCSOverhead + maxMSDULength);
        coder.internal.errorIf(strcmp(macConfig.FrameType, 'Data') && (frameLength > maxLength), 'wlan:wlanMACFrame:MoreThanMaxLimit', maxLength, 'Data frame');
        
    case 'QoS Data'
        % Address4 overhead (6 octets)
        if macConfig.ToDS && macConfig.FromDS
            headerFCSOverhead = headerFCSOverhead + 6;
        end
        
        % QoS Control overhead (2 octets)
        headerFCSOverhead = headerFCSOverhead + 2;
        
        if macConfig.HTControlPresent
            % HT Control overhead (4 octets)
            headerFCSOverhead = headerFCSOverhead + 4;
        end
        
        % QoS Data with MSDU
        if ~macConfig.MSDUAggregation && ~macConfig.MPDUAggregation
            % Minimum length
            coder.internal.errorIf(strcmp(macConfig.FrameType, 'QoS Data') && ~macConfig.MSDUAggregation && ~macConfig.MPDUAggregation && (frameLength < headerFCSOverhead), 'wlan:wlanMACFrame:LessThanMinLimit', ...
                headerFCSOverhead, 'QoS Data containing MSDU');
            
            % Maximum length
            if macConfig.HasMeshControl
                maxLength = (headerFCSOverhead + meshControlOverhead + maxMSDULength);
            else
                maxLength = (headerFCSOverhead + maxMSDULength);
            end
            coder.internal.errorIf(strcmp(macConfig.FrameType, 'QoS Data') && ~macConfig.MSDUAggregation && ~macConfig.MPDUAggregation && (frameLength > maxLength), 'wlan:wlanMACFrame:MoreThanMaxLimit', ...
                maxLength, 'QoS Data containing MSDU');
            
        elseif macConfig.MPDUAggregation
            % A-MPDU with A-MSDU
            if macConfig.MSDUAggregation
                % Minimum length with A-MSDU
                minLength = (headerFCSOverhead + delimiterLength + amsduSubframeHeaderLen);
                coder.internal.errorIf(strcmp(macConfig.FrameType, 'QoS Data') && macConfig.MSDUAggregation && macConfig.MPDUAggregation && (frameLength < minLength), 'wlan:wlanMACFrame:LessThanMinLimit', ...
                    minLength, 'A-MPDU with given configuration');
                
            else % A-MPDU with MSDU
                % Minimum length with MSDU
                minLength = (headerFCSOverhead + delimiterLength);
                coder.internal.errorIf(strcmp(macConfig.FrameType, 'QoS Data') && ~macConfig.MSDUAggregation && macConfig.MPDUAggregation && (frameLength < minLength), 'wlan:wlanMACFrame:LessThanMinLimit', ...
                    minLength, 'A-MPDU with given configuration');
            end
            
        else % MSDUAggregation == true
            % QoS Data with A-MSDU
            minLength = (headerFCSOverhead + amsduSubframeHeaderLen);
            coder.internal.errorIf(strcmp(macConfig.FrameType, 'QoS Data') && macConfig.MSDUAggregation && ~macConfig.MPDUAggregation && (frameLength < minLength), 'wlan:wlanMACFrame:LessThanMinLimit', ...
                minLength, 'QoS Data with given configuration');
            
            if strcmp(macConfig.FrameFormat, 'Non-HT')
                % Maximum length
                maxLength = (headerFCSOverhead + maxNonHTAMSDULength);
                coder.internal.errorIf(strcmp(macConfig.FrameType, 'QoS Data') && strcmp(macConfig.FrameFormat, 'Non-HT') && macConfig.MSDUAggregation && ~macConfig.MPDUAggregation && strcmp(macConfig.FrameFormat, 'Non-HT') && (frameLength > maxLength), 'wlan:wlanMACFrame:MoreThanMaxLimit', ...
                    maxLength, 'Non-HT format QoS Data containing A-MSDU');
                
            elseif strcmp(macConfig.FrameFormat, 'HT-Mixed')
                % Maximum length
                maxLength = (headerFCSOverhead + maxHTAMSDULength);
                coder.internal.errorIf(strcmp(macConfig.FrameType, 'QoS Data') && strcmp(macConfig.FrameFormat, 'Non-HT') && macConfig.MSDUAggregation && ~macConfig.MPDUAggregation && strcmp(macConfig.FrameFormat, 'HT-Mixed') && (frameLength > maxLength), 'wlan:wlanMACFrame:MoreThanMaxLimit', ...
                    maxLength, 'HT-Mixed format QoS Data containing A-MSDU');
            end
        end

        if macConfig.IsMeshFrame
            % AddressExtensionMode must be set to 1 only when ToDS is false
            % and FromDS is true
            coder.internal.errorIf(~(~macConfig.ToDS && macConfig.FromDS) && macConfig.AddressExtensionMode == 1, ...
                'wlan:wlanMACFrame:InvalidAddressExtModeValue1');
            % AddressExtensionMode must be set to 2 only when both ToDS and
            % FromDS are set to true
            coder.internal.errorIf(~(macConfig.ToDS && macConfig.FromDS) && macConfig.AddressExtensionMode == 2, ...
                'wlan:wlanMACFrame:InvalidAddressExtModeValue2');
        end
end
end

function len = amsduSubframeHeaderLength(macConfig)
    len = 14;
    % Mesh Control field has a fixed length of 6 octets and variable length of
    % 0, 6 or 12 octets.
    meshControlOverhead = 6 + macConfig.AddressExtensionMode*6;
    if macConfig.HasMeshControl
        len = len + meshControlOverhead;
    end
end
