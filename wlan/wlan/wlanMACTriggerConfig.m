classdef wlanMACTriggerConfig < comm.internal.ConfigBase
%wlanMACTriggerConfig Create a MAC trigger frame-body configuration object
%
%   CONFIG = wlanMACTriggerConfig creates a WLAN MAC trigger frame-body
%   configuration object.
%
%   CONFIG = wlanMACTriggerConfig(Name=Value) creates a WLAN MAC trigger
%   frame-body configuration object, CONFIG, with the specified property
%   Name set to the specified Value. You can specify additional name-value
%   arguments in any order as (Name1=Value1, ..., NameN=ValueN).
%
%   wlanMACTriggerConfig methods:
%   addUserInfo       - Add User Info field to MAC trigger frame
%
%   wlanMACTriggerConfig properties:
%   TriggerType               - Type of trigger frame
%   LSIGLength                - Value of L-SIG length field in HE TB PPDU
%                               response
%   MoreTF                    - Subsequent trigger frame indication
%   CSRequired                - Indicate carrier sensing required
%   ChannelBandwidth          - Uplink channel bandwidth
%   HELTFTypeAndGuardInterval - HE-LTF compression mode and guard-interval
%                               for HE TB PPDU response
%   SingleStreamPilots        - Indicate HE-LTF single-stream pilots in
%                               HE TB PPDU response
%   NumHELTFSymbols           - Number of HE-LTF symbols present in HE TB
%                               PPDU response
%   MidamblePeriodicity       - Midamble periodicity of HE TB PPDU response                               
%   STBC                      - Enable space-time block coding in HE TB
%                               PPDU response
%   LDPCExtraSymbol           - Indicate low density parity check (LDPC)
%                               extra OFDM symbol in HE TB PPDU response
%   APTransmitPower           - Combined average power per 20 MHz bandwidth
%   PreFECPaddingFactor       - Pre-FEC padding factor in HE TB PPDU
%                               response
%   PEDisambiguity            - PE Disambiguity for HE TB PPDU response
%   SpatialReuse1             - Spatial reuse-1 indication for HE TB PPDU
%                               response
%   SpatialReuse2             - Spatial reuse-2 indication for HE TB PPDU
%                               response
%   SpatialReuse3             - Spatial reuse-3 indication for HE TB PPDU
%                               response
%   SpatialReuse4             - Spatial reuse-4 indication for HE TB PPDU
%                               response
%   HighDoppler               - Indicate the presence of a midamble in the
%                               HE TB PPDU response
%   HESIGAReservedBits        - Reserved bits in HE-SIG-A field of HE TB
%                               PPDU response
%   UserInfo                  - User Info fields of trigger frame
%   NumUserInfo               - Number of User Info fields in UserInfo
%                               property

%   Copyright 2020-2025 The MathWorks, Inc.

%#codegen

properties
    %TriggerType Type of trigger frame
    %   Specify the trigger type as one of 'Basic' | 'MU-RTS' | 'MU-BAR'.
    %   The default value is 'Basic'. Refer to section 9.3.1.22.1 of IEEE
    %   Std 802.11ax-2021.
    TriggerType = 'Basic';

    %LSIGLength Value of L-SIG length field
    %   Specify the value of L-SIG LENGTH field in the HE TB PPDU response
    %   as an integer in the range [1, 4093]. This property is not
    %   applicable when you set the TriggerType property to 'MU-RTS'. The
    %   property value must satisfy the condition mod(LSIGLength,3) = 1.
    %   The default value is 142.
    LSIGLength (1, 1) {wlan.internal.mustBeValidLSIGLength(LSIGLength,'HE TB')} = 142;

    %MoreTF Subsequent trigger frame indication
    %   Set this property to true to indicate that the sender has more
    %   trigger frames to send. The default value is false.
    MoreTF (1, 1) logical = false;

    %CSRequired Carrier sensing required
    %   Set this property to true to indicate that the stations identified
    %   in the User Info fields are required to use energy detection (ED)
    %   to sense the medium. It also indicates that the stations are
    %   required to consider the medium state and the network allocation
    %   vector (NAV) in determining whether to respond. The default value
    %   is true.
    CSRequired (1, 1) logical = true;

    %ChannelBandwidth Uplink channel bandwidth
    %   Specify the bandwidth as one of 'CBW20' | 'CBW40' | 'CBW80' |
    %   'CBW80+80 or CBW160'. This property indicates the bandwidth in
    %   HE-SIG-A of the HE TB PPDU response. The default value is 'CBW20'.
    ChannelBandwidth = 'CBW20';

    %HELTFTypeAndGuardInterval HE-LTF compression mode and guard-interval
    %   Specify HE-LTF compression mode and guard interval in microseconds
    %   as one of '1x HE-LTF + 1.6 us GI' | '2x HE-LTF + 1.6 us GI' | '4x
    %   HE-LTF + 3.2 us GI'. This property indicates the guard interval
    %   (GI) and HE-LTF type of the HE TB PPDU response. This property is
    %   not applicable when you set the TriggerType property to 'MU-RTS'.
    %   The default value is '4x HE-LTF + 3.2 us GI'.
    HELTFTypeAndGuardInterval = '4x HE-LTF + 3.2 us GI';

    %SingleStreamPilots Indicate HE-LTF single-stream pilots
    %   Set this property to true to indicate that the HE-LTF uses
    %   single-stream pilots in the HE TB PPDU response. This property is
    %   not applicable when you set the TriggerType property to 'MU-RTS'.
    %   The default value of this property is true.
    SingleStreamPilots (1, 1) logical = true;

    %NumHELTFSymbols Number of LTF Symbols present
    %   Specify the number of LTF Symbols in the HE TB PPDU response as one
    %   of 1, 2, 4, 6, 8. This property is not applicable when you set the
    %   TriggerType property to 'MU-RTS'. When you set the HighDoppler
    %   property to true, this property value must be 1, 2, or 4. The
    %   default value is 1.
    NumHELTFSymbols (1, 1) {mustBeNumeric, mustBeMember(NumHELTFSymbols, [1 2 4 6 8])} = 1;

    %MidamblePeriodicity Midamble periodicity in number of OFDM symbols
    %   Specify HE-Data field midamble periodicity of the HE TB PPDU
    %   response as 10 or 20 OFDM symbols. This property applies only when
    %   you set the HighDoppler property to true and the TriggerType
    %   property is not 'MU-RTS'. The default is 10.
    MidamblePeriodicity (1, 1) {mustBeNumeric, mustBeMember(MidamblePeriodicity,[10 20])} = 10;

    %STBC Space-time block coding
    %   Set this property to true to indicate space-time block coding in
    %   the HE TB PPDU response. This property is not applicable when you
    %   set the TriggerType property to 'MU-RTS'. The default value is
    %   false.
    STBC (1, 1) logical = false;

    %LDPCExtraSymbol LDPC extra symbol segment
    %   Set this property to true to indicate the presence of an LDPC extra
    %   symbol segment in the HE TB PPDU response. This property is not
    %   applicable when you set the TriggerType property to 'MU-RTS'. The
    %   default value is false.
    LDPCExtraSymbol (1, 1) logical = false;

    %APTransmitPower Combined average power per 20 MHz bandwidth
    %   Specify AP transmit power in dBm as an integer in the range [-20,
    %   40]. This property indicates the combined average power per 20 MHz
    %   bandwidth of all antennas used to transmit the trigger frame. Refer
    %   to section 9.3.1.22.1 of IEEE Std 802.11ax-2021. This property is
    %   not applicable when you set the TriggerType property to 'MU-RTS'.
    %   The default value is -20.
    APTransmitPower (1, 1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(APTransmitPower, -20), mustBeLessThanOrEqual(APTransmitPower, 40)} = -20;

    %PreFECPaddingFactor Pre-FEC padding factor
    %   Specify pre-FEC padding factor of the HE TB PPDU response as an
    %   integer in the range [1, 4]. This property is not applicable when
    %   you set the TriggerType property to 'MU-RTS'. The default value is
    %   4.
    PreFECPaddingFactor (1, 1) {mustBeNumeric, mustBeInteger, mustBePositive, mustBeLessThanOrEqual(PreFECPaddingFactor, 4)} = 4;

    %PEDisambiguity PE Disambiguity for an HE TB PPDU
    %   Set this property to true to indicate the PE Disambiguity for the
    %   HE TB PPDU response. Refer to table 9-29g of IEEE Std
    %   802.11ax-2021. This property is not applicable when you set the
    %   TriggerType property to 'MU-RTS'. The default value of this
    %   property is false.
    PEDisambiguity (1, 1) logical = false;

    %SpatialReuse1 Spatial reuse-1 indication
    %   Specify spatial reuse-1 as an integer between 0 and 15, inclusive.
    %   This property indicates the value to be included in the
    %   corresponding spatial reuse field in the HE-SIG-A field of the HE
    %   TB PPDU response. Refer to table 27-21 of IEEE Std 802.11ax-2021.
    %   This property is not applicable when you set the TriggerType
    %   property to 'MU-RTS'. The default value of this property is 15.
    SpatialReuse1 (1, 1) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(SpatialReuse1,15)} = 15;

    %SpatialReuse2 Spatial reuse-2 indication
    %   Specify spatial reuse-2 as an integer between 0 and 15, inclusive.
    %   This property indicates the value to be included in the
    %   corresponding spatial reuse field in the HE-SIG-A field of the HE
    %   TB PPDU response. Refer to table 27-21 of IEEE Std 802.11ax-2021.
    %   This property is not applicable when you set the TriggerType
    %   property to 'MU-RTS'. The default value of this property is 15.
    SpatialReuse2 (1, 1) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(SpatialReuse2,15)} = 15;

    %SpatialReuse3 Spatial reuse-3 indication
    %   Specify spatial reuse-3 as an integer between 0 and 15, inclusive.
    %   This property indicates the value to be included in the
    %   corresponding spatial reuse field in the HE-SIG-A field of the HE
    %   TB PPDU response. Refer to table 27-21 of IEEE Std 802.11ax-2021.
    %   This property is not applicable when you set the TriggerType
    %   property to 'MU-RTS'. The default value of this property is 15.
    SpatialReuse3 (1, 1) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(SpatialReuse3,15)} = 15;

    %SpatialReuse4 Spatial reuse-4 indication
    %   Specify spatial reuse-4 as an integer between 0 and 15, inclusive.
    %   This property indicates the value to be included in the
    %   corresponding spatial reuse field in the HE-SIG-A field of the HE
    %   TB PPDU response. Refer to table 27-21 of IEEE Std 802.11ax-2021.
    %   This property is not applicable when you set the TriggerType
    %   property to 'MU-RTS'. The default value of this property is 15.
    SpatialReuse4 (1, 1) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(SpatialReuse4,15)} = 15;

    %HighDoppler Indicate the presence of a midamble in the HE TB PPDU
    %response
    %   Set this property to true to indicate the presence of a midamble in
    %   the HE TB PPDU response. This property is not applicable when you
    %   set the TriggerType property to 'MU-RTS'. The default value is
    %   false.
    HighDoppler (1, 1) logical = false;

    %HESIGAReservedBits Reserved bits in HE-SIG-A field
    %   Specify the reserved field bits in the HE-SIG-A field as a binary
    %   column vector of length 9. This property indicates the 9-bit value
    %   to be included in the reserved field in the HE-SIG-A2 subfield of
    %   the HE TB PPDU response. This property is not applicable when you
    %   set the TriggerType property to 'MU-RTS'. The default value of this
    %   property is a column vector of ones.
    HESIGAReservedBits (9, 1) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(HESIGAReservedBits,1)} = ones(9,1);
end

properties(SetAccess = private, GetAccess = public)
    %UserInfo User Info fields of trigger frame
    %   Contains the user info fields. This property is a cell array where
    %   each element is an object of type wlanMACTriggerUserConfig.
    %   The NumUserInfo property indicates the number of User Info fields
    %   in this property that are included in the trigger frame. This is a
    %   read-only property. To add one or more User Info fields to this
    %   property, use the addUserInfo object function. The first User Info
    %   field added to this property using the addUserInfo method replaces
    %   the default User Info field.
    UserInfo;

    %NumUserInfo Number of User Info fields in UserInfo property
    %   Indicates the number of User Info fields in the UserInfo property
    %   that are included in the trigger frame. By default, one User Info
    %   field is included in the trigger frame. This is a read-only
    %   property.
    NumUserInfo = 1;
end

properties (Access = private)
    %UserInfoDefault UserInfo property holds the default User Info field
    UserInfoDefault = true;

    %RUInfo Array holding (RU size, RU index, primary 80MHz indication)
    %info for each user. Valid number of RU info values is determined from
    %NumUserInfo property.
    RUInfo = zeros(74, 3);
end

properties (Hidden)
    %Decoded Configuration holds decoded MPDU properties
    %   Indicates if this configuration holds decoded MPDU properties. When
    %   the wlanMPDUDecode function creates this object as an output of the
    %   MPDU decoding process, this property is true. Otherwise, this
    %   property is false.
    Decoded = false;

    %CommonInfoVariant Specify the variant of the Common Info field
    %   Specify the variant of the Common Info field in the Trigger frame.
    %   This property is only applicable when you set the TriggerType
    %   property to 'MU-RTS'. The default value is 'HE'.
    CommonInfoVariant = 'HE';

    %HEorEHTP160 Specify the bit value of the HE/EHT P160 bit
    %   Specify the bit value of HE/EHT P160 in the EHT variant common info
    %   field. A bit value of 0 indicates that an EHT TB PPDU is solicited
    %   in the primary 160 MHz channel. A bit value of 1 indicates that an
    %   HE TB PPDU is solicited in the primary 160 MHz channel. This property
    %   is only applicable when you set the TriggerType property to 'MU-RTS'.
    %   The default value is 1.
    HEorEHTP160 = 1;

    %SpecialUserInfoPresent Specify whether special user info field is present
    %   Specify whether special user info field is present in the list of user
    %   info fields. This property is only applicable when you specify the
    %   TriggerType property as 'MU-RTS', and CommonInfoVariant property as 'EHT'.
    %   The default value is false.
    SpecialUserInfoPresent = false;
end

properties (Hidden, Constant)
    TriggerType_Values = {'Basic', 'MU-BAR', 'MU-RTS'}
    ChannelBandwidth_Values = {'CBW20', 'CBW40', 'CBW80', 'CBW80+80 or CBW160'}
    HELTFTypeAndGuardInterval_Values = {'1x HE-LTF + 1.6 us GI', '2x HE-LTF + 1.6 us GI', '4x HE-LTF + 3.2 us GI'}
end

methods(Access = protected)
    function flag = isInactiveProperty(obj, prop)
        % Present in all trigger variants
        switch(prop)
            case {'TriggerType', 'MoreTF', 'CSRequired', 'ChannelBandwidth', 'NumUserInfo', 'UserInfo'}
                flag = false;

            otherwise   % {'LSIGLength', 'HELTFTypeAndGuardInterval', 'SingleStreamPilots', ...
                        %   'NumHELTFSymbols', 'MidamblePeriodicity', 'STBC', 'LDPCExtraSymbol', ...
                        %   'APTransmitPower', 'PreFECPaddingFactor', 'PEDisambiguity', 'SpatialReuse1', ...
                        %   'SpatialReuse2', 'SpatialReuse3', 'SpatialReuse4', 'HighDoppler', 'HESIGAReservedBits'}
                flag = strcmp(obj.TriggerType, {'MU-RTS'});
                if ~flag && strcmp(prop, 'SingleStreamPilots')
                    flag = strcmp(obj.HELTFTypeAndGuardInterval, '1x HE-LTF + 1.6 us GI');
                end
                if ~flag && strcmp(prop, 'MidamblePeriodicity')
                    flag = ~obj.HighDoppler;
                end
        end
    end
end

methods
    function obj = wlanMACTriggerConfig(varargin)
        obj@comm.internal.ConfigBase('TriggerType', 'Basic', ...
            'ChannelBandwidth', 'CBW20', ...
            'HELTFTypeAndGuardInterval', '4x HE-LTF + 3.2 us GI', ...
            varargin{:});

        obj.UserInfo = repmat({wlanMACTriggerUserConfig}, 74, 1);
    end

    function obj = set.TriggerType(obj, value)
        value = validatestring(value, obj.TriggerType_Values, 'wlanMACTriggerConfig', 'TriggerType');
        obj.TriggerType = '';
        obj.TriggerType = value;
    end

    function obj = set.ChannelBandwidth(obj, value)
        value = validatestring(value, obj.ChannelBandwidth_Values, 'wlanMACTriggerConfig', 'ChannelBandwidth');
        obj.ChannelBandwidth = '';
        obj.ChannelBandwidth = value;
    end

    function obj = set.HELTFTypeAndGuardInterval(obj, value)
        value = validatestring(value, obj.HELTFTypeAndGuardInterval_Values, 'wlanMACTriggerConfig', 'HELTFTypeAndGuardInterval');
        obj.HELTFTypeAndGuardInterval = '';
        obj.HELTFTypeAndGuardInterval = value;
    end

    function validateConfig(obj)
        % validateConfig Validate the wlanMACTriggerConfig object
        %
        %   validateConfig(OBJ) validates the dependent properties for the
        %   specified wlanMACTriggerConfig configuration object.

        %   For INTERNAL use only, subject to future changes.

        if ~strcmp(obj.TriggerType, 'MU-RTS')
            coder.internal.errorIf((obj.HighDoppler == 1) && (obj.NumHELTFSymbols > 4), 'wlan:wlanMACTriggerConfig:InvalidNumHELTFSymbolsDoppler', obj.NumHELTFSymbols);
            % Refer to section 9.3.1.22.1 of IEEE Std 802.11ax-2021
            coder.internal.errorIf((strcmp(obj.HELTFTypeAndGuardInterval, '1x HE-LTF + 1.6 us GI') && ~obj.SingleStreamPilots), 'wlan:wlanMACTriggerConfig:InvalidSingleStreamPilotsHELTFTypeAndGI');
        end

        % Refer to section 26.5.2.5 of IEEE Std 802.11ax-2021
        coder.internal.errorIf(strcmp(obj.TriggerType, 'MU-RTS') && ~obj.CSRequired, 'wlan:wlanMACTriggerConfig:CSRequiredMURTS');
        % The threshold values 76 and 418 are explained under the section
        % 26.5.2.5 of IEEE Std 802.11ax-2021
        coder.internal.errorIf(~((obj.LSIGLength <= 76) || (strcmp(obj.TriggerType, 'MU-BAR') && (obj.LSIGLength <= 418))) && ~obj.CSRequired, ...
            'wlan:wlanMACTriggerConfig:InvalidCSRequiredForLSIGLength');
        % Refer to section 26.5.2.2.4 of IEEE Std 802.11ax-2021
        coder.internal.errorIf((obj.NumUserInfo == 1) && (obj.UserInfo{1}.StartingSpatialStream ~= 1), 'wlan:wlanMACTriggerConfig:InvalidStartingStreamSingleUser');
    end
end

methods (Access = private)
    function validateCommonInfoUserInfo(obj, userInfoCfg)
        % validateConfig Validates the dependent properties from
        % wlanMACTriggerConfig and wlanMACTriggerUserConfig

        % Validate User Info configuration against the common info
        ruInfo = [userInfoCfg.RUSize userInfoCfg.RUIndex];
        if strcmp(obj.ChannelBandwidth, 'CBW80+80 or CBW160')
            cbw = 160;
            if userInfoCfg.RUSize < 1992
                % For 160 MHz bandwidth, the MAC treats each 80 MHz separately.
                % Therefore, validate RU size and index within 80 MHz, except for
                % a full-band 160 MHz (1992-tone RU).
                cbw = 80;
            end
        else % 'CBW20', 'CBW40', 'CBW80'
            cbw = wlan.internal.cbwStr2Num(obj.ChannelBandwidth);
        end
        wlan.internal.validateRUArgument(ruInfo, cbw);

        if ~(strcmp(obj.TriggerType, {'MU-RTS'})) && ~any(userInfoCfg.AID12 == [0, 2045, 2046])
            numSTS = userInfoCfg.StartingSpatialStream + userInfoCfg.NumSpatialStreams - 1;
            % Validate StartingSpatialStream and NumHELTFSymbols
            Nltf = wlan.internal.numVHTLTFSymbols(numSTS);
            coder.internal.errorIf(obj.NumHELTFSymbols < Nltf, 'wlan:wlanMACTriggerConfig:InvalidNumHELTFSymbols', ...
                Nltf, userInfoCfg.StartingSpatialStream, userInfoCfg.NumSpatialStreams);
        end

        % Refer to section 9.3.1.22.1 of IEEE Std 802.11ax-2021
        coder.internal.errorIf(obj.STBC && userInfoCfg.DCM, 'wlan:wlanMACTriggerConfig:DCMNotAllowedWithSTBC');

        % Verify if duplicate RU info
        for idx = 1:obj.NumUserInfo-1
            coder.internal.errorIf(all(obj.RUInfo(idx, :) == [ruInfo, strcmp(userInfoCfg.RUAllocationRegion, 'primary 80MHz')]), ...
                'wlan:wlanMACTriggerConfig:DuplicateRUInfo', userInfoCfg.RUIndex, idx);
        end
    end
end

methods
    function obj = addUserInfo(obj, userInfoCfg)
        %addUserInfo Add a User Info field to the MAC trigger frame
        %   OBJ = addUserInfo(OBJ, USERINFOCFG) updates and returns the MAC
        %   trigger frame configuration object, OBJ, after adding User Info
        %   fields.
        %
        %   USERINFOCFG is an object of type wlanMACTriggerUserConfig

        validateattributes(userInfoCfg, {'wlanMACTriggerUserConfig'}, {'scalar'}, 'wlanMACTriggerConfig');

        if obj.UserInfoDefault
            obj.UserInfoDefault = false;
        else
            obj.NumUserInfo = obj.NumUserInfo + 1;
            coder.internal.errorIf(obj.NumUserInfo > 74, 'wlan:wlanMACTriggerConfig:UserInfoLimitReached');
        end

        coder.internal.errorIf(~strcmp(userInfoCfg.TriggerType, obj.TriggerType), 'wlan:wlanMACTriggerConfig:TriggerTypeMismatch');

        % AIDs between 1 and 2007 should not be repeated. Refer to section
        % 26.5.2.2.4 of IEEE Std 802.11ax-2021
        for idx = 1:obj.NumUserInfo-1
            coder.internal.errorIf(~any(userInfoCfg.AID12 == [0, 2045, 2046]) && (obj.UserInfo{idx}.AID12 == userInfoCfg.AID12), 'wlan:wlanMACTriggerConfig:DuplicateAID12');
        end

        if ~obj.Decoded
            % Validate the User Info configuration
            validateConfig(userInfoCfg);
            % Validate User Info configuration against the common info
            validateCommonInfoUserInfo(obj, userInfoCfg);
        end

        ruInfo = [userInfoCfg.RUSize, userInfoCfg.RUIndex, strcmp(userInfoCfg.RUAllocationRegion, 'primary 80MHz')];
        % Store if valid RU info
        obj.RUInfo(obj.NumUserInfo, :) = ruInfo;

        % Add User Info field to the list
        obj.UserInfo{obj.NumUserInfo} = userInfoCfg;
    end
end

methods (Hidden)
    function obj = addSpecialUserInfo(obj, specialUserInfoCfg)
        if obj.NumUserInfo == 1 % Special User Info field must be added before the other user info fields
            obj.UserInfo{obj.NumUserInfo} = specialUserInfoCfg;
            obj.NumUserInfo = obj.NumUserInfo + 1;
            obj.SpecialUserInfoPresent = true;
        end
    end
end
end

