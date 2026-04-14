classdef wlanMACDecodeStatus < int16
%wlanMACDecodeStatus is an enumeration to indicate the status of the WLAN 
%MAC frame decoding
%   STATUS = wlanMACDecodeStatus.<ENUMVALUE> creates an enumeration with
%   the value specified by the ENUMVALUE. Valid values for ENUMVALUE are
%   described below.
%
%   wlanMACDecodeStatus properties (enum values):
%   ---------------------------------------------
%   Success (0)                     - MAC frame is decoded successfully
%   FCSFailed (-1)                  - FCS check failed
%   InvalidProtocolVersion (-2)     - Invalid protocol version
%   UnsupportedFrameType (-3)       - Unsupported frame type
%   UnsupportedFrameSubType (-4)    - Unsupported frame subtype
%   NotEnoughData (-5)              - Insufficient data to decode the frame
%   UnsupportedBAVariant (-6)       - Unsupported variant of Block Ack frame
%   UnknownBitmapSize (-7)          - Unknown bitmap size
%   UnknownAddressExtMode (-8)      - Unknown address extension mode
%   MalformedAMSDULength (-9)       - Malformed A-MSDU with invalid length
%   MalformedSSID (-10)             - Malformed SSID IE
%   MalformedSupportedRatesIE (-11) - Malformed Supported Rates IE
%   MalformedIELength (-12)         - Malformed IE length field
%   MissingMandatoryIEs (-13)       - Mandatory IEs are missing
%   NoMPDUFound (-14)               - No MPDU is found in the A-MPDU
%   CorruptedAMPDU (-15)            - All the delimiters in the given AMPDU
%                                     failed CRC check
%   InvalidDelimiterLength (-16)    - Invalid length in the MPDU delimiter
%   MaxAMSDULengthExceeded (-17)    - A-MSDU exceeded maximum length limit
%   MaxMPDULengthExceeded (-18)     - MPDU exceeds maximum length limit
%   MaxMMPDULengthExceeded (-19)    - Management frame exceeds maximum 
%                                     length limit
%   MaxMSDULengthExceeded (-20)     - MSDU exceeds the maximum length limit
%   UnexpectedProtectedFrame (-21)  - Frame is protected, which is
%                                     unexpected for this frame type
%   UnsupportedTriggerType (-22)    - Unsupported trigger type
%   UnknownHELTFTypeAndGI (-23)     - Unknown value in the GI and LTF type
%                                     field
%   UnknownAPTxPower (-24)          - Unknown access point transmit power 
%                                     value
%   UnknownAID12Value (-25)         - Unknown AID12 value in user info
%                                     field
%   UnknownRUAllocation (-26)       - Unknown resource unit allocation 
%                                     value in user info field
%   UnknownULMCS (-27)              - Unknown uplink modulation and coding 
%                                     scheme value in user info field
%   UnknownTargetRSSI (-28)         - Unknown uplink target RSSI value
%   UnsupportedBARType (-29)        - Unsupported block ack request type in 
%                                     user info field
%   MissingUserInfo (-30)           - User info field is missing
%   InvalidLSIGLength (-31)         - L-SIG length value is invalid

%   Copyright 2018-2024 The MathWorks, Inc.

  enumeration
    %Success MPDU is decoded successfully
    %   Success is mapped to the value 0. If the input MAC frame is an
    %   MPDU, this value indicates that all the fields in the MPDU are
    %   decoded successfully. If the input MAC frame is an A-MPDU, this
    %   values indicates that at least one MPDU is extracted successfully.
    Success (0)
    
    %FCSFailed FCS check failed
    %   FCSFailed is mapped to the value -1. This value indicates that FCS
    %   check failed for the MPDU.
    FCSFailed (-1)
    
    %InvalidProtocolVersion Invalid protocol version
    %   InvalidProtocolVersion is mapped to the value -2. This value
    %   indicates that the MPDU contains a reserved value for protocol
    %   version. Only value 0 is supported for protocol version.
    InvalidProtocolVersion (-2)
    
    %UnsupportedFrameType Unsupported frame type
    %   UnsupportedFrameType is mapped to -3. This value indicates that the
    %   received frame type is not supported.
    UnsupportedFrameType (-3)
    
    %UnsupportedFrameSubtype Unsupported frame subtype
    %   UnsupportedFrameSubtype is mapped to -4. This value indicates that
    %   the subtype of the received frame is not supported.
    UnsupportedFrameSubtype (-4)
    
    %NotEnoughData Input data is insufficient to decode the frame
    %   NotEnoughData is mapped to -5. This value indicates that the
    %   received frame does not contain enough data to decode the frame.
    NotEnoughData (-5)
    
    %UnsupportedBAVariant Unsupported variant of Block Ack frame
    %   UnsupportedBAVariant is mapped to -6. This value indicates that the
    %   received frame is an unsupported variant of Block Ack frame.
    UnsupportedBAVariant (-6)
    
    %UnknownBitmapSize Unknown bitmap size
    %   UnknownBitmapSize is mapped to -7. This value indicates that the
    %   received Block Ack frame contains a reserved value in the fragment
    %   number field. The fragment number indicates the bitmap size.
    UnknownBitmapSize (-7)
    
    %UnknownAddressExtMode Unknown address extension mode
    %   UnknownAddressExtMode is mapped to -8. This value indicates that
    %   the received frame contains a reserved value (3) for the address
    %   extension mode in the mesh control field. Only values 0, 1, 2 are
    %   supported by the IEEE 802.11 standard.
    UnknownAddressExtMode (-8)
    
    %MalformedAMSDULength Malformed A-MSDU frame
    %   MalformedAMSDULength is mapped to -9. This value indicates that the
    %   A-MSDU length field in the received data frame indicates more than
    %   the remaining available data.
    MalformedAMSDULength (-9)
    
    %MalformedSSID Malformed SSID IE
    %   MalformedSSID is mapped to -10. This value indicates that the
    %   received management frame contains malformed SSID with length
    %   greater than 32 octets.
    MalformedSSID (-10)
    
    %MalformedSupportedRatesIE Malformed Supported Rates IE
    %   MalformedSupportedRatesIE is mapped to -11. This value indicates
    %   that the received management frame contains malformed supported
    %   rates IE with invalid number of rates.
    MalformedSupportedRatesIE (-11)
    
    %MalformedIELength Malformed IE length field
    %   MalformedIELength is mapped to -12. This value indicates that the
    %   received management frame contains malformed IE with invalid length
    %   field.
    MalformedIELength (-12)
    
    %MissingMandatoryIEs Mandatory IEs are missing
    %   MissingMandatoryIEs is mapped to -13. This value indicates that the
    %   mandatory IEs SSID and/or Supported Rates are missing in the
    %   received beacon frame.
    MissingMandatoryIEs (-13)
        
    %NoMPDUFound No MPDU is found in the A-MPDU
    %   NoMPDUFound is mapped to -14. This value indicates that no MPDU
    %   delimiter is found in the given A-MPDU. So, the decoder is not able
    %   to extract any MPDUs.
    NoMPDUFound (-14)
    
    %CorruptedAMPDU All the delimiter CRCs in the given A-MPDU failed
    %   CorruptedAMPDU is mapped to -15. This value indicates that all the
    %   delimiters found in the A-MPDU failed CRC check.
    CorruptedAMPDU (-15)
    
    %InvalidDelimiterLength Invalid length in the MPDU delimiter
    %   InvalidDelimiterLength is mapped to -16. This value indicates that
    %   the length field in the last MPDU delimiter found is invalid and
    %   there is not enough data to parse further. The last MPDU in the
    %   output MPDULIST contains trailing data and may not be valid.
    InvalidDelimiterLength (-16)
    
    %MaxAMSDULengthExceeded A-MSDU exceeds maximum length limit
    %   MaxAMSDULengthExceeded is mapped to -17. This value indicates that
    %   the received data frame contains an A-MSDU and the length of the
    %   A-MSDU exceeds the maximum length limit for the specified PHY
    %   format.
    MaxAMSDULengthExceeded (-17)
    
    %MaxMPDULengthExceeded MPDU exceeds maximum length limit
    %   MaxMPDULengthExceeded is mapped to -18. This value indicates that
    %   the received frame exceeds the maximum MPDU length limit of 11454
    %   octets for either VHT or HE format.
    MaxMPDULengthExceeded (-18)
    
    %MaxMMPDULengthExceeded Management frame exceeds maximum length limit
    %   MaxMMPDULengthExceeded is mapped to -19. This value indicates that
    %   the received management frame exceeds the maximum length limit of
    %   2304 octets for either Non-HT or HT format.
    MaxMMPDULengthExceeded (-19)
    
    %MaxMSDULengthExceeded MSDU exceeds the maximum length limit
    %   MaxMSDULengthExceeded is mapped to -20. This value indicates that
    %   an MSDU present in the received data frame exceeds the maximum
    %   length limit of 2304 octets.
    MaxMSDULengthExceeded (-20)
    
    %UnexpectedProtectedFrame Frame is protected, which is unexpected for
    %this frame type
    %   UnexpectedProtectedFrame is mapped to -21. This value indicates
    %   that a frame was received with 'Protected' bit set to 1 in the
    %   frame control field. According to sections 12.2.7 and 12.2.7 in the
    %   IEEE Std 802.11-2016, only data frames, authentication frames, and
    %   robust management frames are supposed to be protected.
    UnexpectedProtectedFrame (-21)

    %UnsupportedTriggerType Unsupported trigger type
    %   UnsupportedTriggerType is mapped to -22. This value indicates that
    %   the received trigger frame is an unsupported trigger type.
    UnsupportedTriggerType (-22)

    %UnknownHELTFTypeAndGI Unknown value in the GI and LTF type field
    %   UnknownHELTFTypeAndGI is mapped to -23. This value indicates that
    %   the received trigger frame contains an unknown value in the GI and
    %   LTF type field.
    UnknownHELTFTypeAndGI (-23)

    %UnknownAPTxPower Unknown AP Tx power value
    %   UnknownAPTxPower is mapped to -24. This value indicates that the
    %   received trigger frame contains an unknown value in the AP Tx power
    %   field.
    UnknownAPTxPower (-24)

    %UnknownAID12Value  Unknown AID12 value in user info field
    %   UnknownAID12Value is mapped to -25. This value indicates that the
    %   received trigger frame contains a user info field with unknown
    %   AID12 value. Refer section 9.3.1.22.1 of IEEE Std 802.11ax-2021.
    UnknownAID12Value (-25)

    %UnknownRUAllocation Unknown RU allocation value in user info field
    %   UnknownRUAllocation is mapped to -26. This value indicates that the
    %   received trigger frame contains a user info field with an unknown
    %   value for (B7-B1) RU allocation value mentioned in table 9-29i of
    %   IEEE Std 802.11ax-2021.
    UnknownRUAllocation (-26)

    %UnknownULMCS Unknown UL MCS value in user info field
    %   UnknownULMCS is mapped to -27. This value indicates that the
    %   received trigger frame contains a user info field with an unknown
    %   UL MCS value.
    UnknownULMCS (-27)

    %UnknownTargetRSSI Unknown UL target RSSI value
    %   UnknownTargetRSSI is mapped to -28. This value indicates that the
    %   received trigger frame contains an unknown value in the UL target
    %   RSSI field.
    UnknownTargetRSSI (-28)

    %UnsupportedBARType Unsupported BAR type in user info
    %   UnsupportedBARType is mapped to -29. This value indicates that the
    %   received trigger frame contains a user info field with an
    %   unsupported BAR type value.
    UnsupportedBARType (-29)

    %MissingUserInfo User info field is missing
    %   MissingUserInfo is mapped to -30. This value indicates that the
    %   received trigger frame does not contain any valid user info field.
    MissingUserInfo (-30)

    %InvalidLSIGLength L-SIG length value is invalid
    %   InvalidLSIGLength is mapped to -31. This value indicates that the
    %   received trigger frame contains invalid value in the UL length
    %   field (L-SIG length). The value of mod(LSIGLength, 3) must be 1 for
    %   a valid LSIG length field.
    InvalidLSIGLength (-31)
  end
end


