classdef wlanHESUConfig < comm.internal.ConfigBase
%wlanHESUConfig Create a single user high efficiency (HE) format configuration object
%   CFGHE = wlanHESUConfig creates a single user (SU) high efficiency (HE)
%   format configuration object. This object contains the transmit
%   parameters for the HE SU format of IEEE Std 802.11ax-2021 standard.
%
%   CFGHE = wlanHESUConfig(Name,Value) creates an HE SU object, CFGHE, with
%   the specified property Name set to the specified Value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanHESUConfig methods:
%
%   getPSDULength            - Number of bytes to be coded in the packet
%   packetFormat             - HE SU packet format
%   ruInfo                   - Resource unit allocation information
%   showAllocation           - Shows the RU allocation
%   transmitTime             - Time required to transmit a packet
%   getNumPostFECPaddingBits - Required number of post-FEC padding bits
%
%   wlanHESUConfig properties:
%
%   ChannelBandwidth     - Channel bandwidth 
%   ExtendedRange        - Enable extended range format
%   Upper106ToneRU       - Use only the higher frequency 106 tone RU
%   InactiveSubchannels  - Indicates punctured 20 MHz subchannels in an HE sounding NDP
%   NumTransmitAntennas  - Number of transmit antennas
%   PreHECyclicShifts    - Cyclic shift values for >8 transmit chains
%   NumSpaceTimeStreams  - Number of space-time streams 
%   SpatialMapping       - Spatial mapping scheme
%   SpatialMappingMatrix - Spatial mapping matrix
%   Beamforming          - Enable beamforming
%   PreHESpatialMapping  - Indicate spatial mapping of pre-HE-STF portion
%   STBC                 - Enable space-time block coding
%   MCS                  - Modulation and coding scheme
%   DCM                  - Enable dual coded modulation for HE-Data field
%   ChannelCoding        - Channel coding type
%   APEPLength           - APEP length
%   GuardInterval        - Guard interval type
%   HELTFType            - Indicate HE-LTF compression mode
%   UplinkIndication     - Indicate if the PPDU is sent on the uplink
%   BSSColor             - Basic service set (BSS) color identifier 
%   SpatialReuse         - Spatial reuse indication
%   TXOPDuration         - Duration information for TXOP protection
%   HighDoppler          - High Doppler mode indication
%   MidamblePeriodicity  - Midamble periodicity in number of OFDM symbols
%   NominalPacketPadding - Nominal packet padding in microseconds
%   PostFECPaddingSource - Post-FEC padding bits source
%   PostFECPaddingSeed   - Initial random post-FEC padding bits seed
%   PostFECPaddingBits   - Post-FEC padding bits

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

properties (Access = 'public')
    %ChannelBandwidth Channel bandwidth (MHz) of PPDU transmission
    %   Specify the channel bandwidth as one of 'CBW20' | 'CBW40' | 'CBW80'
    %   | 'CBW160'. The extended range single user configuration only
    %   support 'CBW20'. The default value of this property is 'CBW20'.
    ChannelBandwidth = 'CBW20';
    %ExtendedRange Indicates HE SU or HE extended range SU format
    %   Set this property to true to generate the HE extended range single
    %   user format packet. This property applies when you set the
    %   ChannelBandwidth property to 'CBW20'. The default value of this
    %   property is false which generates an HE SU format packet.
    ExtendedRange (1,1) logical = false;
    %Upper106ToneRU Indicates the higher frequency 106-tone RU 
    %   Set this property to true to indicate only the higher frequency 106
    %   tone resource unit (RU) within the primary 20-MHz channel bandwidth
    %   of an extended range single user transmission is used. This
    %   property applies when you set the ChannelBandwidth property to
    %   'CBW20' and the ExtendedRange property to true. The default value
    %   of this property is false.
    Upper106ToneRU (1,1) logical = false;
    %InactiveSubchannels Indicates punctured 20 MHz subchannels in an HE sounding NDP
    %   Specify inactive 20 MHz subchannels in a sounding null data packet
    %   (NDP) as a logical vector. The number of elements must be 1 or
    %   equal to the number of 20 MHz subchannels given ChannelBandwidth.
    %   Set an element to true if a 20 MHz subchannel is inactive
    %   (punctured). Subchannels are ordered from lowest to highest
    %   absolute frequency. If a scalar is provided, this value is assumed
    %   for all subchannels. This property applies only when APEPLength is
    %   0 and ChannelBandwidth is 'CBW80' or 'CBW160'. At least one
    %   subchannel must be active. The default value for this property is
    %   false.
    InactiveSubchannels logical = false;
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as a numeric, positive
    %   integer scalar. The default is 1.
    NumTransmitAntennas (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(NumTransmitAntennas,1)} = 1;
    %PreHECyclicShifts Cyclic shift values for >8 transmit chains
    %   Specify the cyclic shift values for the pre-HE portion of the
    %   waveform, in nanoseconds for >8 transmit antennas as a row vector
    %   of length L = NumTransmitAntennas-8. The cyclic shift values must
    %   be between -200 and 0 inclusive. The first 8 antennas use the
    %   cyclic shift values defined in Table 21-10 of IEEE Std 802.11-2020.
    %   The remaining antennas use the cyclic shift values defined in this
    %   property. If the length of this row vector is specified as a value
    %   greater than L the object only uses the first L, PreHECyclicShifts
    %   values. For example, if you specify the NumTransmitAntennas
    %   property as 16 and this property as a row vector of length N>L, the
    %   object only uses the first L = 16-8 = 8 entries. This property
    %   applies only when you set the NumTransmitAntennas property to a
    %   value greater than 8 and PreHESpatialMapping to false. The default
    %   value of this property is -75.
    PreHECyclicShifts {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(PreHECyclicShifts,-200), mustBeLessThanOrEqual(PreHECyclicShifts,0)} = -75;
    %NumSpaceTimeStreams Number of space-time streams
    %   Specify the number of space-time streams as integer scalar between
    %   1 and 8, inclusive. The default value of this property is 1.
    NumSpaceTimeStreams (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(NumSpaceTimeStreams,1), mustBeLessThanOrEqual(NumSpaceTimeStreams,8)} = 1;
    %SpatialMapping Spatial mapping scheme
    %   Specify the spatial mapping scheme as one of 'Direct' | 'Hadamard'
    %   | 'Fourier' | 'Custom'. The default value of this property is
    %   'Direct', which applies when NumSpaceTimeStreams is equal to
    %   NumTransmitAntennas.
    SpatialMapping = 'Direct';
    %SpatialMappingMatrix Spatial mapping matrix(ces)
    %   Specify the spatial mapping matrix(ces) as a real or complex, 2D
    %   matrix or 3D array. This property applies when you set the
    %   SpatialMapping property to 'Custom'. It can be of size Nsts-by-Nt,
    %   where Nsts is the NumSpaceTimeStreams property and Nt is the
    %   NumTransmitAntennas property. In this case, the spatial mapping
    %   matrix applies to all the subcarriers. Alternatively, it can be of
    %   size Nst-by-Nsts-Nt, where Nst is the number of occupied
    %   subcarriers determined by the ChannelBandwidth property.
    %   Specifically, Nst is 242 for 'CBW20', 484 for 'CBW40', 996 for
    %   'CBW80' and 1992 (2x996) for 'CBW160'. In this case, each occupied
    %   subcarrier can have its own spatial mapping matrix. In either 2D or
    %   3D case, the spatial mapping matrix for each subcarrier is
    %   normalized. The default value of this property is 1.
    SpatialMappingMatrix {wlan.internal.heValidateSpatialMappingMatrix} = 1;
    %Beamforming  Enable beamforming
    %   Set this property to false when the specified SpatialMappingMatrix
    %   property is not a beamforming steering matrix. This property
    %   applies only when SpatialMapping property is set to 'Custom'. The
    %   default value is true.
    Beamforming (1,1) logical = true; 
    %PreHESpatialMapping Indicate the spatial mapping of pre-HE-STF portion 
    %   Set this property to true to spatially map the pre-HE-STF portion
    %   of the PPDU the same way as the first symbol of the HE-LTF field on
    %   each tone. Set to false to apply no spatial mapping to the
    %   pre-HE-STF portion of the PPDU. The default value of this property
    %   is false.
    PreHESpatialMapping (1,1) logical = false;
    %STBC Enable space-time block coding
    %   Set this property to true to enable space-time block coding (STBC)
    %   in the data field transmission. STBC can only be applied for two
    %   space-time streams and when DCM is not used. The default value of
    %   this property is false.
    STBC (1,1) logical = false; 
    %MCS Modulation and coding scheme 
    %   Specify the modulation and coding scheme as an integer scalar. Its
    %   elements must be integers between 0 and 11, inclusive. The default
    %   value of this property is 0.
    MCS (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(MCS,0), mustBeLessThanOrEqual(MCS,11)} = 0;
    %DCM Enable dual coded modulation for HE-Data field
    %   Set this property to true to indicate that dual carrier modulation
    %   (DCM) is used for the HE-Data field. DCM can only be used with MCS
    %   0, 1, 3, 4, when STBC is not used and when the number of space-time
    %   streams is less than or equal to 2. The default value of this
    %   property is false.
    DCM (1,1) logical = false;
    %ChannelCoding Forward error correction coding type
    %   Specify the channel coding as one of 'BCC' or 'LDPC' to indicate
    %   binary convolution coding (BCC) or low-density-parity-check (LDPC)
    %   coding. The default is 'LDPC'.  
    ChannelCoding = 'LDPC';
    %APEPLength APEP length
    %   Specify the APEP length in bytes as an integer scalar between 1 and
    %   6500631, inclusive. In addition, this property can be 0, which
    %   implies an HE non-data-packet (NDP). The default value of this
    %   property is 100.
    APEPLength (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(APEPLength,0), mustBeLessThanOrEqual(APEPLength,6500631)} = 100;
    %GuardInterval Guard interval type
    %   Specify the guard interval (cyclic prefix) length in Microseconds
    %   as one of 0.8, 1.6 or 3.2. The default is 3.2.
    GuardInterval {wlan.internal.heValidateGI(GuardInterval)} = 3.2;
    %HELTFType Indicate HE-LTF compression mode of HE PPDU
    %   Specify the HE-LTF compression type as one of 1, 2, or 4,
    %   corresponding to 1xHE-LTF, 2xHE-LTF and 4xHE-LTF modes
    %   respectively. The default is 4.
    HELTFType (1,1) {mustBeNumeric, mustBeMember(HELTFType,[1 2 4])} = 4;
    %UplinkIndication Indicates if the PPDU is sent on an uplink transmission
    %   Set this property to true to indicate that the PPDU is sent on an
    %   uplink transmission. The default value of this property is false
    %   which indicates a downlink transmission.
    UplinkIndication (1,1) logical = false;
    %BSSColor Basic service set (BSS) color identifier 
    %   Specify the BSS color number of a basic service set as an integer
    %   scalar between 0 to 63, inclusive. The default is 0.
    BSSColor (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(BSSColor,0), mustBeLessThanOrEqual(BSSColor,63)} = 0;
    %SpatialReuse Spatial reuse indication
    %   Specify the SpatialReuse as an integer scalar between 0 and 15,
    %   inclusive. The default is 0.
    SpatialReuse (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(SpatialReuse,0), mustBeLessThanOrEqual(SpatialReuse,15)} = 0;
    %TXOPDuration Duration information for TXOP protection
    %   Specify the TXOPDuration signaled in HE-SIG-A as an integer scalar
    %   between 0 and 127, inclusive. The TXOP field in HE-SIG-A is set
    %   directly to TXOPDuration, therefore a duration in microseconds must
    %   be converted before being used as specified in Table 27-18 of IEEE
    %   Std 802.11ax-2021. For more information see the documentation.
    TXOPDuration (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(TXOPDuration,0), mustBeLessThanOrEqual(TXOPDuration,127)} = 127;
    %HighDoppler High Doppler mode indication
    %   Set this property to true to indicate high doppler in HE-SIG-A. The
    %   default value of this property is false.
    HighDoppler (1,1) logical = false;
    %MidamblePeriodicity Midamble periodicity in number of OFDM symbols
    %   Specify HE-Data field midamble periodicity as 10 or 20 OFDM
    %   symbols. This property applies only when HighDoppler property is
    %   set to true. The default is 10.
    MidamblePeriodicity (1,1) {mustBeNumeric, mustBeMember(MidamblePeriodicity,[10 20])} = 10;
    %NominalPacketPadding Nominal packet padding in microseconds
    %   Specify nominal packet padding as 0, 8 or 16. The nominal packet
    %   padding and the pre-FEC padding factor are used to calculate the
    %   duration of packet extension field as defined in Table 27-46 of
    %   IEEE Std 802.11ax-2021. The default is 0. The duration of packet
    %   extension field for NDP is 4 microseconds, independent of nominal
    %   packet padding parameter.
    NominalPacketPadding (1,1) {mustBeNumeric, mustBeMember(NominalPacketPadding,[0 8 16])} = 0;
    %PostFECPaddingSource Post-FEC padding bit source
    %   Specify the source of post-FEC padding bits for the waveform
    %   generator as 'mt19937ar with seed', 'Global stream', or
    %   'User-defined'. To use the mt19937ar random number generator
    %   algorithm with a seed to generate normally distributed random bits,
    %   set this property to 'mt19937ar with seed'. The mt19937ar algorithm
    %   uses the seed specified by the value of the PostFECPaddingSeed
    %   property. To use the current global random number stream to
    %   generate normally distributed random bits, set this property to
    %   'Global stream'. To use bits specified in the PostFECPaddingBits
    %   property, set this property to 'User-defined'. The default
    %   value of this property is 'mt19937ar with seed'.
    PostFECPaddingSource = 'mt19937ar with seed';
    %PostFECPaddingSeed Initial random post-FEC padding bits seed
    %   Specify the initial seed of the mt19937ar random number generator
    %   algorithm as a nonnegative integer. This property applies when you
    %   set the PostFECPaddingSource property to 'mt19937ar with seed'. The
    %   default value of this property is 73.
    PostFECPaddingSeed (1,1) {mustBeNumeric, mustBeInteger, mustBeNonnegative} = 73;
    %PostFECPaddingBits Post-FEC padding bits
    %   Specify post-FEC padding bits as an int8, double, or single typed
    %   binary column vector. For C code generation this property must be
    %   int8 typed. The waveform generator loops the vector if the number
    %   of bits required exceeds the length of the vector provided. The
    %   number of bits the waveform generator uses from the vector is given
    %   by the getNumPostFECPaddingBits object function. The default value 
    %   of this property is 0.
    PostFECPaddingBits (:,1) {wlan.internal.validateBits(PostFECPaddingBits,'PostFECPaddingBits')} = int8(0);
end

properties(Constant, Hidden)
    ChannelBandwidth_Values = {'CBW20','CBW40','CBW80','CBW160'};
    SpatialMapping_Values   = {'Direct','Hadamard','Fourier','Custom'};
    ChannelCoding_Values    = {'BCC','LDPC'};
    PostFECPaddingSource_Values = {'mt19937ar with seed','Global stream','User-defined'};
end
    
methods
    function obj = wlanHESUConfig(varargin)
       % For codegen set maximum dimensions to force varsize
       if ~isempty(coder.target)
            channelBandwidth = 'CBW20';
            coder.varsize('channelBandwidth',[1 6],[0 1]); % Add variable-size support
            obj.ChannelBandwidth = channelBandwidth; % Default

            spatialMapping = 'Direct';
            coder.varsize('spatialMapping',[1 8],[0 1]); % Add variable-size support
            obj.SpatialMapping = spatialMapping; % Default

            channelCoding = 'LDPC';
            coder.varsize('channelCoding',[1 4],[0 1]); % Add variable-size support
            obj.ChannelCoding = channelCoding; % Default

            postFECPaddingSource = 'mt19937ar with seed';
            coder.varsize('postFECPaddingSource',[1 19],[0 1]); % Add variable-size support
            obj.PostFECPaddingSource = postFECPaddingSource; % Default

            postFECPaddingBits = int8(0);
            coder.varsize('postFECPaddingBits',[1920*10*8 1],[1 0]); % Add variable-size support (NCBPS = NSD*NBPSCS*NSS)
            obj.PostFECPaddingBits = postFECPaddingBits; % Default
       end
       obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
    end
    
    function obj = set.ChannelBandwidth(obj,val)
        val = validateEnumProperties(obj,'ChannelBandwidth',val);
        obj.ChannelBandwidth = val;
    end
    
    function obj = set.SpatialMapping(obj,val)
        val = validateEnumProperties(obj,'SpatialMapping',val);
        obj.SpatialMapping = val;
    end
    
    function obj = set.ChannelCoding(obj,val)
        val = validateEnumProperties(obj,'ChannelCoding',val);
        obj.ChannelCoding = val;
    end
    
    function obj = set.PostFECPaddingSource(obj,val)
        val = validateEnumProperties(obj,'PostFECPaddingSource',val);
        obj.PostFECPaddingSource = val;
    end
    
    function s = ruInfo(obj)
    %ruInfo Returns information relevant to the resource unit
    %   S = ruInfo(cfgHE) returns a structure, S, containing the resource
    %   unit (RU) allocation information for the wlanHESUConfig object,
    %   cfgHE. The output structure S has the following fields:
    %
    %   NumUsers                 - Number of users (1)
    %   NumRUs                   - Number of RUs (1)
    %   RUIndices                - Index of the RU (1 or 2)
    %   RUSizes                  - Size of the RU
    %   NumUsersPerRU            - Number of users per RU (1)
    %   NumSpaceTimeStreamsPerRU - Total number of space-time streams
    %   PowerBoostFactorPerRU    - Power boost factor (1)
    %   RUNumbers                - RU number (1)
    %   RUAssigned               - Indicate assigned RU (1)
        
        if strcmp(packetFormat(obj),'HE-EXT-SU') && (obj.Upper106ToneRU==true)
            % Hardwire RU info if Upper106ToneRU is used in extended range
            ruIndices = 2;
            ruSizes = 106;
        else
            ruIndices = 1;
            ruSizes = wlan.internal.heFullBandRUSize(obj.ChannelBandwidth);
        end
        s = struct;
        s.NumUsers = 1;
        s.NumRUs = 1;
        s.RUIndices = ruIndices;
        s.RUSizes = ruSizes;
        s.NumUsersPerRU = 1;
        s.NumSpaceTimeStreamsPerRU = obj.NumSpaceTimeStreams;
        s.PowerBoostFactorPerRU = 1;
        s.RUNumbers = 1;
        s.RUAssigned = true;
    end
    
    function psduLength = getPSDULength(obj)
    %getPSDULength Returns PSDU length for the configuration
    %   Returns the PSDU length for a single user and extended range
    %   single user configuration. IEEE Std 802.11ax-2021, Section 27.4.3.
        
        if obj.APEPLength == 0
            psduLength = 0; % NDP
        else
            psduLength = wlan.internal.hePLMETxTimePrimative(obj);
            psduLength = psduLength(1); % For codegen (always scalar for HE SU)
        end
    end
    
    function n = getNumPostFECPaddingBits(obj)
    %getNumPostFECPaddingBits Required number of post-FEC padding bits
    %   Returns the required number of post-FEC padding bits.
        [~,userCodingParams] = wlan.internal.heCodingParameters(obj);
        n = userCodingParams.NPADPostFEC*userCodingParams.mSTBC;
    end
    
    function format = packetFormat(obj)
    %packetFormat Returns the packet format
    %   Returns the packet format as a character vector, based on the
    %   current configuration. Packet format is one of 'HE-EXT-SU', or
    %   'HE-SU'.
    
        if strcmp(obj.ChannelBandwidth,'CBW20') && obj.ExtendedRange==true
            format = 'HE-EXT-SU';
        else
            format = 'HE-SU';
        end
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
        [~,t] = wlan.internal.hePLMETxTimePrimative(obj);
        t = t*1e-3; % Scale from nanoseconds to microseconds
        t = wlan.internal.convertTransmitTime(t,varargin{:});

    end
    
    function varargout = validateConfig(obj,varargin)
    %validateConfig Validate the dependent properties of wlanHESUConfig object
    %   validateConfig(obj) validates the dependent properties for the
    %   specified wlanHESUConfig configuration object.
    % 
    %   For INTERNAL use only, subject to future changes
    %
    %   validateConfig(CFG, MODE) validates only the subset of dependent
    %   properties as specified by the MODE input. MODE must be one of:
    %       'DataLocationLength'
    %       'HELTFGI'
    %       'Coding'
    %       'Full'

        narginchk(1,2);
        nargoutchk(0,1);
        if (nargin==2)
            mode = varargin{1};
        else
            mode = 'Full';
        end

        switch mode
            case 'HELTFGI'    % wlanFieldIndices (HE-LTF)
                validateHELTFGI(obj);
            case 'DataLocationLength'  % wlanFieldIndices (HE-Data and HE-LTF)
                s = validateMCSLengthTxTime(obj);
            case 'Coding'  % wlanHEDataBitRecover
                validateCoding(obj);
            case 'CyclicShift'
                % Validate PreHECyclicShifts against NumTransmitAntennas
                validatePreHECyclicShifts(obj);
            otherwise % wlanWaveformGenerator
                % Full object validation

                % Validate Spatial mapping properties and spatial mapping matrix 
                validateSpatialMapping(obj)
                
                % Validate InactiveSubchannels
                validateInactiveSubchannels(obj);

                % Validate PreHECyclicShifts against NumTransmitAntennas
                validatePreHECyclicShifts(obj);

                % Validate MCS and length
                s = validateMCSLengthTxTime(obj);
        end

        if nargout == 1
            varargout{1} = s;
        end
    end
    
    function showAllocation(obj,varargin)
    %showAllocation Shows the RU allocation
    %   showAllocation(cfgHE) shows the RU allocation for an HE SU and HE ER SU format
    %
    %   showAllocation(cfgHE,AX) shows the allocation in the axes specified
    %   by AX instead of in the current axes. If AX is not
    %   specified, showAllocation plots the allocation in a new figure.

        validateInactiveSubchannels(obj);
        wlan.internal.hePlotAllocation(obj,varargin{:});
    end
  end

  methods (Access = private)
    function validateCoding(obj)
    %   validateCoding Coding properties for wlanHESUConfig
    %   configuration object
    %   Validated property-subset includes:   
    %     MCS, DCM, STBC, ChannelBandwidth, ExtendedRange, Upper106ToneRU,
    %     NumSpaceTimeStreams
       
        % Validate MCS, DCM and STBC 
        coder.internal.errorIf(obj.DCM && (~any(obj.MCS==[0 1 3 4]) || obj.STBC || obj.NumSpaceTimeStreams>2),'wlan:he:InvalidDCM');
        
        % Validate extended range
        if strcmp(obj.ChannelBandwidth,'CBW20') && obj.ExtendedRange
          % For extended range validate MCS range
          if obj.Upper106ToneRU==true
              % For extended range operation 106 only MCS0 is valid
              coder.internal.errorIf(~obj.MCS==0,'wlan:he:InvalidExtRangeMCS106RU');
          else
              % For extended range operation 242 only MCS0,1,2 is valid
              coder.internal.errorIf(~any(obj.MCS==[0 1 2]),'wlan:he:InvalidExtRangeMCS242RU');
          end
        end
        
        % Validate STBC and NumSpaceTimeStreams
        coder.internal.errorIf(obj.STBC && obj.NumSpaceTimeStreams~=2,'wlan:he:InvalidNumSTSWithSTBC');
                
        % Validate BCC coding
        S = obj.ruInfo;
        if strcmp(obj.ChannelCoding,'BCC')
            coder.internal.errorIf(~strcmp(obj.ChannelBandwidth,'CBW20') || S.RUSizes>242,'wlan:shared:InvalidBCCRUSize');
            coder.internal.errorIf(obj.NumSpaceTimeStreams>4,'wlan:shared:InvalidNSTS');
            coder.internal.errorIf(any(obj.MCS==[10 11]),'wlan:he:InvalidMCS');
        end
    end

    function s = validateMCSLength(obj)
    %   validateMCSLength Length properties for wlanHESUConfig
    %   configuration object
    %   Validated property-subset includes:   
    %     ChannelBandwidth, NumUsers, NumSpaceTimeStreams, STBC, MCS,
    %     ChannelCoding, GuardInterval, APEPLength
    
        % Validate HELTFType and GuardInterval for HE-LTF
        validateHELTFGI(obj);
        
        % Validate coding related properties
        validateCoding(obj);

        [psduLength,txTime,commonCodingParams] = wlan.internal.hePLMETxTimePrimative(obj);
        sf = 1e3; % Scaling factor to convert time from ns to us
        % Set output structure
        s = struct( ...
            'NumDataSymbols', commonCodingParams.NSYM, ... 
            'TxTime', txTime/sf, ...% TxTime in us
            'PSDULength', psduLength);
    end

    function s = validateMCSLengthTxTime(obj)
        %   validateMCSLength Calculate length properties and resultant
        %   TxTime for wlanHESUConfig configuration object
        %   Validated property-subset includes:
        %     ChannelBandwidth, NumUsers, NumSpaceTimeStreams, STBC, MCS,
        %     ChannelCoding, GuardInterval, APEPLength

        s = validateMCSLength(obj);

        % Validate TxTime (max 5.484ms for HE SU format)
        coder.internal.errorIf(s.TxTime>5484,'wlan:shared:InvalidPPDUDuration',round(s.TxTime),5484);
    end

    function validateSpatialMapping(obj)
        %validateSpatialMapping Validate the spatial mapping properties 
        %   Validated property-subset includes:
        %     ChannelBandwidth, NumTransmitAntennas, NumSpaceTimeStreams,
        %     SpatialMapping, SpatialMappingMatrix

        validateSpatial(obj);

        if strcmp(obj.SpatialMapping,'Custom')
            % Validate spatial mapping matrix
            switch obj.ChannelBandwidth
                case 'CBW20'
                    if obj.ExtendedRange && obj.Upper106ToneRU && ~obj.PreHESpatialMapping
                        numST = 106;
                    else
                        numST = 242;
                    end
                case 'CBW40'
                    numST = 484;
                case 'CBW80'
                    numST = 996;
                otherwise
                    numST = 1992;
            end
            wlan.internal.validateSpatialMappingMatrix(obj.SpatialMappingMatrix,obj.NumTransmitAntennas,obj.NumSpaceTimeStreams,numST);
        end
    end
    
    function validateSTSTx(obj)
    %ValidateSTSTx Validate the spatial properties of wlanHESUConfig object
    %   Validated property-subset includes:
    %       NumTransmitAntennas, NumSpaceTimeStreams, ExtendedRange

        % NumTx and Nsts: numTx cannot be less than Nsts
        coder.internal.errorIf(obj.NumTransmitAntennas < obj.NumSpaceTimeStreams,'wlan:he:NumSTSLargerThanNumTx',1,obj.NumSpaceTimeStreams,obj.NumTransmitAntennas);

        % Nsts and HE ER SU: Nsts must be 1 or 2 for HE ER SU
        coder.internal.errorIf(obj.ExtendedRange && obj.NumSpaceTimeStreams>2,'wlan:he:InvalidExtRangeNSTS');
    end

    function validateSpatial(obj)
    %validateSpatial Validate the spatial properties of wlanHESUConfig object
    %   Validated property-subset includes:
    %     NumTransmitAntennas, NumSpaceTimeStreams, SpatialMapping

        validateSTSTx(obj);
        coder.internal.errorIf(strcmp(obj.SpatialMapping, 'Direct') && (obj.NumSpaceTimeStreams ~= obj.NumTransmitAntennas),'wlan:he:NumSTSNotEqualNumTxDirectMap',1,obj.NumSpaceTimeStreams,obj.NumTransmitAntennas);            
    end
    
    function validateHELTFGI(obj)
    %validateHELTFGI Validate the HELTF type and GuardInterval of wlanHESUConfig object
    %   Validated property-subset includes:
    %     HELTFType, GuardInterval, DCM, STBC, HighDoppler
    
        switch obj.GuardInterval
            case 0.8
                if obj.HELTFType==4
                   coder.internal.errorIf((obj.DCM | obj.STBC),'wlan:he:SUInvalidGILTF4',feval('sprintf','%1.1f',obj.GuardInterval),obj.HELTFType);
                end
            case 1.6
                coder.internal.errorIf(~(obj.HELTFType==2),'wlan:shared:InvalidGILTF',feval('sprintf','%1.1f',obj.GuardInterval),'HELTFType',obj.HELTFType);
            otherwise % 3.2
                coder.internal.errorIf(~(obj.HELTFType==4),'wlan:shared:InvalidGILTF',feval('sprintf','%1.1f',obj.GuardInterval),'HELTFType',obj.HELTFType);
        end

        % Validate HighDoppler
        coder.internal.errorIf(obj.HighDoppler && obj.NumSpaceTimeStreams>4,'wlan:he:InvalidHighDoppler');
    end
    
    function validateInactiveSubchannels(obj)
    %validateInactiveSubchannels Validate InactiveSubchannels of wlanHESUConfig object
    %   Validated property-subset includes:
    %     APEPLength, ChannelBandwidth, InactiveSubchannels
    
        if ~isInactiveProperty(obj,'InactiveSubchannels')
            % Puncturing is only applicable for HE SU NDP
            wlan.internal.validateInactiveSubchannels(obj);
        end
    end
    
    function validatePreHECyclicShifts(obj)
    %   validatePreHECyclicShifts Validate PreHECyclicShifts values against
    %   NumTransmitAntennas
    %   Validated property-subset includes:
    %     PreHECyclicShifts, NumTransmitAntennas, PreHESpatialMapping 

        if ~isInactiveProperty(obj,'PreHECyclicShifts')
            coder.internal.errorIf(numel(obj.PreHECyclicShifts)<obj.NumTransmitAntennas-8,'wlan:shared:InvalidCyclicShift','PreHECyclicShifts',obj.NumTransmitAntennas-8);
        end
    end
  end
       
methods (Access = protected)
    function flag = isInactiveProperty(obj, prop)
        switch prop
            case 'ExtendedRange'
                % Hide ExtendedRange unless 'CBW20'
                flag = ~(strcmp(obj.ChannelBandwidth,'CBW20'));
            case 'Upper106ToneRU'
                % Hide Upper106ToneRU unless extended range SU
                flag = ~(strcmp(packetFormat(obj),'HE-EXT-SU'));
            case 'Beamforming'
                % Hide Beamforming unless spatial mapping is Custom
                flag = ~(strcmp(obj.SpatialMapping,'Custom'));
            case 'SpatialMappingMatrix'
                % Hide SpatialMappingMatrix when SpatialMapping is not Custom
                flag = ~strcmp(obj.SpatialMapping,'Custom');
            case 'MidamblePeriodicity'
                % Hide MidamblePeriodicity when HighDoppler is not set
                flag = obj.HighDoppler == false;
            case 'NominalPacketPadding'
                % Hide NominalPacketPadding when NDP
                flag = obj.APEPLength == 0;
            case 'InactiveSubchannels'
                % Hide InactiveSubchannels for non-NDP packet when ChannelBandwidth is CBW20 and CBW40
                flag = ~((obj.APEPLength == 0) && any(strcmp(obj.ChannelBandwidth,{'CBW80','CBW160'})));
            case 'PreHECyclicShifts'
                % Hide PreHECyclicShifts when NumTransmitAntennas <=8 or pre-HE
                % spatial mapping is used
                flag = obj.NumTransmitAntennas <= 8 || obj.PreHESpatialMapping == true;
            case 'PostFECPaddingSource'
                % Hide when NDP
                flag = obj.APEPLength == 0;
            case 'PostFECPaddingSeed'
                % Hide when PostFECPaddingSource is not 'mt19937ar with
                % seed' or NDP
                flag = ~strcmp(obj.PostFECPaddingSource,'mt19937ar with seed') || obj.APEPLength == 0;
            case 'PostFECPaddingBits'
                %  Hide when PostFECPaddingSource is not 'User-defined' or
                %  NDP
                flag = ~strcmp(obj.PostFECPaddingSource,'User-defined') || obj.APEPLength == 0;
            otherwise
                flag = false;
        end
    end
end
    
end
