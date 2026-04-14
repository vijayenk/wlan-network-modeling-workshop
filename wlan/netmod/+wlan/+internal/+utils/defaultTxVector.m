function vector = defaultTxVector(perUserInfo)
%defaultTxVector returns a default TX/RX vector structure.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   VECTOR = defaultTxVector() returns a structure VECTOR with the fields
%
%   PPDUFormat              - The physical layer (PHY) frame format,
%                             specified as a constant value defined in the
%                             class wlan.internal.FrameFormats. Specify
%                             this value as one of these constants from
%                             wlan.internal.FrameFormats: NonHT, HTMixed, VHT,
%                             HE_SU, HE_EXT_SU, or HE_MU.
%   ChannelBandwidth        - Bandwidth of the channel
%   Channelization320MHz    - The channelization for 320 MHz channel bandwidth
%   SignalChannelBandwidth  - Logical flag that signals channel bandwidth
%                             in the scrambler sequence
%   BandwidthOperation      - Signal bandwidth operation in the scrambler
%                             sequence, must be 'Dynamic', 'Static' or
%                             'Absent'.
%   ScramblerInitialValue   - The value of Scrambler Initialization field
%                             in the SERVICE field, after scrambling.
%   AggregatedMPDU          - Logical flag that represents whether the MPDU
%                             is aggregatd
%   BSSColor                - Basic service set color (Used to
%                             differentiate signals as Intra-BSS/Intra-BSS)
%   UplinkIndication        - Uplink flag specifying whether the frame is
%                             transmitted in uplink
%   TXOPDuration            - Transmit Opportunity (TXOP) duration, as
%                             required by TXOP subfield of the HE-SIG-A/EHT-USIG
%                             field
%   RUAllocation            - Represents allocation index in HE_MU Tx
%                             vector and represents array of RU size and
%                             index in HE_MU Rx vector and HE_TB Tx vector.
%   PerUserInfo             - Structure containing per-user transmission
%                             parameters. See
%                             <a href="matlab:help('wlan.internal.utils.defaultPerUserFields')">wlan.internal.utils.defaultPerUserFields</a> for
%                             fields.
%   NumTransmitChains       - Number of transmit antennas
%   LowerCenter26ToneRU
%   UpperCenter26ToneRU
%   TriggerMethod           - Specifies the method used to trigger HE TB
%                             PPDU transmission, must be 'TriggerFrame' or
%                             'TRS'
%   LSIGLength              - Represents length of the LSIG field when
%                             'TriggerMethod' is 'TriggerFrame' and UL data
%                             symbols when 'TriggerMethod' is 'TRS'
%   NumHELTFSymbols         - Specifies the number of OFDM symbols in the
%                             HE-LTF field
%   RSSI                    - Receive signal strength
%   NonHTChannelBandwidth   - Interpreted channel bandwidth for Non-HT DUP
%
%   VECTOR = defaultTxVector(PERUSERINFO) uses the structure array
%   PERUSERINFO to populate the structure.

%   Copyright 2022-2025 The MathWorks, Inc.

arguments
    perUserInfo = wlan.internal.utils.defaultPerUserFields;
end
vector = struct( ...
            ... % Fields common in Tx and Rx vectors
            'PPDUFormat', wlan.internal.FrameFormats.NonHT, ... 
            'ChannelBandwidth', 20, ...
            'Channelization320MHz', 1, ... % Applicable only if ChannelBandwidth is 320 MHz. Acceptable values are 1 (320MHz-1) and 2 (320MHz-2)
            'BandwidthOperation', 'Absent', ...
            'ScramblerInitialValue', -1, ... % For CTS response to an MU-RTS frame, see Section 26.2.6.3 of IEEE Std 802.11ax-2021
            'AggregatedMPDU', false, ...
            'BSSColor', 0, ...
            'UplinkIndication', false, ... % Applicable only if PPDUFormat is HE_SU, HE_MU, HE_EXT_SU, EHT_SU, EHT_MU
            'TXOPDuration', 127, ...
            'RUAllocation', 0, ... % Represents allocation index in HE_MU Tx vector and represents array of RU size and index in HE_MU Rx vector and HE_TB Tx vector
            'PerUserInfo', perUserInfo, ... % This will be dynamic array of structures based on number of users
            ... % Fields in Tx vector
            'SignalChannelBandwidth', false, ... % For Non-HT DUP BW signaling, see Section 17.2.2 and 17.2.3 of IEEE Std 802.11-2020
            'NumTransmitChains', 1, ...
            'LowerCenter26ToneRU', false, ...
            'UpperCenter26ToneRU', false, ...
            ... % Fields in Tx vector for HE TB
            'TriggerMethod', 'TriggerFrame', ...
            'LSIGLength', 0, ... % Represents length of the LSIG field when 'TriggerMethod' is 'TriggerFrame' and UL data symbols when 'TriggerMethod' is 'TRS'
            'NumHELTFSymbols', 1, ...
            ... % Fields in Rx vector
            'RSSI', 0, ...
            'NonHTChannelBandwidth', 0); % Interpreted channel bandwidth for Non-HT DUP
end
