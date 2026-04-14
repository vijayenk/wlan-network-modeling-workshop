function [informationElements, varargout] = generateBeaconInformationElements(mpduFrameBody, bandAndChannel, MACFrameAbstraction, varargin)
%generateBeaconInformationElements Generates the beacon payload parameters
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   [INFORMATIONELEMENTS, ELEMENTIDS, TOTALPAYLOADLENGTH] =
%   generateBeaconInformationElements(MPDUFRAMEBODY, BANDANDCHANNEL,
%   MACFRAMEABSTRACTION) generates the beacon payload parameters, according
%   to the user specified configuration.
%
%   INFORMATIONELEMENTS is a cell array containing:
%       * Size of each IE, when MACFRAMEABSTRACTION is true
%       * Each IE in hexadecimal octets, when MACFRAMEABSTRACTION is false
%       * This does not take into account the size or hexadecimal octets
%         for the element ID and element length fields
%
%   ELEMENTIDS is a cell array containing the element IDs of the information elements (IEs) generated.
%
%   TOTALPAYLOADLENGTH is total payload length of the beacon, including
%   mandatory fields (Timestamp, Beacon interval and Capabilities)and IEs.
%   This takes into account the total length of all IEs, including their
%   element ID and element length fields.
%
%   MPDUFRAMEBODY is a structure of type wlan.internal.defaultMPDUFrameBody
%   frame type as 'Beacon'.
%
%   BANDANDCHANNEL is a vector of 2 values where first element represents
%   band as 2.4, 5, or 6 GHz and the second element represents the channel
%   number.
%
%   MACFRAMEABSTRACTION is a logical scalar specifying the abstraction mode
%   of MAC. Set to true, for abstract MAC, false otherwise.
%
%   INFORMATIONELEMENTS = generateBeaconInformationElements(MPDU,
%   BANDANDCHANNEL, MACFRAMEABSTRACTION, ELEMENTID) generates the IE
%   corresponding to the element ID (ELEMENTID) and configuration of the
%   frame (MPDU) specified by the user.

%   Copyright 2023-2025 The MathWorks, Inc.

narginchk(3,4);
nargoutchk(1,3);

if nargin > 3 % Generate a particular information element
    informationElements = generateInformationElement(varargin{1}, mpduFrameBody);
else % Generate all information elements
    if MACFrameAbstraction
        [elementIDs, informationElements] = generateAbstractMACBeaconIEs(mpduFrameBody, bandAndChannel);
    else
        [elementIDs, informationElements] = generateFullMACBeaconIEs(mpduFrameBody, bandAndChannel);
    end

    % Mandatory Fields - Timestamp (8), Beacon interval (2), Capabilities (2), in octets
    fieldLength = 12;
    % Calculate total size of element ID and element length fields
    totalElementLengthBytes = numel(informationElements);
    totalElementIDBytes = 0;
    for elementIDx = 1:totalElementLengthBytes
        totalElementIDBytes = totalElementIDBytes + numel(elementIDs{elementIDx});
    end

    if MACFrameAbstraction
        totalIEBytes = sum([informationElements{:}]); % IE Sizes are directly in octets
    else
        totalIEBytes = 0;
        for IEIdx = 1:totalElementLengthBytes
            totalIEBytes = totalIEBytes + numel(informationElements{IEIdx})/2; % IE Size = Size of Hexadecimal output/2
        end
    end
    % Calculate total payload length
    informationElementLength = totalElementLengthBytes + totalElementIDBytes + totalIEBytes; % Octets
    totalPayloadLength = fieldLength + informationElementLength;

    % Assign outputs
    varargout{1} = elementIDs;
    varargout{2} = totalPayloadLength;
end
end

function [elementIDs, informationElements] = generateAbstractMACBeaconIEs(mpduFrameBody, bandAndChannel)
%generateAbstractMACBeaconIEs Generate the element IDs and the size of information element
%corresponding to each element ID for abstract MAC.

elementIDs = {zeros(0, 2)}; % Decimal values of element IDs, and/or extensions
informationElements = {zeros(0, 1)}; % Size in octets, of information field in an element

band = bandAndChannel(1);
cbw = mpduFrameBody.ChannelBandwidth;

% SSID Parameter Set Element
elementIDs{1} = 0;
if mpduFrameBody.IsMeshBeacon
    SSID = ""; % Wildcard SSID
else
    SSID = mpduFrameBody.SSID;
end
decOctets = uint8(char(SSID));
informationElements{1} = numel(decOctets); % Return the size of information field

% Supported Rates Element
elementIDs{2} = 1;
informationElements{2} = 8;

% EDCA Parameter Set Element
% QoSInfo - 1 octet
% Update EDCA Info - 1 octet
% Parameter Records - 16 octets, 4 for each AC
if ~mpduFrameBody.IsMeshBeacon
    elementIDs{3} = 12;
    informationElements{3} = 18;
end

% Extended Capabilities Element
elementIDs{4} = 127;
informationElements{4} = 3;

% HT Capabilities Element
elementIDs{5} = 45;
informationElements{5} = 26;

% HT Operation Element
if band == 2.4 || band == 5
    elementIDs{6} = 61;
    informationElements{6} = 22;
end

% VHT Capabilities Element
elementIDs{7} = 191;
informationElements{7} = 12;

% VHT Operation Element
if band == 5 % VHT is supported only in 5 GHz band
    elementIDs{8} = 192;
    informationElements{8} = 5;
end

% HE Capabilities Element
elementIDs{9} = [255 35];
% In 2.4 GHz band, B2 bit of Supported Channel Width Set is reserved, so do
% not include Tx and Rx maps for 160 MHz. For 5 GHz and 6 GHz bands, B2 is
% present and marked as supported, so include Tx and Rx maps for both 80
% MHz and 160 MHz. Thus, size of IE is set accordingly. Refer section
% 9.4.2.248.4 in IEEE Std 802.11-2021.
if band == 2.4
    % Fill both Tx and Rx maps, for 80 MHz
    informationElements{9} = 21;
else
    % Fill both Tx and Rx maps, for 80 MHz and 160 MHz
    informationElements{9} = 25;
end

% HE Operation Element
elementIDs{10} = [255 36];
if band == 6
    informationElements{10} = 11; % 6 GHz Operation Information (5 octets) also present
else
    informationElements{10} = 6;
end

% EHT Operation Element
elementIDs{11} = [255 106];
informationElements{11} = 5;
% EHT operation information (extra 3 octets) is present for 6 GHz band and
% 320 MHz configured bandwidth. Refer section 35.15.1 in IEEE P802.11be/D5.0.
if band == 6 && cbw == 320 % 6 GHz and 320 MHz
    informationElements{11} = informationElements{11} + 3;
end

% EHT capabilities element
elementIDs{12} = [255 108];
informationElements{12} = 20;

if mpduFrameBody.IsAffiliatedWithMLD
    % Basic Multi Link Element
    elementIDs{13} = [255 107];
    informationElements{13} = 15; % Multi Link Control - 2, Common Info - 13

    % Reduced Neighbor Report Element
    if mpduFrameBody.NumLinks > 1
        elementIDs{14} = 201;
        informationElements{14} = 20*(mpduFrameBody.NumLinks-1);
    end
end

if mpduFrameBody.IsMeshBeacon
    % Mesh ID Element
    elementIDs{15} = 114;
    meshID = mpduFrameBody.SSID;
    decOctets = uint8(char(meshID));
    informationElements{15} = numel(decOctets); % Return the size of information field

    % Mesh Configuration Element
    elementIDs{16} = 113;
    informationElements{16} = 7;
end

% Remove all empty values
nonEmptyElementIndices = ~cellfun('isempty',elementIDs);
elementIDs = elementIDs(nonEmptyElementIndices);
% Remove all empty values except the first element (SSID), since Wildcard
% SSIDs, if present, are considered empty strings
informationElements = informationElements(nonEmptyElementIndices);
end

function [elementIDs, informationElements] = generateFullMACBeaconIEs(mpduFrameBody, bandAndChannel)
%generateFullMACBeaconIEs Generate the element IDs and the information
%element (hexadecimal octets) corresponding to each element ID for full MAC.

elementIDs = {zeros(0, 2)};
informationElements = {zeros(0, 1)};

% SSID Parameter Set Element
% For more information, refer section 9.4.2.2 in IEEE Std 802.11-2020.
elementIDs{1} = 0;
if mpduFrameBody.IsMeshBeacon
    SSID = ""; % Wildcard SSID
else
    SSID = mpduFrameBody.SSID;
end
% Construct the information field for the SSID IE
decOctets = uint8(char(SSID));
informationElements{1} = reshape(dec2hex(decOctets, 2)', 1, []);

% Supported Rates Element
% Each rate contained in the BSSBasicRateSet parameter is encoded as an
% octet with MSB (bit 7) set to 1, and bits 6 to 0 are set to the data rate,
% if necessary rounded up to the next 500 Kb/s, in units of 500 kb/s.
% The following rates are supported in the simulation: 6,9,12,18,24,36,48,54.
% Units are in Mbps. BSS membership selectors are not supported in this implementation.
% For more information, refer section 9.4.2.3 in IEEE Std 802.11-2020.
elementIDs{2} = 1;
supportedRates = [6 9 12 18 24 36 48 54]; % Units in Mbps
basicRates = mpduFrameBody.BasicRates; % Subset of the supported rates
additionalRates = setdiff(supportedRates,basicRates);
additionalRates = ceil(additionalRates*1000/500); % Units of 500 kbps
basicRates = ceil(basicRates*1000/500); % Units of 500 kbps
hexRates = '0'; % Initialize
for rateIdx = 1:numel(basicRates)
    rateBits = [1 bitget(basicRates(rateIdx),7:-1:1)]; % Set MSB bit 1
    rateHexBytes = dec2hex(bi2deOptimized(rateBits),2);
    hexRates = [hexRates rateHexBytes]; %#ok<AGROW>
end
for rateIdx = 1:numel(additionalRates)
    rateBits = [0 bitget(additionalRates(rateIdx),7:-1:1)]; % Set MSB bit 0
    rateHexBytes = dec2hex(bi2deOptimized(rateBits),2);
    hexRates = [hexRates rateHexBytes]; %#ok<AGROW>
end
informationElements{2} = hexRates(2:end); % Remove the initialized value '0'

% EDCA Parameter Set Element
if ~mpduFrameBody.IsMeshBeacon
    elementIDs{3} = 12;
    informationElements{3} = formEDCAParameterSetOctets(mpduFrameBody);
end

% Store in local variables for reuse
cbw = mpduFrameBody.ChannelBandwidth;
band = bandAndChannel(1);
channel = bandAndChannel(2);
primaryChannel = mpduFrameBody.PrimaryChannel(mpduFrameBody.LinkID);

% Extended Capabilities Element
% For more information, refer section 9.4.2.26 in IEEE Std 802.11-2020.
elementIDs{4} = 127;
% Octet 1 - 20/40 BSS Coexistence Management Support set to 1 if Supported
% Channel width in HT capabilities is set to 1. Refer section 11.15.1 in
% IEEE Std 802.11-2020
% Octet 3 - QoS Traffic capability supported
informationElements{4} = '010010';

% HT Capabilities Element
% For more information, refer section 9.4.2.55 in IEEE Std 802.11-2020.
elementIDs{5} = 45;

% HT Capabilities information (hex) - HT Support Channel width (both 20 MHz
% and 40 MHz supported), HT SM Power Save (disabled). Note that MSDU
% aggregation is not supported, so Max A-MSDU length bit is set 0 for lack
% of appropriate value
htCapabilitiesInfo = '0e00';

% AMPDU Parameters
% Maximum length supported for an AMDPU is 65535 octets
% Maximum AMPDU Length Exponent is calculated as:
%   log2(65535+1) - 13 = 3; (Binary - 11)
% Minimum MPDU Start Spacing = 0, for no restriction (Binary - 000)
% Remaining 3 bits are reserved (000)
% AMPDU Parameters field in binary bits is 000 000 11, converted to hex
% gives '03'
ampduParameters = '03';

% Rx MCS Bitmask
% Based on the maximum number of allowed spatial streams for HT(4) and
% the channel bandwidth, the following MCSs are supported
% MCS 0-7, for 20 MHz, 1 spatial stream (mandatory)
% MCS 8-15 for 20 MHz, 2 spatial streams (optional)
% MCS 16-23 for 20 MHz, 3 spatial streams (optional)
% MCS 24-31 for 20 MHz, 4 spatial streams (optional)
% Maximum of 4 spatial streams are allowed for HT PHY, so MCS 0-31 are supported.
% MCS order in bitmask is [(0-7) (8-15) (16-23) (24-31) (32) (33-38) (39-52) (53-76)]
hexRxMCSBitmask = ['ff' 'ff' 'ff' 'ff' '00' '00' '00' '00' '00' '00'];

htDataRate = 540; % Max HT data rate is 540 Mbps, for 40 MHz, 4 spatial streams
htRateBits = bitget(htDataRate,8:-1:1);
hexHTRates = [dec2hex(bi2deOptimized(htRateBits(1:4))) dec2hex(bi2deOptimized(htRateBits(5:8)))];
hexHTRates = [hexHTRates '00']; % Undefined bits

% Tx Supported MCS Set is defined and equal to Rx MCS set, maximum number
% of Tx Spatial Streams is four for HT PHY. Unequal modulation is not supported
maxTxSpatialStreams = 3; % 0x03 for 4 spatial streams
bitsTxRxMCS = [bitget(maxTxSpatialStreams,2:-1:1) 0 1];
hexTxRxMCS = ['0' dec2hex(bi2deOptimized(bitsTxRxMCS))];
% Form the Rx MCS set word
rxMCSSetParameters = [hexRxMCSBitmask hexHTRates hexTxRxMCS '000000']; % Form 0's for reserved bits

% HT Extended Capabilities are not supported
htExtendedCapabilities = '0000';

% Transmit beamforming capabilities are not supported
txBeamformingCapabilities = '00000000';

% Antenna Selection (ASEL) capabilities are not supported
aselCapabilities = '00';

informationElements{5} = [htCapabilitiesInfo ampduParameters rxMCSSetParameters ...
    htExtendedCapabilities txBeamformingCapabilities aselCapabilities];

% HT Operation Element
% This element controls the operation of HT BSS in the network.
% For more information, refer section 9.4.2.56 in IEEE Std 802.11-2020.
if band == 2.4 || band == 5
    elementIDs{6} = 61;
    primaryChannelHex = dec2hex(primaryChannel,2);
    % htInformationSubset1 - Secondary Channel Offset, Supported Channel Width, RIFS
    if cbw == 20 % Refer Table 11-23 in IEEE Std 802.11-2020
        htInformationSubset1 = '00'; % Supported Channel width bit = 0
    else % 40 MHz
        if rem(mpduFrameBody.PrimaryChannelIndex, 2) == 0 % Secondary is below primary channel
            % Secondary channel offset bits = 11 and Supported channel width bit = 1
            htInformationSubset1 = '07';
        else
            % Secondary channel offset bits = 01 and Supported channel width bit = 1
            htInformationSubset1 = '05';
        end
    end
    % htInformationSubset2 = '0400' (Non-Greenfield STAs present)
    % htInformationSubset3 = '0000'
    htInformation = [htInformationSubset1 '0400' '0000'];
    informationElements{6} = [primaryChannelHex htInformation rxMCSSetParameters];
end

% VHT Capabilities Element
% For more information, refer section 9.4.2.157 in IEEE Std 802.11-2020.
elementIDs{7} = 191;
% VHT Capabilities information
% Subset1: (0x04)
% 0x1 - Binary 0000 (No support for TxSTBC, short GI or Rx LDPC)
% 0x4 - Binary 0100 (160 MHz supported, Maximum MPDU Length is set in accordance with Maximum A-MSDU length in HT Capabilities)
% Refer Table 9-272 and Table 11-23 in IEEE Std 802.11-2020 for more
% information about Supported Channel Width Set
% Subset2: (0x00)
% 0x0 - Binary 0000 (No Support)
% 0x0 - Binary 0000 (No support)
% Subset3: (0x80)
% 0x8 - Binary 1000 (LSB bit of Max AMDPU Length Exponent, binary 111)
% 0x0 - Binary 0000 (No support)
% Maximum length supported for an AMDPU is 1048575 octets
% Maximum AMPDU Length Exponent is calculated as:
%   log2(1048575+1) - 13 = 7; (Binary - 0111)
% Subset4: (0x03)
% 0x0 - Binary 0000 (No support)
% 0x3 - Binary 0011 (Two MSB bits of Max AMDPU Length Exponent, binary 111)
vhtCapabilitiesInfo = ['04' '00' '80' '03'];

% VHT Supported MCS set
% Rx MCS Map
% Max MCS 9 is supported for 1-8 number of spatial streams.
% See Table 9-273 of IEEE Std 802.11-2020.
% Subset1: (0xaa)
% 0xa - Binary 1010 (Rx 4 SS and Rx 3 SS support MCS 0-9)
% 0xa - Binary 1010 (Rx 2 SS and Rx 1 SS support MCS 0-9)
% Subset2: (0xaa)
% 0xa - Binary 1010 (Rx 8 SS and Rx 7 SS support MCS 0-9)
% 0xa - Binary 1010 (Rx 6 SS and Rx 5 SS support MCS 0-9)
% Note that the VHT-MCSs as indicated above might not be valid at all
% bandwidths. Refer the NOTE following the description of Figure 9-611 in
% IEEE Std 802.11-2020.
rxVHTMCSMapSubset1 = 'aaaa';
% Rx Highest GI Data Rate
rxVHTdataRate = 6240; % Max VHT data rate is 6240 Mbps, for 160 MHz, 8 spatial streams, long GI
vhtRateBits = bitget(rxVHTdataRate,13:-1:1);
maxNSTSTotal = 0; % Reserved (No specific value available for reserved, so marking it 0)
maxNSTSTotalBits = [bitget(maxNSTSTotal,3:-1:1) vhtRateBits(1)];
rxVHTMCSMapSubset2 = [dec2hex(bi2deOptimized(vhtRateBits(6:9))) dec2hex(bi2deOptimized(vhtRateBits(10:13))) dec2hex(bi2deOptimized(maxNSTSTotalBits)) dec2hex(bi2deOptimized(vhtRateBits(2:5)))];
rxVHTMCSMap = [rxVHTMCSMapSubset1 rxVHTMCSMapSubset2];
% Tx MCS Map (same as Rx MCS Map)
% Tx Highest GI Data Rate (13 binary bits)
% Max VHT data rate is 6240 Mbps, for 160 MHz, 8 spatial streams
% Extended NSS BW capability is not present (Binary 0)
% Remaining 2 binary bits are reserved
% So, Tx and Rx MCS maps are equal
txVHTMCSMap = rxVHTMCSMap;

% Form VHT Capabilities Element
informationElements{7} = [vhtCapabilitiesInfo rxVHTMCSMap txVHTMCSMap];

% VHT Operation Element
% For more information, refer section 9.4.2.158 in IEEE Std 802.11-2020.
if band == 5 % VHT is supported only in 5 GHz band
    elementIDs{8} = 192;

    % VHT operation info
    % Channel width, CCFS0, CCFS1
    if cbw == 20 || cbw == 40
        channelWidth = 0; % 20 or 40 MHz
    else
        channelWidth = 1; % 80 or 160 MHz, 320 MHz not supported so set to maximum support for VHT
    end

    if any(cbw==[20 40 80])
        CCFS0 = channel; % Refer Section 11.38.1, Table 11-24, and Table 21-22 in IEEE Std 802.11-2020.
        CCFS1 = 0;
    else % 160 MHz only
        % Refer Table 11.24 in IEEE Std 802.11-2020
        CCFS1 = channel;
        if primaryChannel > channel
            CCFS0 = channel + 8;
        else
            CCFS0 = channel - 8;
        end
    end
    vhtOperationInfo = [dec2hex(channelWidth,2) dec2hex(CCFS0,2) dec2hex(CCFS1,2)];
    % Basic VHT MCS Map - same as VHT Rx MCS Set in VHT Capabilities
    vhtMCSSet = rxVHTMCSMapSubset1;
    informationElements{8} = [vhtOperationInfo vhtMCSSet];
end

% HE Capabilities Element
% For more information, refer section 9.4.2.248 in IEEE Std 802.11-2021.
elementIDs{9} = [255 35];

% HE MAC Capabilities
% +HTC HE Support, BSR support, Max AMPDU length exponent (3)
heMACCapabilities = ['01' '0c' '08' '18' '00' '00'];

% HE PHY Capabilities
% Supported Channel width set is encoded differently depending upon the
% operating band. Refer Table 9-322b in IEEE Std 802.11-2021
if band == 2.4
    channelWidthSet = '02'; % 40 MHz channel bandwidth supported
else % 5 or 6 GHz bands
    channelWidthSet = '0c'; % 40, 80, 160 MHz channel width supported
end

% LDPC coding supported, Rx Full BW SU using HEMU PPDU With compressed
% HE-SIG-B supported
hePHYCapabilities = [channelWidthSet '20' repmat('00',1,7), '1c' '00'];
% Supported HE-MCS and NSS Set, MCS 0-11 supported for 1-8
% spatial streams
heMCSMap = 'aaaa';
% In 2.4 GHz band, B2 bit of Supported Channel Width Set is reserved, so do
% not include Tx and Rx maps for 160 MHz. For 5 GHz and 6 GHz bands, B2 is
% present and marked as supported, so include Tx and Rx maps for both 80
% MHz and 160 MHz. Refer section 9.4.2.248.4 in IEEE Std 802.11-2021.
if band == 2.4
    % Fill both Tx and Rx maps, for 80 MHz
    heMCSNSSSet = repmat(heMCSMap,1,2);
else
    % Fill both Tx and Rx maps, for 80 MHz and 160 MHz
    heMCSNSSSet = repmat(heMCSMap,1,4);
end
informationElements{9} = [heMACCapabilities hePHYCapabilities heMCSNSSSet];

% HE Operation Element
% For more information, refer section 9.4.2.249 in IEEE Std 802.11-2021.
elementIDs{10} = [255 36];

% HE Operation Parameters
% 6 GHz operation information present
if band == 6
    heOperationParameters = '000002';
    sixGHzInfo = dec2hex(primaryChannel,2);
    switch cbw
        case 20
            channelWidth = 0;
        case 40
            channelWidth = 1;
        case 80
            channelWidth = 2;
        otherwise
            channelWidth = 3;
    end
    controlField = dec2hex(channelWidth,2);
    % Fill CCFS fields as per description followed after Figure 9-788k in
    % IEEE Std 802.11-2020.
    if cbw == 160 || cbw == 320
        if primaryChannel > channel
            ccfs0 = channel + 8;
        else
            ccfs0 = channel - 8;
        end
        ccfs0 = dec2hex(ccfs0,2);
        ccfs1 = dec2hex(channel,2);
    else % 20, 40, 80 MHz
        ccfs0 = dec2hex(channel,2);
        ccfs1 = '00';
    end
    minRate = dec2hex(floor(14.6250),2); % For MCS=0, NSS=1, 20 MHz
    sixGHzInfo = [sixGHzInfo controlField ccfs0 ccfs1 minRate];
else
    heOperationParameters = '000000';
end

% BSS Color Information - No partial BSS color
bssColorBits = bitget(min([mpduFrameBody.BSSColor, 63]),6:-1:1); % Maximum value is 63
bssColorInformation = [dec2hex(bi2deOptimized([0 0 bssColorBits(1:2)])) dec2hex(bi2deOptimized(bssColorBits(3:6)))];

% Basic HE MCS and NSS Set - same as Tx/Rx MCS NCS Set
informationElements{10} = [heOperationParameters bssColorInformation heMCSMap];

if band == 6
    informationElements{10} = [informationElements{10} sixGHzInfo];
end

% EHT Operation Element
% For more information, refer section 9.4.2.311 in IEEE P802.11be/D5.0
elementIDs{11} = [255 106];

% Maximum of 8 spatial streams are supported for each MCS in the range [0-13]
basicEHTMCSNSSSet = '88888888';
% EHT operation parameters
ehtOperationParameters = '00';
informationElements{11} = [ehtOperationParameters basicEHTMCSNSSSet];
% EHT operation information is present for 6 GHz band and 320 MHz configured
% bandwidth. Refer section 35.15.1 in IEEE P802.11be/D5.0.
if band == 6 && cbw == 320
    ehtOperationParameters = '01'; % EHT Operation info present
    channelWidth = '4'; % 320 MHz
    controlField = ['0' channelWidth];
    if primaryChannel > channel
        CCFS0 = channel + 16;
    else
        CCFS0 = channel - 16;
    end
    CCFS0 = dec2hex(CCFS0,2);
    CCFS1 = dec2hex(channel,2);
    ehtOperationInfo = [controlField CCFS0 CCFS1];
    informationElements{11} = [ehtOperationParameters basicEHTMCSNSSSet ehtOperationInfo];
end

% EHT capabilities element
% For more information, refer section 9.4.2.313 in IEEE P802.11be/D5.0
elementIDs{12} = [255 108];

% EHT MAC capabilities
% No support for EPCS Priority Access, OM Control, Triggered TxOP Sharing
% Max MPDU Length = 0 (Chosen default since A-MSDU aggregation is not supported)
subset1 = '00';
subset2 = '01'; % Maximum AMPDU Length Exponent Extension is set to 1
ehtMACCapabilities = [subset1 subset2];

% EHT PHY capabilities
% Only 320 MHz in 6 GHz band supported
ehtPHYCapabilities = ['1' repmat('0',1,17)];

% Supported EHT MCS NSS Set
% Three EHT MCS Maps to be filled for bandwidths <= 80 MHz, =160 MHz, =320 MHz
ehtMCSMap = '888888'; % 3 octets
ehtMCSNSSSet = repmat(ehtMCSMap,1,3);
informationElements{12} = [ehtMACCapabilities ehtPHYCapabilities ehtMCSNSSSet];

if mpduFrameBody.IsAffiliatedWithMLD
    % Basic Multi Link Element
    % For more information, refer section 9.4.2.312 in IEEE P802.11be/D5.0
    elementIDs{13} = [255 107];
    informationElements{13} = formBasicMultilinkOctets(mpduFrameBody);

    % Reduced Neighbor Report element
    if mpduFrameBody.NumLinks > 1
        elementIDs{14} = 201;
        informationElements{14} = formReducedNeighborReportOctets(mpduFrameBody);
    end
end

if mpduFrameBody.IsMeshBeacon
    % Mesh ID Element
    % For more information, refer section 9.4.2.98 in IEEE Std. 802.11-2020
    elementIDs{15} = 114;
    meshID = mpduFrameBody.MeshID;
    % Construct the information field for the Mesh ID IE
    decOctets = uint8(char(meshID));
    informationElements{15} = reshape(dec2hex(decOctets, 2)', 1, []);

    % Mesh Configuration Element
    % Active Path Selection Protocol Identifier - Reserved (0)
    % Active Path Selection Metric Identifier - Reserved (0)
    % Congestion Control Mode Identifier - Default (0, No active congestion control)
    % Synchronization Method Identifier - Reserved (0)
    % Authentication Protocol Identifier - No authentication method (0)
    % Mesh Formation Info - Mesh Gate (0), Number of peerings, Connected to AS (0)
    % Mesh Capability - Accepting Additional Mesh Peerings, Forwarding, are
    % supported capabilities
    % For more information, refer section 9.4.2.97 in IEEE Std. 802.11-2020
    elementIDs{16} = 113;
    numPeersBits = bitget(min([mpduFrameBody.NumMeshPeers, 63]),6:-1:1);
    meshFormationInfo = dec2hex(bi2deOptimized([0 numPeersBits 0]),2);
    meshCapability = '09';
    informationElements{16} = ['00' '00' '00' '00' '00' meshFormationInfo meshCapability];
end

% Remove all empty values
nonEmptyElementIndices = ~cellfun('isempty',elementIDs);
elementIDs = elementIDs(nonEmptyElementIndices);
% Remove all empty values except the first element (SSID), since Wildcard
% SSIDs, if present, are considered empty strings
informationElements = informationElements(nonEmptyElementIndices);
end

function dec = bi2deOptimized(bin)
    dec = comm.internal.utilities.bi2deLeftMSB(double(bin), 2);
end

function shortSSIDHex = calculateShortSSID(ssid)
%calculateShortSSID Returns the short SSID in hexadecimal octets

    persistent crcCfg
    if isempty(crcCfg)
       crcCfg = crcConfig(Polynomial=[32 26 23 22 16 12 11 10 8 7 5 4 2 1 0], InitialConditions=1, DirectMethod=true, FinalXOR=1);
    end

    % 1 octet = 8 bits
    octetLength = 8;

    % Convert octets to bits to add FCS
    frameBits = int2bit(ssid, octetLength, false);
    frameBitsColVector = reshape(frameBits, numel(frameBits), 1);

    % Calculate short SSID
    shortSSID = crcGenerate(double(frameBitsColVector), crcCfg); % Returns short SSID appended to SSID
    shortSSID = shortSSID(numel(ssid)*8+1:end)'; % Take only the bits corresponding to short SSID
    shortSSID = shortSSID(end:-1:1);
    shortSSIDHex = [dec2hex(bi2deOptimized(shortSSID(1:8)),2) dec2hex(bi2deOptimized(shortSSID(9:16)),2) ...
        dec2hex(bi2deOptimized(shortSSID(17:24)),2) dec2hex(bi2deOptimized(shortSSID(25:32)),2)];
end

function edcaParameterSetElement = formEDCAParameterSetOctets(mpduFrameBody)
%edcaParameterSetElement Return the hexadecimal octets for EDCA Parameter Set element

    % QoSInfo - '00'
    % Update EDCA Info - '00'. It is reserved for non-S1G STAs.
    % AC_BE Parameter Record - 4 octets
    % AC_BK Parameter Record - 4 octets
    % AC_VI Parameter Record - 4 octets
    % AC_VO Parameter Record - 4 octets
    % For more information, refer section 9.4.2.28 in IEEE Std 802.11-2020.

    updateCount = rem(mpduFrameBody.EDCAParamsCount(mpduFrameBody.LinkID), 16); % Maximum allowed value is 15 (since 4 bits are available)
    EDCAUpdateCount = bitget(updateCount, 4:-1:1);
    QoSInfo = [0 0 0 0 EDCAUpdateCount];
    hexQoSInfo = dec2hex(bi2deOptimized(QoSInfo),2);
    edcaParameterSetElement = [hexQoSInfo '00']; % Initialize to hold QoSInfo, Update EDCA Info
    AIFSN = mpduFrameBody.AIFS(1:4);
    ECWMin = log2(mpduFrameBody.CWMin(1:4) + 1);
    ECWMax = log2(mpduFrameBody.CWMax(1:4) + 1);
    parameterRecordsPerAC = {zeros(0,1)};
    for idx = 1:4
        bitsAIFSN = bitget(AIFSN(idx), 4:-1:1);
        bitsACI = bitget(idx-1,2:-1:1);
        bitsACI_AIFSN = [0 bitsACI 0 bitsAIFSN]; % Reserved, ACI, ACM, AIFSN bits
        hexACI_AIFSN = [dec2hex(bi2deOptimized(bitsACI_AIFSN(1:4))) dec2hex(bi2deOptimized(bitsACI_AIFSN(5:8)))];
        bitsECWMax = bitget(ECWMax(idx),4:-1:1);
        bitsECWMin = bitget(ECWMin(idx),4:-1:1);
        hexECW = [dec2hex(bi2deOptimized(bitsECWMax)) dec2hex(bi2deOptimized(bitsECWMin))];
        bitsTXOPLimit = bitget(mpduFrameBody.TXOPLimit(idx),16:-1:1);
        hexTXOPLimit = [dec2hex(bi2deOptimized(bitsTXOPLimit(1:4))) dec2hex(bi2deOptimized(bitsTXOPLimit(5:8))) dec2hex(bi2deOptimized(bitsTXOPLimit(9:12))) dec2hex(bi2deOptimized(bitsTXOPLimit(13:16)))];
        parameterRecordsPerAC{idx} = [hexACI_AIFSN hexECW hexTXOPLimit(3:4) hexTXOPLimit(1:2)];
        edcaParameterSetElement = [edcaParameterSetElement parameterRecordsPerAC{idx}]; %#ok<AGROW>
    end
end

function rnrElement = formReducedNeighborReportOctets(mpduFrameBody)
%formReducedNeighborReportOctets Return the hexadecimal octets for Reduced Neighbor Report element

    rnrElement = [];
    % TBTT Information Header and Operating class have same values for all the
    % links
    % TBTT Information Header - TBTT Information field type (00), Filtered
    % Neighbor AP (0) + Reserved (0) + TBTT Information Count (0000), TBTT
    % Information Length (16 - 00010000)
    % Reference: Section 9.4.2.169.2 of IEEE Draft P802.11be/D5.0
    tbttInfoHeaderBits = [zeros(1, 12) 1 zeros(1, 3)];
    tbttInfoHeaderBits = tbttInfoHeaderBits(end:-1:1); % Left MSB
    tbttInfoHeader = [dec2hex(bi2deOptimized(tbttInfoHeaderBits(9:16)), 2) ...
        dec2hex(bi2deOptimized(tbttInfoHeaderBits(1:8)), 2)];
    % Operating class - not supported currently
    operatingClass = '00';
    
    linkID = mpduFrameBody.LinkID;

    for linkIdx = 1:mpduFrameBody.NumLinks
        if linkIdx ~= linkID % Other AP affiliated with AP MLD 
            rnrIdx = (linkIdx == [mpduFrameBody.RNRNeighborAPInfo(:).LinkID]);
            rnrLinkInfo = mpduFrameBody.RNRNeighborAPInfo(rnrIdx);

            % Channel number
            primaryChannel = mpduFrameBody.PrimaryChannel(linkIdx);
            primaryChannel = dec2hex(primaryChannel,2);

            % TBTT Info field - Neighbor AP TBTT Offset
            tbttOffset = rnrLinkInfo.TBTTOffset;

            % Fill an invalid value (255) when offset goes beyond 254. This
            % may happen if beacon transmission is disabled on any link
            if tbttOffset > 254 && rnrLinkInfo.NextTBTT == 0
                tbttOffset = 255;
            end
            tbttOffset = dec2hex(tbttOffset, 2);

            % TBTT Info field - BSSID
            bssID = rnrLinkInfo.BSSIDList;

            % TBTT Info field - Short SSID
            decOctets = uint8(char(mpduFrameBody.SSID));
            shortSSID = calculateShortSSID(decOctets);

            % TBTT Info field - BSS parameters - OCT recommended (0), same SSID (1),
            % multiple BSSID (0), transmitted BSSID (reserved), member of ESS With
            % 2.4/5 GHz Co-Located AP (0), unsolicited probe responses (0), co-Located
            % AP (0), reserved (0)
            bssParametersBits = [0 1 0 0 0 0 0 0];
            bssParameters = dec2hex(bi2deOptimized(bssParametersBits(end:-1:1)), 2);

            % TBTT Info field - 20 MHz PSD
            % Reference: Section 9.4.2.170.2 of IEEE Std 802.11ax-2021
            psd = dec2hex(127, 2);

            % TBTT Info field - MLD parameters
            % Reference: Section 9.4.2.169.2 of IEEE Draft P802.11be/D5.0
            apMLDIDBits = zeros(1, 8);
            linkIDBits = bitget(linkIdx,1:4);
            changeCount = rem(rnrLinkInfo.EDCAParamsCount, 255); % Maximum allowed value is 254
            changeCountBits = bitget(changeCount, 1:8);
            mldParametersBits = [apMLDIDBits linkIDBits changeCountBits zeros(1, 4)];
            mldParametersBits = mldParametersBits(end:-1:1);
            mldParameters = [dec2hex(bi2deOptimized(mldParametersBits(17:24)), 2) ...
                dec2hex(bi2deOptimized(mldParametersBits(9:16)), 2) dec2hex(bi2deOptimized(mldParametersBits(1:8)), 2)];

            rnrElement = [rnrElement tbttInfoHeader operatingClass primaryChannel tbttOffset ...
                bssID shortSSID bssParameters psd mldParameters]; %#ok<AGROW>
        end
    end
end

function basicMultiLinkElement = formBasicMultilinkOctets(mpduFrameBody)
%formBasicMultilinkOctets Return the hexadecimal octets for Basic Multi link element

    linkID = mpduFrameBody.LinkID;
    % Multi link control
    % Type - Basic
    % Presence Bitmap - Link ID Info, BSS Parameters Change Count,
    % EML Capabilities, MLD Capabilities and Operations
    % Bits - 000 0 110110000000
    % 0000 1101 1000 0000 - half bytes
    % 0000 0001 1011 0000 - half bytes flipped
    % 0    1    b    0
    multiLinkControl = ['b0' '01'];

    % Common info - Length, MLD MAC Address, Link ID Info, BSS Parameters
    % Change Count, EML Capabilities, MLD Capabilities and Operations
    mldMACAddress = mpduFrameBody.MLDMACAddress;
    linkIDBits = bitget(linkID,4:-1:1);
    linkIDInfo = dec2hex(bi2deOptimized([0 0 0 0 linkIDBits]), 2);
    updateCount = rem(mpduFrameBody.EDCAParamsCount(linkID), 255); % Maximum allowed value is 254
    bssParametersChange = dec2hex(updateCount, 2);
    % EML Capabilities - No EMLSR support
    % EMLSR Support(0), EMLSR Padding Delay(000), EMLSR Transition Delay(000)
    % EMLMR Support(0), EMLMR Delay(000), Transition Timeout(0000), Reserved(0)
    % Bits - 0 000 000 0 000 0000 0
    emlCapabilities = '0000'; 
    % MLD capabilities - Max Links
    % SRS, TID-To-Link Mapping Negotiation, Frequency separation For STR/
    % NSTR Mobile AP MLD, AAR are not supported.
    maxSimulataneousLinks = mpduFrameBody.NumLinks - 1;
    maxLinks = bitget(maxSimulataneousLinks,4:-1:1);
    mldCapabilitiesBits = [zeros(1, 12) maxLinks];
    mldCapabilities = [dec2hex(bi2deOptimized(mldCapabilitiesBits(9:16)), 2) dec2hex(bi2deOptimized(mldCapabilitiesBits(1:8)), 2)];
    commonInfoField = [mldMACAddress linkIDInfo bssParametersChange emlCapabilities mldCapabilities];
    commonInfoLength = numel(commonInfoField)/2 + 1; % Add 1 octet for common info length subfield
    commonInfoLength = dec2hex(commonInfoLength, 2);
    commonInfoField = [commonInfoLength commonInfoField];

    % Form Multi link information element
    basicMultiLinkElement = [multiLinkControl commonInfoField];
end

function updatedInformationElement = generateInformationElement(elementID, mpduFrameBody)
%generateInformationElement Generate the information element in hexadecimal
%octets corresponding to the specified element ID

    if elementID == 12 % EDCA Parameter Set
        updatedInformationElement = formEDCAParameterSetOctets(mpduFrameBody);
    elseif elementID == 201 % Reduced Neighbor Report element
        updatedInformationElement = formReducedNeighborReportOctets(mpduFrameBody);
    elseif all(elementID == [255 107]) % Basic Multilink element
        updatedInformationElement = formBasicMultilinkOctets(mpduFrameBody);
    end
end
