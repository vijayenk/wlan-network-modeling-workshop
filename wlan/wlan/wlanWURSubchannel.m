classdef wlanWURSubchannel < comm.internal.ConfigBase
%wlanWURSubchannel WUR 20 MHz subchannel properties
%   CFGSUBCH = wlanWURSubchannel creates a 20 MHz subchannel configuration
%   object. This object contains the 20 MHz subchannel properties for a
%   WUR packet.
%
%   CFGSUBCH = wlanWURSubchannel(Name,Value) creates an object that holds
%   the parameters for a 20 MHz subchannel, CFGSUBCH, with the specified
%   property Name set to the specified value. You can specify additional
%   name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   The wlanWURSubchannel object parameterizes 20 MHz subchannels within a
%   WUR packet, and therefore is part of the wlanWURConfig object.
%
%   wlanWURSubchannel properties:
%
%   DataRate      - Data rate
%   PSDULength    - Length of the PSDU in bytes
%   SymbolDesign  - Multicarrier on-off keying (MC-OOK) symbol sequence and
%                   cyclic shift diversity (CSD) values
%   HDRSequence   - HDR MC-OOK symbol sequence
%   LDRSequence   - LDR MC-OOK symbol sequence
%   HDRCSD        - CSD values for WUR-Sync and WUR-Data field
%   LDRCSD        - CSD values for WUR-Data field for LDR
%   Enabled       - Subchannel puncturing

%   Copyright 2021-2024 The MathWorks, Inc.

%#codegen

properties
    %DataRate Data rate
    %   Specify the date rate as 'LDR' or 'HDR'. 'LDR' and 'HDR'
    %   indicate a data rate of 62.5 kb/s and 250 kb/s, respectively, as
    %   specified in IEEE P802.11ba/D8.0. The default is 'HDR'.
    DataRate = 'HDR';
    %PSDULength PSDU length
    %   Specify the PSDU length, in bytes, for the data carried in the
    %   subchannel. The PSDU length must be between 1 and 22, inclusive.
    %   The default is 8 bytes.
    PSDULength (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(PSDULength,1),mustBeLessThanOrEqual(PSDULength,22)} = 8;
    %SymbolDesign MC-OOK symbol sequence and CSD values
    %   Specify the MC-OOK symbol sequence and CSD values for WUR-Sync and
    %   WUR-Data field as one of 'Example1' | 'Example2' | 'Example3' |
    %   'User-defined'.
    %
    %   IEEE P802.11ba/D8.0, Table AC-1/AC-2 defines the MC-OOK symbol
    %   sequence, and Table AC-3/AC-4 defines the CSD values in nanoseconds
    %   for Example1, Example2, and Example3 respectively.
    %
    %   When set to 'User-defined', you can specify the MC-OOK symbol
    %   sequence and the CSD value using the HDRSequence, LDRSequence,
    %   HDRCSD, and LDRCSD properties. The default is 'Example1'.
    SymbolDesign = 'Example1';
    %HDRSequence HDR MC-OOK symbol sequence
    %   Specify the normalized MC-OOK symbol sequence for WUR-Sync and
    %   WUR-Data fields as a row vector of length 13. To enable this
    %   property, set the SymbolDesign property to 'User-defined'.
    HDRSequence (1,13) {mustBeNumeric,mustBeFinite} = [1 0 -3 0 -3 0 0 0 -3 0 -3 0 1]./sqrt(6.333);
    %LDRSequence LDR MC-OOK symbol sequence
    %   Specify the normalized MC-OOK symbol sequence for the WUR-Data
    %   field as a row vector of length 13. To enable this property, set
    %   the SymbolDesign property to 'User-defined'.
    LDRSequence (1,13) {mustBeNumeric,mustBeFinite} = [-1 1 1 1 -1 1 0 -1 -1 -1 1 -1 -1];
    %HDRCSD CSD values for WUR-Sync and WUR-Data fields for HDR
    %   Specify the CSD values in nanoseconds as a row vector of length
    %   NumTransmitAntennas for WUR-Sync and WUR-Data fields. The cyclic
    %   shift values must be less than or equal to 0. If you set this
    %   property as a row vector of length greater than
    %   NumTransmitAntennas, the object uses only the first
    %   NumTransmitAntennas values. This property applies only when
    %   SymbolDesign property is set to 'User-defined'. The default is 0.
    HDRCSD {mustBeNumeric,mustBeInteger,mustBeLessThanOrEqual(HDRCSD,0)} = 0;
    %LDRCSD CSD values for the WUR-Data field for LDR
    %   Specify the CSD values in nanoseconds for the WUR-Data field as a
    %   row vector of length NumTransmitAntennas. The cyclic shift values
    %   must be less than or equal to 0. If you set this property as a row
    %   vector of length greater than NumTransmitAntennas, the object uses
    %   only the first NumTransmitAntennas values. This property applies
    %   only when SymbolDesign property is set to 'User-defined'. The
    %   default is 0.
    LDRCSD {mustBeNumeric,mustBeInteger,mustBeLessThanOrEqual(LDRCSD,0)} = 0;
    %Enabled Subchannel puncturing
    %   Enable 20 MHz subchannel, specified as true or false. The default
    %   is true. To puncture the subchannel, set this property to false.
    %   All subchannels must be enabled when the channel bandwidth is less
    %   than 80 MHz, and at least one subchannel must be enabled when the
    %   channel bandwidth is 80 MHz.
    Enabled (1,1) logical = true;
end

properties(Constant,Hidden)
    DataRate_Values = {'HDR','LDR'};
    SymbolDesign_Values = {'Example1','Example2','Example3','User-defined'};
end

methods
    function obj = wlanWURSubchannel(varargin)
        obj@comm.internal.ConfigBase('SymbolDesign','Example1',varargin{:});
    end

    function obj = set.DataRate(obj,val)
        val = validateEnumProperties(obj,'DataRate',val);
        obj.DataRate = val;
    end

    function obj = set.SymbolDesign(obj,val)
        val = validateEnumProperties(obj,'SymbolDesign',val);
        obj.SymbolDesign = ''; % Force varsize
        obj.SymbolDesign = val;
    end
end

methods (Access = protected)
    function flag = isInactiveProperty(obj,prop)
        switch prop
            case {'HDRSequence','HDRCSD'}
                flag = ~strcmp(obj.SymbolDesign,'User-defined');
            case {'LDRSequence','LDRCSD'}
                flag = ~strcmp(obj.SymbolDesign,'User-defined') || strcmp(obj.DataRate,'HDR');
            otherwise
                flag = false;
        end
    end
end
end
