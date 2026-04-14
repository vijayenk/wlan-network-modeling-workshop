classdef wlanEHTUser < comm.internal.ConfigBase
%wlanEHTUser User properties within each RU
%   CFGUSER = wlanEHTUser(RUNUMBER) creates a user configuration object.
%   This object contains the properties of a user within an EHT RU.
%   RUNUMBER is an integer specifying the 1-based index of the resource
%   unit (RU) the user is transmitted on.
%
%   CFGUSER = wlanEHTUser(...,Name,Value) creates an object, CFGUSER, that
%   holds the properties for the users within an RU. The specified property
%   Name is set to the specified value. You can specify additional
%   name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanEHTUser objects are used to parameterize users within an EHT MU
%   transmission, and therefore are part of the wlanEHTMUConfig object.
%                     
%   wlanEHTUser properties:
%
%   APEPLength            - APEP length per user
%   MCS                   - Modulation and coding scheme
%   NumSpaceTimeStreams   - Number of space-time streams
%   ChannelCoding         - Forward error correction coding type
%   STAID                 - Station identification
%   RUNumber              - Index of RU used to transmit user
%   NominalPacketPadding  - Specify Nominal Packet Padding in microseconds
%   PostFECPaddingSource  - Post-FEC padding bits source
%   PostFECPaddingSeed    - Initial random post-FEC padding bits seed
%   PostFECPaddingBits    - Post-FEC padding bits

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

properties
    %APEPLength APEP length per user: 
    %   Specify the APEP length in bytes as an integer scalar between 0 and
    %   15523198, inclusive. The default value of this property is 100.
    APEPLength (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(APEPLength,0),mustBeLessThanOrEqual(APEPLength,15523198)} = 100;
    %MCS Modulation and coding scheme per user
    %   Specify the modulation and coding scheme as an integer scalar
    %   between 0 and 13, inclusive or 15 (BPSK-DCM). To specify EHT DUP
    %   mode (MCS 14), set the name-value pair 'EHTDUPMode' of
    %   wlanEHTMUConfig object. The default value of this property is 0.
    MCS (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(MCS,0),mustBeLessThanOrEqual(MCS,15)} = 0;
    %NumSpaceTimeStreams  Number of space-time streams per user
    %   Specify the number of space-time streams as integer scalar between
    %   1 and 8, inclusive. The maximum number of space-time streams for
    %   each user within a MU-MIMO RU is between 1 and 4 (inclusive) and
    %   depends on the user number, total number of users and total number
    %   of space-time streams as per IEEE P802.11be/D5.0, Table 36-42.
    %   The default value of this property is 1.
    NumSpaceTimeStreams (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumSpaceTimeStreams,1),mustBeLessThanOrEqual(NumSpaceTimeStreams,8)} = 1;
    %ChannelCoding Forward error correction coding type
    %   Specify the channel coding as one of 'bcc' or 'ldpc' to indicate
    %   binary convolution coding (BCC) or low-density-parity-check (LDPC)
    %   coding. The default is 'ldpc'.
    ChannelCoding (1,1) wlan.type.ChannelCoding = wlan.type.ChannelCoding.ldpc;
    % STAID Station identification 
    %   The STAID refer to the association identifier (AID) field as an
    %   integer between 0 and 2047. The STAID is defined in IEEE
    %   P802.11be/D5.0, Section 36.3.12.8.5. The 11 LSBs of the AID field
    %   are used to address the STA. When STAID is set to 2046 the
    %   associated RU carries no data. When you create a wlanEHTMUConfig
    %   object, the default value of this property in each wlanEHTUser
    %   object is unique starting from 0 and incrementing by 1. Otherwise,
    %   the default value of this property is 0.
    STAID (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(STAID,0),mustBeLessThanOrEqual(STAID,2047)} = 0;
    %NominalPacketPadding Nominal packet padding in microseconds
    %   Specify nominal packet padding as 0, 8, 16, or 20. The nominal
    %   packet padding and the pre-FEC padding factor are used to calculate
    %   the duration of packet extension field as defined in IEEE
    %   P802.11be/D5.0, Table 36-61. The default is 0.
    NominalPacketPadding (1,1) {mustBeNumeric,mustBeMember(NominalPacketPadding,[0 8 16 20])} = 0;
    %PostFECPaddingSource Post-FEC padding bit source
    %   Specify the source of post-FEC padding bits for the waveform
    %   generator as 'mt19937arwithseed', 'globalstream', or
    %   'userdefined'. To use the mt19937ar random number generator
    %   algorithm with a seed to generate normally distributed random bits,
    %   set this property to 'mt19937arwithseed'. The mt19937ar algorithm
    %   uses the seed specified by the value of the PostFECPaddingSeed
    %   property. To use the current global random number stream to
    %   generate normally distributed random bits, set this property to
    %   'globalstream'. To use bits specified in the PostFECPaddingBits
    %   property, set this property to 'userdefined'. The default
    %   value of this property is 'mt19937arwithseed'.
    PostFECPaddingSource (1,1) wlan.type.PostFECPaddingSource = wlan.type.PostFECPaddingSource.mt19937arwithseed;
    %PostFECPaddingSeed Initial random post-FEC padding bit seed
    %   Specify the initial seed of the mt19937ar random number generator
    %   algorithm as a nonnegative integer. This property applies when you
    %   set the PostFECPaddingSource property to 'mt19937arwithseed'
    %   in wlanEHTUser object, the default value of this property in each
    %   wlanEHTUser object is the user number. Otherwise, the default value
    %   of this property is 73.
    PostFECPaddingSeed (1,1) {mustBeNumeric,mustBeInteger,mustBeNonnegative} = 73;
    %PostFECPaddingBits Post-FEC padding bits
    %   Specify post-FEC padding bits as an int8, double, or single typed
    %   binary column vector. The waveform generator loops the vector if
    %   the number of bits required exceeds the length of the vector
    %   provided. The number of bits the waveform generator uses from the
    %   vector is given by the numPostFECPaddingBits object function
    %   of wlanEHTMUConfig. The default value of this property is 0.
    PostFECPaddingBits (:,1) {wlan.internal.validateBits(PostFECPaddingBits,'PostFECPaddingBits')} = int8(0);
end

properties (SetAccess=private)
    % RUNumber RU number
    %   RUNumber is the 1-based index of the RU which the user is 
    %   transmitted on. This number is used to index the appropriate RU
    %   objects within wlanEHTMUConfig.
    RUNumber = 1;
end

methods
    function obj = wlanEHTUser(ruNumber,varargin)
        % For codegen set different dimensions to make sure varsize
        if ~isempty(coder.target)
            postFECPaddingBits = int8(0);
            coder.varsize('postFECPaddingBits',[3920*12*8 1],[1 0]); % Add variable-size support (NCBPS = NSD*NBPSCS*NSS)
            obj.PostFECPaddingBits = postFECPaddingBits; % Default
        end
        obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
        obj.RUNumber = ruNumber;
    end
end

methods (Access = protected)
    function flag = isInactiveProperty(obj,prop)
        switch prop
            case 'PostFECPaddingSeed'
                flag = obj.PostFECPaddingSource~=wlan.type.PostFECPaddingSource.mt19937arwithseed;
            case 'PostFECPaddingBits'
                flag = obj.PostFECPaddingSource~=wlan.type.PostFECPaddingSource.userdefined;
            otherwise
                flag = false;
        end
    end
end
end
