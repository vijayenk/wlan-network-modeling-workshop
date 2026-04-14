classdef wlanEHTTBConfig < comm.internal.ConfigBase
%wlanEHTTBConfig Create an extremely high-throughput (EHT) trigger-based (TB) format configuration object
%   CFG = wlanEHTTBConfig creates an uplink EHT TB format configuration
%   object. This object contains the transmit parameters for the EHT TB
%   format of IEEE P802.11be/D5.0.
%
%   CFG = wlanEHTTBConfig(Name,Value) creates an EHT TB object, CFG, with
%   the specified property Name set to the specified Value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanEHTTBConfig methods:
%
%   psduLength            - Number of bytes to be coded in the packet
%   packetFormat          - EHT TB packet format
%   ruInfo                - Resource unit (RU) allocation information
%   showAllocation        - Shows the RU allocation
%   transmitTime          - Time required to transmit a packet
%   compressionMode       - Compression mode
%   numPostFECPaddingBits - Required number of post-FEC padding bits
%
%   wlanEHTTBConfig properties:
%
%   ChannelBandwidth         - Channel bandwidth (MHz) of PPDU transmission
%   RUSize                   - RU size
%   RUIndex                  - RU index
%   PreEHTPowerScalingFactor - Power scaling factor for pre-EHT TB field
%   NumTransmitAntennas      - Number of transmit antennas
%   PreEHTCyclicShifts       - Cyclic shift values for >8 transmit chains
%   NumSpaceTimeStreams      - Number of space-time streams
%   StartingSpaceTimeStream  - Starting space-time stream index
%   SpatialMapping           - Spatial mapping scheme
%   SpatialMappingMatrix     - Spatial mapping matrix
%   PreEHTPhaseRotation      - Pre-EHT phase rotation coefficients for 320 MHz
%   MCS                      - Modulation and coding scheme
%   ChannelCoding            - Forward error correction (FEC) coding type
%   PreFECPaddingFactor      - The pre-FEC padding factor for an EHT TB PPDU
%   LDPCExtraSymbol          - LDPC extra OFDM symbol indication
%   PEDisambiguity           - The PE-Disambiguity for an EHT TB PPDU
%   LSIGLength               - L-SIG length of an EHT TB PPDU
%   GuardInterval            - Guard interval type
%   EHTLTFType               - EHT-LTF compression type
%   NumEHTLTFSymbols         - Number of EHT-LTF symbols in the PPDU
%   BSSColor                 - Basic service set (BSS) color identifier
%   SpatialReuse1            - Spatial reuse-1 indication
%   SpatialReuse2            - Spatial reuse-2 indication
%   TXOPDuration             - Duration information for TXOP protection
%   Channelization           - Channelization for 320 MHz
%   DisregardBitsUSIG1       - Disregard bits in the first U-SIG symbol
%   ValidateBitUSIG2         - Validate bit in the second U-SIG symbol
%   DisregardBitsUSIG2       - Disregard bits in the second U-SIG symbol
%   PostFECPaddingSource     - Post-FEC padding bits source
%   PostFECPaddingSeed       - Initial random post-FEC padding bits seed
%   PostFECPaddingBits       - Post-FEC padding bits

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen
properties (Access = 'public')
    %ChannelBandwidth Channel bandwidth (MHz) of PPDU transmission
    %   Specify the channel bandwidth as one of 'CBW20' | 'CBW40' | 'CBW80'
    %   | 'CBW160'| 'CBW320'. The default is 'CBW20'.
    ChannelBandwidth = 'CBW20';
    %RUSize Resource unit size
    %   Specify the RU size as a scalar or a row vector for an MRU. If
    %   scalar, the RU size must be one of 26, 52, 106, 242, 484, 996, 1992
    %   (2x996), or 3984 (4x996). For an MRU, RU size is a row vector,
    %   where each element of the row vector must be 26, 52, 106, 242, 484,
    %   or 996. The default is 242.
    RUSize (1,:) {wlan.internal.validateEHTRUSize(RUSize)} = 242;
    %RUIndex Resource unit index
    %   Specify the RU index as a nonzero integer. RU index is a scalar, or
    %   a row vector for an MRU. The RU index specifies the location of
    %   the RU within the channel. For example, in an 80 MHz transmission
    %   there are four possible 242 tone RUs, one in each 20 MHz
    %   subchannel. RU# 242-1 (size 242, index 1) is the RU occupying the
    %   lowest absolute frequency within the 80 MHz, and RU# 242-4 (size
    %   242, index 4) is the RU occupying the highest absolute
    %   frequency. The default is 1.
    RUIndex (1,:) {mustBeNumeric,mustBeInteger,mustBeNonempty,mustBeGreaterThanOrEqual(RUIndex,1),mustBeLessThanOrEqual(RUIndex,148)} = 1;
    %PreEHTPowerScalingFactor Power scaling factor for pre-EHT fields
    %   Specify the power scaling factor for the pre-EHT TB fields in the
    %   range [1/sqrt(2),1]. The default is 1.
    PreEHTPowerScalingFactor (1,1) {mustBeNumeric,wlan.internal.validatePreEHTPowerScalingFactor(PreEHTPowerScalingFactor)} = 1;
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as positive integer. The
    %   default is 1.
    NumTransmitAntennas (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumTransmitAntennas,1)} = 1;
    %PreEHTCyclicShifts Cyclic shift values for >8 transmit chains
    %   Specify the cyclic shift values for the pre-EHT portion of the
    %   waveform, in nanoseconds, for more than 8 transmit antennas as a
    %   row vector of length L = NumTransmitAntennas-8. The cyclic shift
    %   values must be between -200 and 0 inclusive. The first 8 antennas
    %   use the cyclic shift values defined in Table 21-10 of IEEE Std
    %   802.11-2020. The remaining antennas use the cyclic shift values
    %   defined in this property. If the length of this row vector is
    %   specified as a value greater than L the object only uses the first
    %   L PreEHTCyclicShifts values. For example, if you specify the
    %   NumTransmitAntennas property as 16 and this property as a row
    %   vector of length N>L, the object only uses the first L = 16-8 = 8
    %   entries. This property applies only when you set the
    %   NumTransmitAntennas property to a value greater than 8. The default
    %   is -75.
    PreEHTCyclicShifts {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(PreEHTCyclicShifts,-200),mustBeLessThanOrEqual(PreEHTCyclicShifts,0)} = -75;
    %NumSpaceTimeStreams Number of space-time streams
    %   Specify the number of space-time streams as integer between 1 and
    %   8, inclusive. The default is 1.
    NumSpaceTimeStreams (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumSpaceTimeStreams,1),mustBeLessThanOrEqual(NumSpaceTimeStreams,8)} = 1;
    %StartingSpaceTimeStream Starting space-time stream index
    %   Specify the starting space-time stream index as 1-based index. When
    %   multiple users are transmitting in the same RU, in an MU-MIMO
    %   configuration, each user must transmit on different space-time
    %   streams. The StartingSpaceTimeStream and NumSpaceTimeStreams
    %   properties must be set to ensure each user transmits on a distinct
    %   space-time stream. The default is 1.
    StartingSpaceTimeStream (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(StartingSpaceTimeStream,1),mustBeLessThanOrEqual(StartingSpaceTimeStream,8)} = 1;
    %SpatialMapping Spatial mapping scheme
    %   Specify the spatial mapping scheme as one of 'direct' | 'hadamard'|
    %   'fourier' | 'custom'. The default value of this property is
    %   'direct', which applies when NumSpaceTimeStreams is equal to
    %   NumTransmitAntennas.
    SpatialMapping (1,1) wlan.type.SpatialMapping = wlan.type.SpatialMapping.direct;
    %SpatialMappingMatrix Spatial mapping matrix(ces)
    %   Specify the spatial mapping matrix(ces) as a real or complex, 2D
    %   matrix or 3D array. This property applies when you set the
    %   SpatialMapping property to 'Custom'. It can be of size
    %   NstsTotal-by-Nt, where NstsTotal is the sum of the elements in the
    %   NumSpaceTimeStreams property and Nt is the NumTransmitAntennas
    %   property. In this case, the spatial mapping matrix applies to all
    %   the subcarriers. Alternatively, it can be of size Nst-by-
    %   NstsTotal-Nt, where Nst is the number of occupied subcarriers
    %   determined by the RU size. Specifically, Nst is 26, 52, 78, 106,
    %   132, 242, 484, 726, 968, 996, 1480, 1992, 2476, 2988, or 3984. In
    %   this case, each occupied subcarrier can have its own spatial
    %   mapping matrix. In either 2D or 3D case, the spatial mapping matrix
    %   for each subcarrier is normalized. The default value of this
    %   property is 1.
    SpatialMappingMatrix {wlan.internal.ehtValidateSpatialMappingMatrix} = complex(1);
    %PreEHTPhaseRotation Pre-EHT phase rotation coefficients for 320 MHz
    %   Specifies the phase rotation coefficients for the pre-EHT portion
    %   of the waveform as a row vector of size 1-by-16. Each element of
    %   the vector corresponds to a complex multiplier applied to the
    %   respective subcarriers in a 20 MHz subchannel, ordered by
    %   increasing frequency, as defined in Equation 36-13 of IEEE
    %   P802.11be/D5.0. This property only applies when ChannelBandwidth is
    %   CBW320. The default value is [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1
    %   1].
    PreEHTPhaseRotation (1,16) {mustBeNumeric,mustBeFinite,mustBeNonzero} = [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1 1];
    %MCS Modulation and coding scheme per user
    %   Specify the modulation and coding scheme as an integer scalar
    %   between 0 to 13 (inclusive) or 15. The default is 0.
    MCS (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(MCS,[0:13 15])} = 0;
    %ChannelCoding Forward error correction coding type
    %   Specify the channel coding as one of 'bcc' or 'ldpc' to indicate
    %   binary convolution coding (BCC) or low-density-parity-check (LDPC)
    %   coding. The default is 'ldpc'.
    ChannelCoding (1,1) wlan.type.ChannelCoding = wlan.type.ChannelCoding.ldpc;
    %PreFECPaddingFactor Specify the pre-FEC padding factor for an EHT TB PPDU
    %   Specify the pre-FEC padding factor for an EHT TB PPDU as 1,2,3, or
    %   4. The default is 4.
    PreFECPaddingFactor (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(PreFECPaddingFactor,1),mustBeLessThanOrEqual(PreFECPaddingFactor,4)} = 4;
    %LDPCExtraSymbol LDPC extra OFDM symbol indication
    %   To indicate the presence of an extra OFDM symbol for LDPC encoding,
    %   set this property to true. The default is false.
    LDPCExtraSymbol (1,1) logical = false;
    % PEDisambiguity PE-Disambiguity for an EHT TB PPDU
    %   To indicate the PE-Disambiguity for an EHT TB PPDU, set this
    %   property to true. The default is false.
    PEDisambiguity (1,1) logical = 0;
    %LSIGLength L-SIG length of an EHT TB PPDU
    %   Specify the L-SIG length for an EHT TB PPDU as an integer scalar
    %   between 1 and 4093 (inclusive). The value of the L-SIG length must
    %   satisfy, mod(LSIGLength+2,3)=0. The  default is 142.
    LSIGLength (1,1) {wlan.internal.mustBeValidLSIGLength(LSIGLength,'EHT TB')} = 142;
    %GuardInterval Guard interval type
    %   Specify the guard interval (cyclic prefix) length in microseconds
    %   as one of 1.6 or 3.2. The default is 3.2.
    GuardInterval (1,1) {mustBeMember(GuardInterval,[1.6,3.2])} = 3.2;
    %EHTLTFType EHT-LTF compression type
    %   Specify the EHT-LTF compression type as one of 1, 2, or 4,
    %   corresponding to 1xEHT-LTF, 2xEHT-LTF, and 4xEHT-LTF type
    %   respectively. The default is 4.
    EHTLTFType (1,1) {mustBeNumeric,mustBeMember(EHTLTFType,[1 2 4])} = 4;
    %NumEHTLTFSymbols Number of EHT-LTF symbols in the PPDU
    %   Specify the number of EHT-LTF symbols in an EHT TB PPDU as one of 1,
    %   2, 4, 6, or 8. The default is 1.
    NumEHTLTFSymbols (1,1) {mustBeNumeric,mustBeMember(NumEHTLTFSymbols,[1 2 4 6 8])} = 1;
    %BSSColor Basic service set (BSS) color identifier
    %   Specify the BSS color number of a basic service set as an integer
    %   scalar between 0 to 63, inclusive. The default is 0.
    BSSColor (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(BSSColor,0),mustBeLessThanOrEqual(BSSColor,63)} = 0;
    %SpatialReuse1 Spatial reuse-1 indication
    %   Specify spatial reuse-1 in U-SIG as an integer scalar between 0
    %   and 15, inclusive. The default is 15.
    SpatialReuse1 (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SpatialReuse1,0),mustBeLessThanOrEqual(SpatialReuse1,15)} = 15;
    %SpatialReuse2 Spatial reuse-2 indication
    %   Specify spatial reuse-2 in U-SIG as an integer scalar between 0
    %   and 15, inclusive. The default is 15.
    SpatialReuse2 (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SpatialReuse2,0),mustBeLessThanOrEqual(SpatialReuse2,15)} = 15;
    %TXOPDuration Duration information for TXOP protection
    %   Specify the TXOPDuration signaled in U-SIG in microseconds as
    %   integer scalar between 0 and 8448, inclusive as specified in Table
    %   36-1 of IEEE P802.11be/D5.0. For more information see the documentation.
    %   Use empty ([]) to specify no NAV duration and the TXOP field in
    %   U-SIG is set to 127. The default is [].
    TXOPDuration {wlan.internal.ehtValidateTXOPDuration(TXOPDuration)} = [];
    %Channelization Channelization for 320 MHz
    %   Specify the channelization for 320 MHz channel bandwidth as 1 or 2,
    %   corresponding to '320MHz-1' and '320MHz-2' in Section 36.3.24.2 of
    %   IEEE P802.11be/D5.0. This property only applies when
    %   ChannelBandwidth is CBW320. The default value is 1.
    Channelization (1,1) {mustBeNumeric,mustBeMember(Channelization,[1 2])} = 1;
    %DisregardBitsUSIG1 Disregard bits in the first U-SIG symbol
    %   Specify the disregard bits in the first OFDM symbol of U-SIG field
    %   as a binary column vector of length 6 (bit locations 21 to 26). See
    %   Table 36-31 of IEEE P802.11be/D5.0. The default is a column vector
    %   of ones.
    DisregardBitsUSIG1 (6,1) {wlan.internal.validateBits(DisregardBitsUSIG1,'DisregardBitsUSIG1')} = ones(6,1,'int8');
    %ValidateBitUSIG2 Validate bit in the second U-SIG symbol
    %   Specify the validate bit in the second OFDM symbols of U-SIG field
    %   as 1 or 0. The default is 1.
    ValidateBitUSIG2 (1,1) {wlan.internal.validateBits(ValidateBitUSIG2,'ValidateBitUSIG2')} = int8(1);
    %DisregardBitUSIG2 Disregard bits in the second U-SIG symbol
    %   Specify the disregard bits in the second OFDM symbol of U-SIG field
    %   as a binary column vector of length 5 (bit location 12 to 16). See
    %   Table 36-31 of IEEE P802.11be/D5.0. The default is [0; 1; 1; 1; 1].
    DisregardBitsUSIG2 (5,1) {wlan.internal.validateBits(DisregardBitsUSIG2,'DisregardBitsUSIG2')} = int8([0; 1; 1; 1; 1]);
    %PostFECPaddingSource Post-FEC padding bit source
    %   Specify the source of post-FEC padding bits for the waveform
    %   generator as 'mt19937arwithseed', 'globalstream', or 'userdefined'.
    %   To use the mt19937ar random number generator algorithm with a seed
    %   to generate normally distributed random bits, set this property to
    %   'mt19937arwithseed'. The mt19937ar algorithm uses the seed
    %   specified by the value of the PostFECPaddingSeed property. To use
    %   the current global random number stream to generate normally
    %   distributed random bits, set this property to 'globalstream'. To
    %   use bits specified in the PostFECPaddingBits property, set this
    %   property to 'userdefined'. The default is 'mt19937arwithseed'.
    PostFECPaddingSource (1,1) wlan.type.PostFECPaddingSource = wlan.type.PostFECPaddingSource.mt19937arwithseed;
    %PostFECPaddingSeed Initial random post-FEC padding bit seed
    %   Specify the initial seed of the mt19937ar random number generator
    %   algorithm as a nonnegative integer. This property applies when you
    %   set the PostFECPaddingSource property to 'mt19937arwithseed'. The
    %   default is 73.
    PostFECPaddingSeed (1,1) {mustBeNumeric,mustBeInteger,mustBeNonnegative} = 73;
    %PostFECPaddingBits Post-FEC padding bits
    %   Specify post-FEC padding bits as an int8, double, or single typed
    %   binary column vector. For C code generation this property must be
    %   int8 typed. The waveform generator loops the vector if the number
    %   of bits required exceeds the length of the vector provided. The
    %   number of bits the waveform generator uses from the vector is given
    %   by the numPostFECPaddingBits object function. The default is 0.
    PostFECPaddingBits (:,1) {wlan.internal.validateBits(PostFECPaddingBits,'PostFECPaddingBits')} = int8(0);
end

properties(Constant,Hidden)
    ChannelBandwidth_Values = {'CBW20','CBW40','CBW80','CBW160','CBW320'};
    EHTDUPMode = false; % EHT DUP mode is not supported for EHT TB
    NumExtraEHTLTFSymbols = 0; % No extra EHT-LTF symbols in EHT TB
end

methods
    function obj = wlanEHTTBConfig(varargin)
        if ~isempty(coder.target)
            channelBandwidth = 'CBW20';
            coder.varsize('channelBandwidth',[1 6],[0 1]); % Add variable-size support
            obj.ChannelBandwidth = channelBandwidth; % Default

            postFECPaddingBits = int8(0);
            coder.varsize('postFECPaddingBits',[3920*12*8 1],[1 0]); % Add variable-size support (NCBPS = NSD*NBPSCS*NSS)
            obj.PostFECPaddingBits = postFECPaddingBits; % Default
        end
        obj = setProperties(obj,varargin{:}); % Superclass method for NV pair parsing
    end

    function obj = set.ChannelBandwidth(obj,val)
        val = validateEnumProperties(obj,'ChannelBandwidth',val);
        obj.ChannelBandwidth = val;
    end

    function psduLength = psduLength(obj)
        %psduLength Returns PSDU length for the configuration
        %   Returns the PSDU length for an EHT TB configuration as defined in
        %   Section 36.4.3 of IEEE P802.11be/D5.0.


        validateLSIGLength(obj); % Validate LSIGLength
        psduLength = wlan.internal.ehtPLMETxTimePrimative(obj);
    end

    function format = packetFormat(obj) %#ok<MANU>
    %packetFormat Returns the packet format
    %   Returns the packet format as a character vector.

        format = 'EHT-TB';
    end

    function s = ruInfo(obj)
    %ruInfo Returns RU allocation information
    %   S = ruInfo(CFG) returns a structure, S, containing the resource
    %   unit (RU) allocation information for the wlanEHTTBConfig object,
    %   CFG. The output structure S has these fields:
    %
    %   NumUsers                  - Number of users
    %   NumRUs                    - Number of RUs
    %   RUIndices                 - Index of the RU/MRU
    %   RUSizes                   - Size of the RU/MRU
    %   NumUsersPerRU             - Number of users per RU
    %   NumSpaceTimeStreamsPerRU  - Total number of space-time streams
    %   PowerBoostFactorPerRU     - Power boost factor
    %   RUNumbers                 - RU number
    %   RUAssigned                - Indicate assigned RU

        s = struct;
        s.NumUsers = 1;
        s.NumRUs = 1;
        s.RUIndices = {obj.RUIndex};
        s.RUSizes = {obj.RUSize};
        s.NumUsersPerRU = 1;
        s.NumSpaceTimeStreamsPerRU = obj.NumSpaceTimeStreams;
        s.PowerBoostFactorPerRU = 1;
        s.RUNumbers = 1;
        s.RUAssigned = true;
    end

    function showAllocation(obj,varargin)
    %showAllocation Shows the RU allocation
    %   showAllocation(cfg) shows the RU allocation for an EHT TB format
    %   configuration object
    %
    %   showAllocation(cfg,AX) shows the allocation in the axes specified
    %   by AX instead of in the current axes. If AX is not specified,
    %   showAllocation plots the allocation in a new figure.

        wlan.internal.validateEHTRUArgument(obj.RUSize,obj.RUIndex,wlan.internal.cbwStr2Num(obj.ChannelBandwidth));
        wlan.internal.hePlotAllocation(obj,varargin{:});
    end

    function n = numPostFECPaddingBits(obj)
        %numPostFECPaddingBits Required number of post-FEC padding bits
        %   Returns a vector with the required number of post-FEC padding
        %   bits for each user.

        [~,userCodingParams] = wlan.internal.ehtCodingParameters(obj);
        n = [userCodingParams.NPADPostFEC];
    end

    function t = transmitTime(obj,varargin)
    %transmitTime Returns the time required to transmit a packet
    %   T = transmitTime(CFG) returns the time required to transmit a
    %   packet in seconds.
    %
    %   T = transmitTime(CFG,UNIT) returns the transmit time in the
    %   requested unit. UNIT must be 'seconds', 'milliseconds',
    %   'microseconds', or 'nanoseconds'.

        narginchk(1,2);
        [~,t] = wlan.internal.ehtPLMETxTimePrimative(obj);
        t = t*1e-3; % Scale from nanoseconds to microseconds
        t = wlan.internal.convertTransmitTime(t,varargin{:});
    end

    function mode = compressionMode(obj) %#ok<MANU>
    %compressionMode Returns compression mode as defined in IEEE P802.11be/D5.0, Table 36-29

        mode = 0; % EHT TB
    end

    function varargout = validateConfig(obj,varargin)
    %validateConfig Validate the dependent properties of wlanEHTTBConfig object
    %   validateConfig(CFG) validates the dependent properties for the
    %   specified wlanEHTTBConfig configuration object.
    %
    %   For INTERNAL use only, subject to future changes.
    %
    %   validateConfig(CFG,MODE) validates only the subset of dependent
    %   properties as specified by the MODE input. MODE must be one of:
    %       'DataLocationLength'
    %       'EHTLTFGI'
    %       'Coding'
    %       'CyclicShift'
    %       'EHTMCS15'
    %       'Full'

        narginchk(1,2);
        nargoutchk(0,1);

        if (nargin==2)
            mode = varargin{1};
        else
            mode = 'Full';
        end

        switch mode
            case 'DataLocationLength' % wlanFieldIndices (EHT-LTF)
                % Validate MCS and length
                s = validateMCSLengthTxTime(obj);
            case 'EHTLTFGI' % wlanFieldIndices (EHT-LTF)
                % Validate GuardInterval and EHTLTFType
                validateEHTLTFGI(obj);
            case 'Coding' % wlanEHTDataBitRecover
                % Validate channel coding
                validateCoding(obj);
            case 'CyclicShift'
                % Validate PreEHTCyclicShifts against NumTransmitAntennas
                validatePreEHTCyclicShifts(obj);
            case 'EHTMCS15'
                % Validate MCS-15
                validateMCS15(obj);
            otherwise % wlanWaveformGenerator
                % Full object validation

                % Validate GuardInterval and EHTLTFType
                validateEHTLTFGI(obj);

                % Validate ChannelCoding for BCC
                validateCoding(obj);

                % Validate PreEHTCyclicShifts against NumTransmitAntennas
                validatePreEHTCyclicShifts(obj);

                % Validate MCS-15
                validateMCS15(obj);

                % Validate Spatial mapping properties and spatial mapping matrix
                validateSpatialMapping(obj)

                % Validate RUSize, RUIndex, and ChannelBandwidth
                wlan.internal.validateEHTRUArgument(obj.RUSize,obj.RUIndex,wlan.internal.cbwStr2Num(obj.ChannelBandwidth));

                s = validateMCSLengthTxTime(obj);
        end

        if nargout == 1
            varargout{1} = s;
        end
    end
end

methods (Access = private)
    function s = validateMCSLengthTxTime(obj)
    %validateMCSLengthTxTime Validate the EHT TB packet length

        % Validate LSIGLength
        validateLSIGLength(obj);

        [psduLength,txTime,commonCodingParams,~,trc] = wlan.internal.ehtPLMETxTimePrimative(obj);
        sf = 1e3; % Scaling factor to convert time from ns to us

        % Set output structure
        s = struct( ...
            'TxTime', txTime/sf, ... % TxTime in us
            'LSIGLength', obj.LSIGLength, ...
            'PSDULength', psduLength, ...
            'NumDataSymbols', commonCodingParams.NSYM, ...
            'TPE', trc.TPE/sf); % TPE in us
    end

    function validateEHTLTFGI(obj)
    %validateEHTLTFGI Validate GuardInterval and EHTLTFType
    %   Validated property-subset includes:
    %     EHTLTFType, GuardInterval
          % Valid EHTLTFType modes are:
          %   1 x EHTLTFType and 1.6 GI
          %   2 x EHTLTFType and 1.6 GI
          %   4 x EHTLTFType and 3.2 GI

        coder.internal.errorIf(any(obj.EHTLTFType==[1 2]) && obj.GuardInterval~=1.6,'wlan:shared:InvalidGILTF',sprintf('%1.1f',obj.GuardInterval),'EHTLTFType',obj.EHTLTFType);
        coder.internal.errorIf(obj.EHTLTFType==4 && obj.GuardInterval~=3.2,'wlan:shared:InvalidGILTF',sprintf('%1.1f',obj.GuardInterval),'EHTLTFType',obj.EHTLTFType);
    end

    function validateCoding(obj)
    %validateCoding Coding properties for wlanEHTTBConfig configuration object
    %   Validated property-subset includes:
    %     NumSpaceTimeStreams, MCS, ChannelCoding, RUSize

        % Validate BCC coding
        if obj.ChannelCoding==wlan.type.ChannelCoding.bcc
            coder.internal.errorIf(sum(obj.RUSize)>242,'wlan:shared:InvalidBCCRUSize');
            coder.internal.errorIf(any(obj.MCS==[10 11 12 13]),'wlan:eht:InvalidBCCMCS');
            coder.internal.errorIf(obj.NumSpaceTimeStreams>4,'wlan:shared:InvalidNSTS');
        end
    end

    function validatePreEHTCyclicShifts(obj)
    %validatePreEHTCyclicShifts Validate PreEHTCyclicShifts values against NumTransmitAntennas
    %   Validated property-subset includes:
    %     PreEHTCyclicShifts, NumTransmitAntennas

        numTx = obj.NumTransmitAntennas;
        csh = obj.PreEHTCyclicShifts;
        if numTx>8
            coder.internal.errorIf(~(numel(csh)>=numTx-8),'wlan:shared:InvalidCyclicShift','PreEHTCyclicShifts',numTx-8);
        end
    end

    function validateMCS15(obj)
        %validateMCS15 Validate EHT-MCS 15
        %
        %   Validated property-subset includes:
        %     NumSpaceTimeStreams

        coder.internal.errorIf(obj.MCS==15 && obj.NumSpaceTimeStreams>1,'wlan:eht:InvalidMCS15NSTS');
    end

    function validateSpatialMapping(obj)
    %validateSpatialMapping Validate the spatial mapping properties
        %   Validated property-subset includes:
        %     ChannelBandwidth, NumTransmitAntennas, NumSpaceTimeStreams,
        %     SpatialMapping, SpatialMappingMatrix,
        %     StartingSpaceTimeStream, NumEHTLTFSymbols

        % Validate SpatialMappingMatrix, SpatialMapping and the number of transmit antennas
        coder.internal.errorIf(obj.NumTransmitAntennas < obj.NumSpaceTimeStreams,'wlan:he:NumSTSLargerThanNumTx',1,obj.NumSpaceTimeStreams,obj.NumTransmitAntennas);
        if obj.SpatialMapping==wlan.type.SpatialMapping.custom
            wlan.internal.validateSpatialMappingMatrix(obj.SpatialMappingMatrix,obj.NumTransmitAntennas,obj.NumSpaceTimeStreams,sum(obj.RUSize));
        else
            coder.internal.errorIf(obj.SpatialMapping==wlan.type.SpatialMapping.direct && obj.NumSpaceTimeStreams~=obj.NumTransmitAntennas,'wlan:he:NumSTSNotEqualNumTxDirectMap',1,obj.NumSpaceTimeStreams,obj.NumTransmitAntennas);
        end

        % Validate StartingSpaceTimeStream and NumSpaceTimeStreams
        numSTS = obj.StartingSpaceTimeStream+obj.NumSpaceTimeStreams-1;
        coder.internal.errorIf(numSTS>8,'wlan:wlanHETBConfig:InvalidStartingSpaceTimeStream');

        % Validate StartingSpaceTimeStream and NumEHTLTFSymbols
        Nltf = wlan.internal.numVHTLTFSymbols(numSTS);
        coder.internal.errorIf(obj.NumEHTLTFSymbols<Nltf,'wlan:shared:InvalidNumLTFSymbols','NumEHTLTFSymbols',Nltf,obj.StartingSpaceTimeStream,obj.NumSpaceTimeStreams);
    end

    function validateLSIGLength(obj)
    %validateLSIGLength Validate LSIGLength value
    %   Validated property-subset includes:
    %     LSIGLength

        [trc,NSYM,TEHTPREAMBLE] = wlan.internal.ehtTBTimingRelatedConstants(obj);
        sf = 1e3; % Scaling factor to convert time in us into ns
        if NSYM<1
            SignalExtension = 0;
            if obj.PEDisambiguity
                numSYM = 2;
            else
                numSYM = 1;
            end
            minTXTIME = 20*sf+TEHTPREAMBLE+trc.TSYM*numSYM; % Minimum TXTIME without TPE + time for one data field symbol
            lsigLength = ceil((minTXTIME-SignalExtension-20e3)/4e3)*3-3;
            % The value of LSIGLength without packet extension must be
            % greater than or equal to the length of the preamble field
            % plus one data symbol.
            coder.internal.error('wlan:shared:InvalidLSIGLength',ceil(lsigLength/3)*3-2);
        end
    end
end

methods (Access = protected)
    function flag = isInactiveProperty(obj, prop)
        flag = false;
        switch prop
            case 'LDPCExtraSymbol'
                % Hide LDPCExtraSymbol when ChannelCoding is BCC
                flag = obj.ChannelCoding==wlan.type.ChannelCoding.bcc;
            case 'SpatialMappingMatrix'
                % Hide SpatialMappingMatrix when SpatialMapping is not Custom
                flag = obj.SpatialMapping~=wlan.type.SpatialMapping.custom;
            case 'PreEHTCyclicShifts'
                % Hide PreEHTCyclicShifts when NumTransmitAntennas <=8
                flag = obj.NumTransmitAntennas<=8;
            case 'PostFECPaddingSeed'
                % Hide PostFECPaddingSeed when PostFECPaddingSource is not mt19937arwithseed
                flag = obj.PostFECPaddingSource~=wlan.type.PostFECPaddingSource.mt19937arwithseed;
            case 'PostFECPaddingBits'
                % Hide PostFECPaddingBits when PostFECPaddingSource is not userdefined
                flag = obj.PostFECPaddingSource~=wlan.type.PostFECPaddingSource.userdefined;
            case {'PreEHTPhaseRotation','Channelization'}
                % Hide PreEHTPhaseRotation for bandwidths other than 320 MHz
                flag = ~strcmp(obj.ChannelBandwidth,'CBW320');
        end
    end
end
end
