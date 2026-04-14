classdef wlanHTConfig < comm.internal.ConfigBase
%wlanHTConfig Create a high throughput (HT) format configuration object
%   CFGHT = wlanHTConfig creates a high throughput (HT) format
%   configuration object. This object contains the transmit parameters for
%   the HT-Mixed Format of the IEEE 802.11 standard.
%
%   CFGHT = wlanHTConfig(Name,Value) creates a HT object, CFGHT, with the
%   specified property Name set to the specified Value. You can specify
%   additional name-value pair arguments in any order as
%   (Name1,Value1,...,NameN,ValueN).
%
%   wlanHTConfig methods:
%
%   packetFormat - HT packet format
%   transmitTime - Time required to transmit a packet
%
%   wlanHTConfig properties:
%
%   ChannelBandwidth     - Channel bandwidth (MHz) 
%   NumTransmitAntennas  - Number of transmit antennas
%   PreHTCyclicShifts    - Cyclic shift values for >4 transmit chains
%   NumSpaceTimeStreams  - Number of space-time streams 
%   NumExtensionStreams  - Number of extension spatial streams
%   SpatialMapping       - Spatial mapping scheme
%   SpatialMappingMatrix - Spatial mapping matrices
%   MCS                  - Modulation and coding scheme
%   GuardInterval        - Guard interval type used for transmission
%   ChannelCoding        - Forward error correction coding type used
%   PSDULength           - Length of the PSDU in bytes
%   AggregatedMPDU       - Aggregation indication
%   RecommendSmoothing   - Recommend smoothing for channel estimation

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

% Define properties in order of intended display
% Public properties
properties (SetAccess = 'public')
    %ChannelBandwidth Channel bandwidth (MHz) for PPDU transmission
    %   Specify the channel bandwidth for the packet as one of 'CBW20'
    %   | 'CBW40' to indicate 20MHz and 40MHz use respectively. The
    %   default is 'CBW20'.
    ChannelBandwidth = 'CBW20';     
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as a numeric, positive
    %   integer scalar. The default is 1.
    NumTransmitAntennas = 1;
    %PreHTCyclicShifts Cyclic shift values for >4 transmit chains
    %   Specify the cyclic shift values for the pre-HT portion of the
    %   waveform, in nanoseconds for >4 transmit antennas as a row vector
    %   of length L = NumTransmitAntennas-4. The cyclic shift values must
    %   be between -200 and 0 inclusive. The first 4 antennas use the
    %   cyclic shift values defined in Table 19-9 of IEEE Std 802.11-2016.
    %   The remaining antennas use the cyclic shift values defined in this
    %   property. If the length of this row vector is specified as a value
    %   greater than L, the object only uses the first L PreHTCyclicShifts
    %   values. For example, if you specify the NumTransmitAntennas
    %   property as 16 and this property as a row vector of length N>L, the
    %   object only uses the first L = 16-4 = 12 entries. This property
    %   applies only when you set the NumTransmitAntennas property to a
    %   value greater than 4. The default value of this property is -75.
    PreHTCyclicShifts {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(PreHTCyclicShifts,-200), mustBeLessThanOrEqual(PreHTCyclicShifts,0)}  = -75;     
    %NumSpaceTimeStreams Number of space-time streams
    %   Specify the number of space-time streams as a positive integer
    %   scalar between 1 and 4, inclusive. The default is 1.
    NumSpaceTimeStreams = 1;
    %NumExtensionStreams Number of extension spatial streams
    %   Specify the number of spatial extension streams as a positive
    %   integer scalar between 0 and 3, inclusive. The default is 0.
    NumExtensionStreams = 0; 
    %SpatialMapping Spatial mapping scheme
    %   Specify the spatial mapping scheme as one of 'Direct' |
    %   'Hadamard' | 'Fourier' | 'Custom'. The default value of this
    %   property is 'Direct', which applies when the
    %   NumSpaceTimeStreams and NumTransmitAntennas properties are
    %   equal and the NumExtensionStreams property is 0.
    SpatialMapping = 'Direct';
    %SpatialMappingMatrix Spatial mapping matrices
    %   Specify the spatial mapping matrix(ces) as a double precision,
    %   real or complex, 2D matrix or 3D array. This property applies
    %   when you set the SpatialMapping property to 'Custom'. It can be
    %   of size [Nsts+Ness, Nt], where Nsts is the NumSpaceTimeStreams
    %   property value, Ness is the NumExtensionStreams property value
    %   and Nt is the NumTransmitAntennas property value. In this case,
    %   the spatial mapping matrix applies to all the frequency
    %   subcarriers and its first Nsts and last Ness rows apply to the
    %   space-time streams and extension spatial streams respectively.
    %   Alternatively, it can be of size [Nst, Nsts+Ness, Nt], where
    %   Nst is the number of data plus pilot subcarriers determined by
    %   the ChannelBandwidth property. Specifically, Nst is 56 for
    %   'CBW20' and 114 for 'CBW40'. In this case, each data and pilot
    %   subcarrier can have its own spatial mapping matrix. In either
    %   2D or 3D case, the spatial mapping matrix for each subcarrier
    %   is normalized. The default value of this property is 1.
    SpatialMappingMatrix = 1;
    %MCS Modulation and coding scheme
    %   Specify the modulation and coding scheme for the packet
    %   transmission as a integer scalar between 0 and 31, inclusive.
    %   The selected value also sets the number of spatial streams
    %   (Nss) for the configuration. The difference between the number
    %   of space-time streams (NumSpaceTimeStreams) and Nss conveys
    %   the use of space-time block coding (STBC). The default is 0.
    MCS = 0;                       
    %GuardInterval Guard interval (cyclic prefix) type
    %   Specify the cyclic prefix type of the data field within a
    %   packet as one of 'Long' | 'Short'. An interval of 800ns and
    %   400ns is used for long and short guard interval types
    %   respectively. The default is 'Long'.
    GuardInterval = 'Long';
    %ChannelCoding Forward error correction coding type
    %   Specify the channel coding as one of 'BCC' | 'LDPC' to indicate
    %   binary convolution coding (BCC) or low-density-parity-check
    %   (LDPC) coding. The default is 'BCC'.
    ChannelCoding = 'BCC'; 
    %PSDULength PSDU length
    %   Specify the PSDU length as an integer scalar for the data
    %   carried in a packet, in bytes. The default is 1024.
    PSDULength = 1024; 
    %AggregatedMPDU Aggregation indication
    %   Set to true to indicate this is a packet with A-MPDU
    %   aggregation. The default is false.
    AggregatedMPDU (1,1) logical = false;
    %RecommendSmoothing Recommend smoothing for channel estimation
    %   Set this property to true to indicate smoothing is recommended
    %   for channel estimation. The default is true.
    RecommendSmoothing (1,1) logical = true;      
end

properties(Constant, Hidden)
    ChannelBandwidth_Values  = {'CBW20', 'CBW40'};
    SpatialMapping_Values    = {'Direct', 'Hadamard', 'Fourier', 'Custom'}
    ChannelCoding_Values     = {'BCC', 'LDPC'};
    GuardInterval_Values     = {'Long', 'Short'};
end

methods
    % Constructor
    function obj = wlanHTConfig(varargin)
        % For codegen set maximum dimensions to force varsize
        if ~isempty(coder.target)
            spatialMapping = 'Direct';
            coder.varsize('spatialMapping',[1 8],[0 1]); % Add variable-size support
            obj.SpatialMapping = spatialMapping; % Default

            guardInterval = 'Long';
            coder.varsize('guardInterval',[1 5],[0 1]); % Add variable-size support
            obj.GuardInterval = guardInterval; % Default

            channelCoding = 'BCC';
            coder.varsize('channelCoding',[1 4],[0 1]); % Add variable-size support
            obj.ChannelCoding = channelCoding; % Default
        end
        obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
    end

    % Property self-validation and sets
    function obj = set.ChannelBandwidth(obj,val)
        propName = 'ChannelBandwidth';
        val = validateEnumProperties(obj, propName, val);
        obj.(propName) = val;
    end

    function obj = set.NumTransmitAntennas(obj, val)
        propName = 'NumTransmitAntennas';
        validateattributes(val, {'numeric'}, ...
            {'real','integer','scalar' '>=',1}, ...
            [class(obj) '.' propName], propName);
        obj.(propName) = val;
    end

    function obj = set.NumSpaceTimeStreams(obj, val)
        propName = 'NumSpaceTimeStreams';
        validateattributes(val, {'numeric'}, ...
            {'real','integer','scalar' '>=',1,'<=',4}, ...
            [class(obj) '.' propName], propName);
        obj.(propName) = val;
    end

    function obj = set.NumExtensionStreams(obj, val)
        propName = 'NumExtensionStreams';
        validateattributes(val, {'numeric'}, ...
            {'real','integer','scalar','>=',0,'<=',3}, ...
            [class(obj) '.' propName], propName);
        obj.(propName) = val;
    end

    function obj = set.SpatialMapping(obj, val)
        propName = 'SpatialMapping';
        val = validateEnumProperties(obj, propName, val);
        obj.(propName) = val;
    end

    function obj = set.SpatialMappingMatrix(obj, val)
        propName = 'SpatialMappingMatrix';
        validateattributes(val, {'double'}, {'3d','finite','nonempty'}, ...
            [class(obj) '.' propName], propName); 

        is3DFormat = (ndims(val) == 3) || (iscolumn(val) && ~isscalar(val));
        numSTS = size(val, 1+is3DFormat);
        numTx  = size(val, 2+is3DFormat);
        coder.internal.errorIf( ...
            (is3DFormat && ~any(size(val, 1) == [56 114])) || ...  
            (numSTS > 4) || (numSTS > numTx), ...
            'wlan:wlanHTConfig:InvalidSpatialMapMtxDim');

        obj.(propName) = val;
    end

    function obj = set.MCS(obj,val)
        propName = 'MCS';
        validateattributes(val, {'numeric'}, ...
            {'real','integer','scalar','>=',0,'<=',31}, ...
            [class(obj) '.' propName], propName); 
        obj.(propName) = val;
    end

    function obj = set.GuardInterval(obj,val)
        propName = 'GuardInterval';
        val = validateEnumProperties(obj, propName, val);
        obj.(propName) = val;
    end

    function obj = set.ChannelCoding(obj, val)
        propName = 'ChannelCoding';
        val = validateEnumProperties(obj, propName, val);
        obj.(propName) = val;
     end

    function obj = set.PSDULength(obj,val)
        propName = 'PSDULength';
        validateattributes(val, {'numeric'}, ...
            {'real','integer','scalar','>=',0,'<=',65535}, ...
            [class(obj) '.' propName], propName); 
        obj.(propName) = val;
    end

    function format = packetFormat(obj) %#ok<MANU>
        %packetFormat Returns the packet format
        %   Returns the packet format as a character vector
        format = 'HT-MF';
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
        s = validateMCSLength(obj);
        t = wlan.internal.convertTransmitTime(s.TxTime,varargin{:});
    end

    function varargout = validateConfig(obj, varargin)
        % validateConfig Validate the wlanHTConfig object
        %
        %   validateConfig(CFGHT) validates the dependent properties
        %   for the specified wlanHTConfig configuration object.

        %   For INTERNAL use only, subject to future changes:
        %
        %   validateConfig(CFGHT, MODE) validates only the subset of 
        %   dependent properties as specified by the MODE input.
        %   MODE must be one of:
        %    'EssSTS':
        %    'STSTx':
        %    'SMapping':
        %    'MCS':
        %    'MCSSTSTx':
        %    'SMappingMCS':

        narginchk(1,2);nargoutchk(0,1);
        if (nargin==2)
            mode = varargin{1};
        else
            mode = 'Full';
        end

        s = struct('NumDataSymbols', nan, ...
            'NumPadBits',     nan, ...
            'NumPPDUSamples', nan, ...
            'TxTime',         nan, ...
            'PSDULength',     nan);

        if strcmp(mode, 'EssSTS')           % wlanHTLTFDemodulate, 
            validateEssSTS(obj);            % wlanHTLTFChannelEstimate 

        elseif strcmp(mode, 'STSTx')        % wlanFieldIndices
            validateSTSTx(obj);

        elseif strcmp(mode, 'SMapping')     % HT-STF, HT-LTF
            validateSpatialMapping(obj);

        elseif strcmp(mode, 'MCS')          % wlanHTDataRecover
            s = validateMCSLengthTxTime(obj);

        elseif strcmp(mode, 'MCSSTSTx')     % HT-SIG, LSIG
            validateSTSTx(obj);
            s = validateMCSLengthTxTime(obj);
            
        elseif strcmp(mode, 'CyclicShift')  % Pre-HT fields cyclic shifts
            % Validate PreHTCyclicShifts values against NumTransmitAntennas
            validatePreHTCyclicShifts(obj);

        elseif strcmp(mode, 'SMappingMCS') || strcmp(mode, 'Full') % HT-Data
            % Shared full object validation
            validateSpatialMapping(obj);
            validatePreHTCyclicShifts(obj);
            s = validateMCSLengthTxTime(obj);

        end
        if nargout==1
            varargout{1} = s;
        end

    end      

end

methods (Access = protected)
    function flag = isInactiveProperty(obj, prop)
        flag = false;
        if strcmp(prop, 'NumExtensionStreams')
            flag = ~wlan.internal.inESSMode(obj);
        elseif strcmp(prop, 'SpatialMappingMatrix')
            flag = ~strcmp(obj.SpatialMapping, 'Custom');
        elseif strcmp(prop,'PreHTCyclicShifts')
            flag = obj.NumTransmitAntennas<=4;
        end
    end
end

methods (Access = private)

    function s = privInfo(obj)
        %privInfo Returns information relevant to the object
        %   S = privInfo(cfgHT) returns a structure, S, containing the
        %   relevant information for the wlanHTConfig object, cfgHT.
        %   The output structure S has the following fields:
        %
        %   NumDataSymbols - Number of OFDM symbols for the Data field
        %   NumPadBits     - Number of pad bits in the Data field
        %   NumPPDUSamples - Number of PPDU samples per transmit antenna
        %   TxTime         - PPDU transmission time in us
        %   PSDULength     - PSDU length in octets (bytes)

        % Compute the number of OFDM symbols in Data field
        mcsTable  = wlan.internal.getRateTable(obj);
        numDBPS   = mcsTable.NDBPS;
        numES     = mcsTable.NES;
        rate      = mcsTable.Rate;
        mSTBC     = mcsTable.mSTBC;
        numSTS = obj.NumSpaceTimeStreams;

        if obj.PSDULength > 0                
            if strcmp(obj.ChannelCoding,'BCC') 
                Ntail = 6;
                numDataSym = mSTBC * ceil((8*obj.PSDULength + 16 + ...
                                          Ntail*numES)/(mSTBC*numDBPS));
                numPadBits = numDataSym * numDBPS - (8*obj.PSDULength + ...
                                                     16 + Ntail*numES);
            else % LDPC
                numPLD = obj.PSDULength*8 + 16;
                cfg = wlan.internal.getLDPCparameters(numDBPS,rate,mSTBC,numPLD);
                numDataSym = cfg.NumSymbol;

                %No Padding in HT. This does not account for the repeated bits
                numPadBits = 0; 
            end            
        else % == 0, NDP or sounding packet
            numDataSym = 0;
            numPadBits = 0;
        end

        % Compute the number of PPDU samples at CBW
        switch obj.ChannelBandwidth
            case 'CBW40'
                Nfft = 128;
            otherwise   % 'CBW20'
                Nfft = 64;
        end

        if wlan.internal.inESSMode(obj)
            numESS = obj.NumExtensionStreams;            
        else
            numESS = 0;
        end
        numPreambSym = 2 + 2 + 1 + 2 + 1 + wlan.internal.numVHTLTFSymbols(numSTS) + ...
                       wlan.internal.numHTELTFSymbols(numESS); 
        numSymbols = numPreambSym + numDataSym;

        if strcmp(obj.GuardInterval, 'Short')
            cpLen = Nfft/8;
            numSamples = numPreambSym*(Nfft*5/4) + numDataSym*(Nfft + cpLen);
            txTime = numPreambSym*4 + 4*ceil(numDataSym*3.6/4);
        else % 'Long'
            cpLen = Nfft/4;
            numSamples = numSymbols * (Nfft + cpLen);
            txTime = (numPreambSym+numDataSym)*4;
        end

        % Set output structure
        s.NumDataSymbols = numDataSym;
        s.NumPadBits     = numPadBits;
        s.NumPPDUSamples = numSamples;
        s.TxTime         = txTime;
        s.PSDULength     = obj.PSDULength;
    end

    function validateEssSTS(obj)
    %   ValidateESSSTS Validate NumExtensionStreams, NumSpaceTimeStreams
    %   properties for wlanHTConfig object

        if wlan.internal.inESSMode(obj)
            % Nsts + Ness <= 4
            coder.internal.errorIf( obj.NumExtensionStreams + ...
                obj.NumSpaceTimeStreams > 4, ...
                'wlan:wlanHTConfig:InvalidNumEss');
        end
    end

    function validateSTSTx(obj)
    %   ValidateSTSTx Validate NumTransmitAntennas, NumSpaceTimeStreams
    %   NumExtensionStreams properties for wlanHTConfig object

        if wlan.internal.inESSMode(obj)
            % NumTx and Nsts: numTx cannot be less than (Nsts+Ness)
            coder.internal.errorIf( obj.NumTransmitAntennas < ...
                obj.NumSpaceTimeStreams + obj.NumExtensionStreams, ...
                'wlan:wlanHTConfig:InvalidNumTxandSTSESS');
        else
            % NumTx and Nsts: numTx cannot be less than Nsts
            coder.internal.errorIf( obj.NumTransmitAntennas < ...
                obj.NumSpaceTimeStreams, ...
                'wlan:wlanHTConfig:InvalidNumTxandSTS');
        end
    end

    function validateSpatialMapping(obj)
    %   ValidateSpatialMapping Validate spatial mapping properties for
    %   wlanHTConfig object that include:
    %     NumTransmitAntennas, NumSpaceTimeStreams, SpatialMapping, 
    %     SpatialMappingMatrix, NumExtensionStreams, ChannelBandwidth

        validateSTSTx(obj);        
        validateEssSTS(obj);

        % Validate spatial mapping between STS+ESS and Tx
        if wlan.internal.inESSMode(obj)               
            numESS = obj.NumExtensionStreams;
        else
            numESS = 0;
        end

        coder.internal.errorIf(strcmp(obj.SpatialMapping, 'Direct') && ...
        ( (obj.NumSpaceTimeStreams ~= obj.NumTransmitAntennas) ), ...
        'wlan:wlanHTConfig:NumSTSNotEqualNumTxDirectMap');

        % Restrict to Custom for v1.
        coder.internal.errorIf(numESS ~=0 && ...
            ~strcmp(obj.SpatialMapping, 'Custom'), ...
            'wlan:wlanHTConfig:NumESSNotCustomMap');

        if strcmp(obj.SpatialMapping, 'Custom')
            % Validate spatial mapping matrix
            SPMtx = obj.SpatialMappingMatrix;
            is3DFormat = (ndims(SPMtx) == 3) || (iscolumn(SPMtx) && ...
                         ~isscalar(SPMtx));
            numSTSPlusESS = size(SPMtx, 1+is3DFormat);
            numTx         = size(SPMtx, 2+is3DFormat);
            if strcmp(obj.ChannelBandwidth, 'CBW20')
                numST = 56;
            else
                numST = 114;
            end
            coder.internal.errorIf( ...
                (is3DFormat && (size(SPMtx, 1) ~= numST)) || ...
                (numSTSPlusESS ~= (obj.NumSpaceTimeStreams + numESS)) || ...
                (numTx ~= obj.NumTransmitAntennas), ...
                'wlan:wlanHTConfig:MappingMtxNotMatchOtherProp', ...
                obj.NumSpaceTimeStreams, numESS, obj.NumTransmitAntennas, ...
                numST);
        end
    end

    function s = validateMCSLength(obj)
    %   ValidateMCSLength Validate PSDULength, MCS and Spatial properties
    %   for the wlanHTConfig object that include:
    %     PSDULength, MCS, NumSpaceTimeStreams, ChannelBandwidth, 
    %     NumExtensionStreams, GuardInterval
    %   Returns a structure with packet information.

        validateEssSTS(obj);

        % IEEE Std 802.11-2012, Table 20-12, Nsts cannot be less than Nss
        Nss = floor(obj.MCS/8)+1;
        coder.internal.errorIf( obj.NumSpaceTimeStreams < Nss, ...
            'wlan:wlanHTConfig:InvalidNumSTSandSSLT', ...
            obj.NumSpaceTimeStreams, Nss);

        % IEEE Std 802.11-2012, Tables 20-12, 20-18, Nsts cannot be > 2*Nss
        coder.internal.errorIf( obj.NumSpaceTimeStreams > 2*Nss, ...
            'wlan:wlanHTConfig:InvalidNumSTSandSSGT', ... 
            obj.NumSpaceTimeStreams, Nss);

        s = privInfo(obj);
    end

    function s = validateMCSLengthTxTime(obj)
    %   ValidateMCSLength Validate PSDULength, MCS and Spatial properties,
    %   and resultant TxTime for the wlanHTConfig object that include:
    %     PSDULength, MCS, NumSpaceTimeStreams, ChannelBandwidth,
    %     NumExtensionStreams, GuardInterval
    %   Returns a structure with packet information.

        s = validateMCSLength(obj);

        % Validate TxTime (max 5.484ms for Mixed mode)
        coder.internal.errorIf( s.TxTime > 5484, ...
            'wlan:wlanHTConfig:InvalidPPDUDuration'); 

    end
    
    function validatePreHTCyclicShifts(obj)
    %   validatePreHTCyclicShifts Validate PreHTCyclicShifts values against
    %   NumTransmitAntennas for wlanHTConfig object that includes:
    %     PreHTCyclicShifts, NumTransmitAntennas

        numTx = obj.NumTransmitAntennas;
        csh = obj.PreHTCyclicShifts;
        if numTx>4
            coder.internal.errorIf(~(numel(csh)>=numTx-4),'wlan:shared:InvalidCyclicShift','PreHTCyclicShifts',numTx-4);
        end
    end

end
end
