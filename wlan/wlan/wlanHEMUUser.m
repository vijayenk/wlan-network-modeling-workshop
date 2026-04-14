classdef wlanHEMUUser < comm.internal.ConfigBase
%wlanHEMUUser User properties within each RU
%   CFGUSER = wlanHEMUUser(RUNUMBER) creates a user configuration object.
%   This object contains the user properties of a user within an HE RU.
%   RUNUMBER is an integer specifying the 1-based index of the resource
%   unit (RU) the user is transmitted on. This number is used to index the
%   appropriate RU object within wlanHEMUConfig.
%
%   CFGUSER = wlanHEMUUser(...,Name,Value) creates an object that holds the
%   properties for the users within an RU, CFGUSER, with the specified
%   property Name set to the specified value. You can specify additional
%   name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanHEMUUser objects are used to parameterize users within an HE-MU
%   transmission, and therefore are part of the wlanHEMUConfig object.
%                     
%   wlanHEMUUser properties: 
%
%   APEPLength            - APEP length per user
%   MCS                   - Modulation and coding scheme
%   NumSpaceTimeStreams   - Number of space-time streams
%   DCM                   - Enable dual carrier modulation
%   ChannelCoding         - Forward error correction coding type
%   STAID                 - Station identification
%   RUNumber              - Index of RU used to transmit user
%   NominalPacketPadding  - Specify Nominal Packet Padding in microseconds
%   PostFECPaddingSource  - Post-FEC padding bits source
%   PostFECPaddingSeed    - Initial random post-FEC padding bits seed
%   PostFECPaddingBits    - Post-FEC padding bits

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

properties
    %APEPLength APEP length per user: 
    %   Specify the APEP length in bytes as an integer scalar between 1 and
    %   6451631, inclusive. The default value of this property is 100.
    APEPLength (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(APEPLength,1), mustBeLessThanOrEqual(APEPLength,6451631)} = 100;
    %MCS Modulation and coding scheme per user
    %   Specify the modulation and coding scheme as an integer scalar
    %   between 0 and 11, inclusive. The default value of this property is
    %   0.
    MCS (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(MCS,0), mustBeLessThanOrEqual(MCS,11)} = 0;
    %NumSpaceTimeStreams  Number of space-time streams per user
    %   Specify the number of space-time streams as integer scalar between
    %   1 and 8, inclusive. The maximum number of space-time streams for
    %   each user within a MU-MIMO RU is between 1 and 4 (inclusive) and
    %   depends on the user number, total number of users and total number
    %   of space-time streams as per IEEE Std 802.11ax-2021, Table 27-30.
    %   The default value of this property is 1.
    NumSpaceTimeStreams (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(NumSpaceTimeStreams,1), mustBeLessThanOrEqual(NumSpaceTimeStreams,8)} = 1;
    %DCM Enable dual coded modulation for HE-Data field
    %   Set this property to true to indicate that dual carrier modulation
    %   (DCM) is used for the HE-Data field. DCM can only be used with up
    %   to two space-time streams, and in a single-user RU. The default
    %   value of this property is false.
    DCM (1,1) logical = false;
    %ChannelCoding Forward error correction coding type
    %   Specify the channel coding as one of 'BCC' or 'LDPC' to indicate
    %   binary convolution coding (BCC) or low-density-parity-check (LDPC)
    %   coding. The default is 'LDPC'.
    ChannelCoding = 'LDPC';
    % STAID Station identification 
    %   The STAID refer to the association identifier (AID) field as an
    %   integer between 0 and 2047. The STAID is defined in IEEE
    %   Std 802.11ax-2021, Section 26.11.1. The 11 LSBs of the AID field are
    %   used to address the STA. When STAID is set to 2046 the associated
    %   RU carries no data. The default is 0.
    STAID (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(STAID,0), mustBeLessThanOrEqual(STAID,2047)} = 0;
    %NominalPacketPadding Nominal packet padding in microseconds
    %   Specify nominal packet padding as 0, 8 or 16. The nominal packet
    %   padding and the pre-FEC padding factor are used to calculate the
    %   duration of packet extension field as defined in IEEE
    %   Std 802.11ax-2021, Table 27-46. The default is 0.
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
    %PostFECPaddingSeed Initial random post-FEC padding bit seed
    %   Specify the initial seed of the mt19937ar random number generator
    %   algorithm as a nonnegative integer. This property applies when you
    %   set the PostFECPaddingSource property to 'mt19937ar with seed'.
    %   When you create a wlanHEMUConfig object, the default value of this
    %   property in each wlanHEMUUser object is the user number. Otherwise,
    %   the default value of this property is 73.
    PostFECPaddingSeed (1,1) {mustBeNumeric, mustBeInteger, mustBeNonnegative} = 73;
    %PostFECPaddingBits Post-FEC padding bits
    %   Specify post-FEC padding bits as an int8, double, or single typed
    %   binary column vector. For C code generation this property must be
    %   int8 typed. The waveform generator loops the vector if the number
    %   of bits required exceeds the length of the vector provided. The
    %   number of bits the waveform generator uses from the vector is given
    %   by the getNumPostFECPaddingBits object function of wlanHEMUConfig.
    %   The default value of this property is 0.
    PostFECPaddingBits (:,1) {wlan.internal.validateBits(PostFECPaddingBits,'PostFECPaddingBits')} = int8(0);
end

properties (SetAccess=private)
    % RUNumber RU number
    %   RUNumber is the 1-based index of the RU which the user is 
    %   transmitted on. This number is used to index the appropriate RU
    %   objects within wlanHEMUConfig.
    RUNumber = 1;
end

properties(Constant, Hidden)
    ChannelCoding_Values = {'BCC','LDPC'};
    PostFECPaddingSource_Values = {'mt19937ar with seed','Global stream','User-defined'};
end

methods
    function obj = wlanHEMUUser(ruNumber,varargin)
        % For codegen set maximum dimensions to force varsize
        if ~isempty(coder.target)
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
        obj.RUNumber = ruNumber;
    end
    
    function obj = set.ChannelCoding(obj,val)
        val = validateEnumProperties(obj,'ChannelCoding',val);
        obj.ChannelCoding = val;
    end
    
    function obj = set.PostFECPaddingSource(obj,val)
        val = validateEnumProperties(obj,'PostFECPaddingSource',val);
        obj.PostFECPaddingSource = val;
    end
end

methods (Access = protected)
    function flag = isInactiveProperty(obj,prop)
        switch prop
            case 'PostFECPaddingSeed'
                flag = ~strcmp(obj.PostFECPaddingSource,'mt19937ar with seed');
            case 'PostFECPaddingBits'
                flag = ~strcmp(obj.PostFECPaddingSource,'User-defined');
            otherwise
                flag = false;
        end
    end
end
end

