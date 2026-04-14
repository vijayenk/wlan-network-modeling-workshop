classdef wlanWURConfig < comm.internal.ConfigBase
%wlanWURConfig Create wake-up radio (WUR) format configuration object
%   CFGWUR = wlanWURConfig creates a wake-up radio (WUR) format
%   configuration object. This object contains the transmit parameters for
%   the WUR format of the IEEE P802.11ba/D8.0 standard.
%
%   CFGWUR = wlanWURConfig(NUMSUBCHANNELS) creates an object for
%   parameterizing a WUR packet. NumSubchannels specifies the number of 20
%   MHz subchannels and must be 1, 2, or 4. When you do not specify
%   NumSubchannels, the object assumes one 20 MHz subchannel.
%
%   CFGWUR = wlanWURConfig(...,Name,Value) creates an object for
%   parameterizing a WUR packet with the specified property Name set to the
%   specified Value. You can specify additional name-value pair arguments
%   in any order as (Name1,Value1,...,NameN,ValueN).
%
%   wlanWURConfig methods:
%
%   getPSDULength            - Number of coded bytes in the packet
%   packetFormat             - WUR packet format
%   transmitTime             - Time required to transmit a packet
%   getActiveSubchannelIndex - Indices of active subchannels
%
%   wlanWURConfig properties:
%
%   Subchannel          - 20 MHz subchannel parameters
%   NumTransmitAntennas - Number of transmit antennas
%   ChannelBandwidth    - Channel bandwidth
%   NumUsers            - Number of users

%   Copyright 2021-2024 The MathWorks, Inc.

%#codegen

properties
    %Subchannel 20 MHz subchannel properties
    %   Set the parameters of each 20 MHz subchannel. This property is a
    %   cell array of wlanWURSubchannel objects. Each element of the cell
    %   array contains properties to configure a 20 MHz subchannel. The
    %   object sets this property when you specify the NumSubchannel input.
    Subchannel;
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as a positive integer
    %   between 1 and 8 (inclusive). The default is 1.
    NumTransmitAntennas (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumTransmitAntennas,1),mustBeLessThanOrEqual(NumTransmitAntennas,8)} = 1;
end

properties (SetAccess = private,GetAccess = public)
    %ChannelBandwidth Channel bandwidth (MHz) of WUR packet
    %   Channel bandwidth, returned as one of 'CBW20' | 'CBW40' | 'CBW80'.
    %   The object sets this property based on the NumSubchannels input or
    %   the Subchannel property. Once the object is created, this property
    %   is read-only.
    ChannelBandwidth;
    %NumUsers Number of users
    %   The number of users, returned as a positive integer between 1 and 4
    %   (inclusive). The number of users depends on the Enabled property
    %   within the wlanWURSubchannel object. Once the object is created, 
    %   this property is read-only.
    NumUsers;
end

properties (SetAccess = private,GetAccess = public,Hidden)
    %NumSubchannel Number of 20 MHz subchannels within a WUR packet
    NumSubchannel;
    %InactiveSubchannels Indicates punctured 20 MHz subchannels
    InactiveSubchannels;
end

methods
    function obj = wlanWURConfig(varargin)
        numOddInputs = false;
        createSubchannel = true;
        if mod(nargin,2)==1 % Odd number of inputs
            if isscalar(varargin{1})
                % First input is scalar
                numSubchannels = varargin{1};
                validateattributes(numSubchannels(1),{'numeric'},{'scalar','>=',1,'<=',4},mfilename,'NumSubchannels');
            else
                % Name-Value pair check
                coder.internal.errorIf((mod(nargin,2)~=0),'wlan:ConfigBase:InvalidPVPairs');
            end
            startInd = 2;
            numOddInputs = true;
        else % Even number of inputs
            numSubchannels = 1;
            coder.internal.errorIf(nargin>0 && ~(ischar(varargin{1}) || isstring(varargin{1})),'wlan:ConfigBase:InvalidPVPairs');
            startInd = 1;
        end

        % Process Name-Value pairs
        for i=startInd:2:nargin-1
            if iscell(varargin{i+1}) && strcmp(varargin{i},'Subchannel')
                if strcmp(varargin{i},'Subchannel') && numOddInputs
                    coder.internal.errorIf(nargin>0 && ~(ischar(varargin{1}) || isstring(varargin{1})),'wlan:wlanWURConfig:InvalidNameValue');
                end
                numSubchannels = numel(varargin{i+1});
                createSubchannel = false;
            end
            obj.(char(varargin{i})) = varargin{i+1};
        end

        % Create subchannels
        if createSubchannel
            y = cell(1,numSubchannels);
            for i=1:numSubchannels
                y{i} = wlanWURSubchannel();
            end
            obj.Subchannel = y;
        end
    end

    function obj = set.Subchannel(obj,val)
        % Subchannel property must be a cell array of wlanWURSubchannel
        validateattributes(val,{'cell'},{'nonempty'},mfilename,'Subchannel');
        for i=1:numel(val)
            coder.internal.errorIf(~isa(val{i},'wlanWURSubchannel'),'wlan:wlanWURConfig:InvalidSubchannelType');
        end
        % NumSubchannels must be 1, 2, or 4
        coder.internal.errorIf(~any(numel(val)==[1 2 4]),'wlan:wlanWURConfig:InvalidSubchannelNum');
        obj.Subchannel = val;
    end

    function val = get.ChannelBandwidth(obj)
        switch numel(obj.Subchannel)
            case 1
                val = 'CBW20';
            case 2
                val = 'CBW40';
            otherwise
                val = 'CBW80';
        end
    end

    function val = get.NumUsers(obj)
        params = wlan.internal.wurTxTime(obj);
        val = numel(params.ActiveSubchannels);
    end

    function val = get.InactiveSubchannels(obj)
        val = coder.nullcopy(false(1,obj.NumSubchannel));
        for i=1:obj.NumSubchannel
            val(i) = ~(obj.Subchannel{i}.Enabled);
        end
    end

    function val = get.NumSubchannel(obj)
        val = numel(obj.Subchannel);
    end

    function format = packetFormat(obj) %#ok<MANU>
        %packetFormat Returns the packet format
        %   Returns the packet format as a character vector

        format = 'WUR';
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
        validateInactiveSubchannel(obj);
        params = wlan.internal.wurTxTime(obj);
        t = params.TXTIME/1e3; % Scaling factor to convert time from ns to us
        t = wlan.internal.convertTransmitTime(t,varargin{:});
     end

    function varargout = validateConfig(obj,varargin)
        %validateConfig Validate the dependent properties of wlanWURConfig object
        %   validateConfig(obj) validates the dependent properties for the
        %   specified wlanWURConfig configuration object.
        %
        %   For INTERNAL use only, subject to future changes

        narginchk(1,2);
        if nargin==2
            mode = varargin{1};
        else
            mode = 'Full';
        end

        s = validateLength(obj); % wlanFieldIndices
        if strcmp(mode,'Full')
            validateCyclicShifts(obj);
            validateInactiveSubchannel(obj);
        end

        if nargout==1
            varargout{1} = s;
        end
    end

    function psduLength = getPSDULength(obj)
        %getPSDULength Returns PSDU length for the configuration
        %   Returns PSDU length as a row vector for active subchannels

        params = wlan.internal.wurTxTime(obj);
        psduLength = params.PSDULength(params.ActiveSubchannels);
    end

    function activeSubchannelIndex = getActiveSubchannelIndex(obj)
        %getActiveSubchannelIndex Returns the indices of active subchannels
        %   Returns the indices of active subchannels as a row vector

        allActiveSubchannels = 1:obj.NumSubchannel;
        activeSubchannelIndex = allActiveSubchannels(obj.InactiveSubchannels==0);
    end
end

methods (Access = private)
    function s = validateLength(obj)
        %Get length properties for wlanWURConfig configuration object

        sf = 1e3; % Scaling factor to convert time from ns to us
        params = wlan.internal.wurTxTime(obj);
        % Set output structure
        s = struct( ...
            'NumDataSymbols', params.NSYM(params.ActiveSubchannels), ...
            'TxTime', params.TXTIME/sf, ...% TxTime in us
            'PSDULength', params.PSDULength(params.ActiveSubchannels), ...
            'NumPaddingBits', params.NPad(params.ActiveSubchannels));
    end

    function validateInactiveSubchannel(obj)
        %validateInactiveSubchannels Validate InactiveSubchannels of wlanWURConfig object

        if strcmp(obj.ChannelBandwidth,'CBW80')
            coder.internal.errorIf(all(obj.InactiveSubchannels==true),'wlan:wlanWURConfig:InvalidInactiveSubchannelNum');
        else
            coder.internal.errorIf(any(obj.InactiveSubchannels==true),'wlan:wlanWURConfig:InvalidInactiveSubchannelOption');
        end
    end

    function validateCyclicShifts(obj)
        %validateCyclicShifts Validate CyclicShifts values against
        %   NumTransmitAntennas, HDRCSD, LDRCSD

        for subCh=1:obj.NumSubchannel
            if strcmp(obj.Subchannel{subCh}.SymbolDesign,'User-defined')
                numHDRCSD = numel(obj.Subchannel{subCh}.HDRCSD);
                numTx = obj.NumTransmitAntennas;
                if strcmp(obj.Subchannel{subCh}.DataRate,'HDR')
                    coder.internal.errorIf(numHDRCSD<numTx,'wlan:wlanWURConfig:InvalidCSD','HDRCSD',numTx,subCh);
                else
                    numLDRCSD = numel(obj.Subchannel{subCh}.LDRCSD);
                    coder.internal.errorIf(numHDRCSD<numTx,'wlan:wlanWURConfig:InvalidCSD','HDRCSD',numTx,subCh);
                    coder.internal.errorIf(numLDRCSD<numTx,'wlan:wlanWURConfig:InvalidCSD','LDRCSD',numTx,subCh);
                end
            end
        end
    end
end

end

