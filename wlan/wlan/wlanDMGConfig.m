classdef wlanDMGConfig < comm.internal.ConfigBase
%wlanDMGConfig Create a directional multi-gigabit (DMG) format configuration object
%   CFGDMG = wlanDMGConfig creates a directional 60 GHz format
%   configuration object. This object contains the transmit parameters for
%   the DMG format of IEEE 802.11 standard.
%
%   CFGDMG = wlanDMGConfig(Name,Value) creates a DMG object, CFGDMG, with
%   the specified property Name set to the specified value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanDMGConfig methods:
%
%   phyType      - DMG PHY modulation type
%   transmitTime - Time required to transmit a packet
%
%   wlanDMGConfig properties:
%
%   MCS                     - Modulation and coding scheme
%   TrainingLength          - Training field length
%   PacketType              - Packet training field type
%   BeamTrackingRequest     - Indicates beam tracking is requested
%   TonePairingType         - Tone pairing type
%   DTPGroupPairIndex       - Specify the DTP group pair indexing
%   DTPIndicator            - Indicate DTP update
%   PSDULength              - PSDU length
%   ScramblerInitialization - Scrambler initialization
%   AggregatedMPDU          - Aggregation indication
%   LastRSSI                - Indicates the received power level of the last packet
%   Turnaround              - Turnaround indication

%   Copyright 2016-2024 The MathWorks, Inc.

%#codegen
    
properties (Access = public)
    %MCS Modulation and coding scheme
    %   Specify the modulation and coding scheme as a character vector,
    %   string scalar, or integer. MCS must be an integer index from 0 to
    %   24, or one of the extended MCS indices: 9.1, 12.1, 12.2, 12.3,
    %   12.4, 12.5 or 12.6. An extended (non-integer) MCS index can only be
    %   specified as a character vector or string scalar. An integer MCS
    %   index can be specified as a character vector, string scalar, or
    %   integer. The default value is '0'.
    MCS = '0';
    %TrainingLength Training field length
    %   Specify the number of training fields as an integer from 0 to 64,
    %   in multiples of 4. The default value is 0.
    TrainingLength = 0;
    %PacketType Packet training field type
    %   Specify the packet training field type as 'TRN-R' or 'TRN-T'. This
    %   property applies when TrainingLength>0. The default value is
    %   'TRN-R'.
    PacketType = 'TRN-R';
    %BeamTrackingRequest Indicates beam tracking is requested
    %   Set to true to indicate beam tracking is requested. This property
    %   applies when MCS is not 0 and TrainingLength>0. The default is
    %   false.
    BeamTrackingRequest (1,1) logical = false;
    %TonePairingType Tone pairing type
    %   Specify the tone mapping type as 'Static' or 'Dynamic'. The default
    %   value is 'Static'. This property applies when OFDM and SQPSK or
    %   QPSK modulation is used, when MCS is from 13 to 17.
    TonePairingType = 'Static';
    %DTPGroupPairIndex Specify the DTP group pair indexing
    %   Specify the DTP group pair index for each pair as a 42-by-1 vector
    %   of integers. Element values must be in the range 0 to 41. There
    %   must be no duplicate elements. The default value is (0:1:41)'. This
    %   property applies when MCS is from 13 to 17 and when ToneParingType
    %   is 'Dynamic'.
    DTPGroupPairIndex = (0:41).';
    %DTPIndicator Enable DTP update indication
    %   Bit flip used to indicate DTP update. Set this property to true or
    %   false. The default value is false. This property applies when MCS
    %   is from 13 to 17 and when ToneParingType is 'Dynamic'.
    DTPIndicator (1,1) logical = false;
    %PSDULength PSDU length
    %   Specify the PSDU length in bytes as an integer from 1 to 262143.
    %   The default value is 1000.
    PSDULength = 1000;
    %ScramblerInitialization Scrambler initialization
    %   Specify the scrambler initialization as a double or int8 scalar, or
    %   an int8-typed binary vector. The default is 2. The valid range
    %   depends on the MCS:
    %     When MCS is 0, the valid range is between 1 and 15 inclusive,
    %     corresponding to a 4-by-1 column vector.
    %     When MCS is 9.1, 12.1, 12.2, 12.3, 12.4, 12.5 or 12.6, the valid
    %     range is between 0 and 31 inclusive, corresponding to a 5-by-1
    %     column vector.
    %     Otherwise, the valid range is between 1 and 127 inclusive,
    %     corresponding to a 7-by-1 column vector.
    ScramblerInitialization = 2;
    %AggregatedMPDU Aggregation indication
    %   Set to true to indicate this is a packet with A-MPDU aggregation.
    %   This property applies when MCS is not 0. The default is false.
    AggregatedMPDU (1,1) logical = false;
    %LastRSSI Indicates the received power level of the last packet
    %   Specify the received power level as an integer from 0 to 15. This
    %   property applies when MCS is not 0. The default is 0.
    LastRSSI = 0;
    %Turnaround Turnaround indication
    %   Set to true to indicate the STA is required to listen for an
    %   incoming PPDU immediately following the transmission. The default
    %   is false.
    Turnaround (1,1) logical = false;
end

properties(Constant, Hidden)
    PacketType_Values = {'TRN-R','TRN-T'};
    TonePairingType_Values = {'Static','Dynamic'};
    MCS_Values = {'0','1','2','3','4','5','6','7','8','9','9.1','10','11','12','12.1','12.2','12.3','12.4','12.5','12.6','13','14','15','16','17','18','19','20','21','22','23','24'};
end

methods
  function obj = wlanDMGConfig(varargin)
    % For codegen set maximum dimensions to force varsize
    if ~isempty(coder.target)
        tonePairingType = 'Static';
        coder.varsize('tonePairingType',[1 7],[0 1]); % Add variable-size support
        obj.TonePairingType = tonePairingType; % Default
    end
    obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
  end

  function obj = set.MCS(obj,val)
    propName = 'MCS';
    val = convertStringsToChars(val); % String conversion
    if ischar(val)
        validatestring(val,obj.MCS_Values,[class(obj) '.' propName],propName);
        obj.(propName) = '';
    else
        validateattributes(val,{'numeric'},{'real','scalar'},[class(obj) '.' propName],propName);
        coder.internal.errorIf(~any(val==0:1:24),'wlan:wlanDMGConfig:InvalidMCS');
    end
    obj.(propName) = val;
  end
  
  function obj = set.PSDULength(obj, val)
    propName = 'PSDULength';
    validateattributes(val,{'numeric'},{'real','integer','scalar','>=',1,'<=',262143},[class(obj) '.' propName],propName);
    obj.(propName) = val;
  end
  
  function obj = set.ScramblerInitialization(obj, val)
    propName = 'ScramblerInitialization';

    if isscalar(val) 
        validateattributes(val,{'double','int8'},{'real','integer','column','nonempty','>=',0,'<=',127},[class(obj) '.' propName],propName);
    elseif iscolumn(val)  % [7, 1], [5, 1], or [4, 1]
        coder.internal.errorIf(any((val~=0) & (val~=1)) || ~((size(val,1)==7)||(size(val,1)==5)||(size(val,1)==4)),'wlan:wlanDMGConfig:InvalidScramInitValue');
    else
        % Check for row or matrix input
        coder.internal.error('wlan:wlanDMGConfig:InvalidScramInitValue');
    end
    obj.(propName) = val;
  end

  function obj = set.TrainingLength(obj, val)
    propName = 'TrainingLength';
    % Training length must be a multiple of 4, <= 64, and >= 0
    validateattributes(val,{'numeric'},{'real','integer','scalar','>=',0,'<=',64},[class(obj) '.' propName],propName);
    coder.internal.errorIf(mod(val,4)~=0,'wlan:wlanDMGConfig:InvalidTrainingLength');
    obj.(propName) = val;
  end
  
  function obj = set.PacketType(obj,val)
    propName = 'PacketType';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end
  
  function obj = set.TonePairingType(obj,val)
    propName = 'TonePairingType';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end

  function obj = set.LastRSSI(obj,val)
    propName = 'LastRSSI';
    validateattributes(val,{'numeric'},{'real','integer','scalar','>=',0,'<=',15},[class(obj) '.' propName],propName);
    obj.(propName) = val;
  end  

  function obj = set.DTPGroupPairIndex(obj,val)
    propName = 'DTPGroupPairIndex';
    validateattributes(val,{'numeric'},{'real','integer','column','>=',0,'<=',41,'size',[42 1]},[class(obj) '.' propName],propName);
    % Ensure all indices are accounted for (0:41)
    coder.internal.errorIf(~isempty(setdiff(0:41,val,'stable')),'wlan:wlanDMGConfig:InvalidDTPGroupPairIndex');
    obj.(propName) = val;
  end  
  
  function type = phyType(obj)
    %phyType Get DMG PHY modulation type
    %   Returns the DMG PHY modulation method as a character vector, based
    %   on the current configuration. PHY type is one of 'Control', 'SC' or
    %   'OFDM'.
    mcs = obj.MCS;
    if ischar(mcs)
        mcsUse = str2double(mcs);
    else
        mcsUse = mcs;
    end
    
    if mcsUse==0
        type = 'Control';
    elseif mcsUse>=13 && mcsUse<=24
        type = 'OFDM';
    else % mcs>=1 && mcs<=12.6
        type = 'SC';
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
        s = validateMCSLength(obj);
        t = wlan.internal.convertTransmitTime(s.TxTime,varargin{:});
  end
  
  function varargout = validateConfig(obj,varargin)
    % validateConfig Validate the wlanDMGConfig object
    %   validateConfig(CFGDMG) validates the dependent properties for the
    %   specified wlanDMGConfig configuration object.
    % 
    %   For INTERNAL use only, subject to future changes.
    %
    %   validateConfig(CFGDMG,MODE) validates only the subset of dependent
    %   properties as specified by the MODE input. MODE must be one of:
    %       'Scrambler' - validates scrambler initialization
    %       'Length' - validates PSDULength for MCS0, and TXTIME
    %       'Full' - validates all above
    
    narginchk(1,2);
    nargoutchk(0,1);
    if (nargin==2)
        mode = varargin{1};
    else
        mode = 'Full';
    end

    switch mode
        case 'Scrambler'
            % Validate scrambler initialization
            validateScramblerInitialization(obj);
            
        case 'Length'
            % Validate PSDULength and TXTIME, and return waveform information
            s = validateMCSLengthTxTime(obj);
            
        otherwise
            % Validate full object and return waveform information
            validateScramblerInitialization(obj);
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
    if strcmp(prop,'TonePairingType')
        % Hide DTP related properties unless configuration is OFDM SQPSK or
        % QPSK
        if ischar(obj.MCS)
            flag = ~any(strcmp(obj.MCS,{'13','14','15','16','17'}));
        else
            flag = ~(obj.MCS>=13 & obj.MCS<=17);
        end
    elseif any(strcmp(prop,{'DTPIndicator','DTPGroupPairIndex'}))
        % Hide DTPIndicator and DTPGroupPairIndex if dynamic tone mapping
        % is not used or the modulation scheme is not OFDM SQPSK or QPSK
        if ischar(obj.MCS)
            flag = ~any(strcmp(obj.MCS,{'13','14','15','16','17'}));
        else
            flag = ~(obj.MCS>=13 & obj.MCS<=17);
        end
        flag = flag | ~strcmp(obj.TonePairingType,'Dynamic');
    elseif any(strcmp(prop,{'PacketType'}))
        % Hide PacketType when TrainingLength is 0
        flag = obj.TrainingLength==0;
    elseif any(strcmp(prop,{'AggregatedMPDU','LastRSSI'}))
        % Hide AggregatedMPDU and LastRSSI for control PHY
        flag = strcmp(phyType(obj),'Control');
    elseif strcmp(prop,'BeamTrackingRequest')
        % Hide BeamTrackingRequest for control PHY of when TrainingLength
        % is 0
        flag = strcmp(phyType(obj),'Control') | obj.TrainingLength==0;
    end
  end
end

methods (Access = private)
  function s = privInfo(obj)
    %privInfo Returns information relevant to the object
    %   S = privInfo(CFGDMG) returns a structure, S, containing the
    %   relevant information for the wlanDMGConfig object, CFGDMG.
    %   The output structure S has the following fields:
    %
    %   NumPPDUSamples - The number of samples in the PPDU.
    %   TxTime         - The time in microseconds, required to
    %                    transmit the PPDU.
    %   PSDULength     - The PSDU length in octets (bytes).

    % Calculate number of OFDM symbols
    txTime = plmeTXTIMEPrimitive(obj); % microseconds
    
    % Calculate burst time in samples   
    FS = 2640e6;   % OFDM sample rate, Table 21-4
    FC = FS*(2/3); % SC chip rate, 1760 MHz, Table 21-4
    TC = 1/FC;     % SC chip time, 0.57 Nanoseconds (1/Fc), Table 21-4
    TS = 1/FS;     % OFDM sample time, (1/Fs), Table 21-4
    if strcmp(phyType(obj),'OFDM')
        numPPDUSamples = round(txTime/(TS*1e6));
    else % SC or control
        numPPDUSamples = round(txTime/(TC*1e6));
    end

    s = struct(...
        'NumPPDUSamples', numPPDUSamples, ...
        'TxTime',         txTime, ...
        'PSDULength',     obj.PSDULength);
  end

  function s = validateMCSLength(obj)
    %validateMCSLength Validate MCS and Length properties for
    %   wlanDMGConfig configuration object
    s = privInfo(obj);
    
    % Validate PSDULength is between 14 and 1023, inclusive, for control PHY
    coder.internal.errorIf(strcmp(phyType(obj),'Control')&&(obj.PSDULength<14||obj.PSDULength>1023),'wlan:wlanDMGConfig:InvalidPSDULength')
  end

  function s = validateMCSLengthTxTime(obj)
    %validateMCSLengthTxTime Validate MCS and Length properties, and
    %   resultant TXTIME for wlanDMGConfig configuration object
    s = validateMCSLength(obj);
    
    % Validate txTime
    aPPDUMaxTime = 2e3; % Max microseconds, aPPDUMaxTime, Table 21-31
    coder.internal.errorIf(s.TxTime>aPPDUMaxTime,'wlan:shared:InvalidPPDUDuration',round(s.TxTime),aPPDUMaxTime);
  end
  
  function validateScramblerInitialization(obj)
    if strcmp(phyType(obj),'Control')
        if isscalar(obj.ScramblerInitialization)
            % Check for correct range
            coder.internal.errorIf(any((obj.ScramblerInitialization<1) | (obj.ScramblerInitialization>15)), ...
                'wlan:wlanDMGConfig:InvalidScramblerInitialization','Control',1,15,4);
        else
            % Check for non-zero binary vector
            coder.internal.errorIf( ...
                any((obj.ScramblerInitialization~=0) & (obj.ScramblerInitialization~=1)) || (numel(obj.ScramblerInitialization)~=4) ...
                || all(obj.ScramblerInitialization==0) || (size(obj.ScramblerInitialization,1)~=4), ...
                'wlan:wlanDMGConfig:InvalidScramblerInitialization','Control',1,15,4);
        end
    elseif wlan.internal.isDMGExtendedMCS(obj.MCS)
        % At least one of the initialization bits must be non-zero,
        % therefore determine if the pseudorandom part can be 0 given the
        % extended MCS and PSDU length.
        if all(wlan.internal.dmgExtendedMCSScramblerBits(obj)==0)
            minScramblerInit = 1; % Pseudorandom bits cannot be all zero
        else
            minScramblerInit = 0; % Pseudorandom bits can be all zero
        end
        
        if isscalar(obj.ScramblerInitialization)
            % Check for correct range
            coder.internal.errorIf(any((obj.ScramblerInitialization<minScramblerInit) | (obj.ScramblerInitialization>31)), ...
                'wlan:wlanDMGConfig:InvalidScramblerInitialization','SC extended MCS',minScramblerInit,31,5);
        else
            % Check for non-zero binary vector
            coder.internal.errorIf( ...
                any((obj.ScramblerInitialization~=0) & (obj.ScramblerInitialization~=1)) || (numel(obj.ScramblerInitialization)~=5) ...
                || (minScramblerInit&&all(obj.ScramblerInitialization==0)) || (size(obj.ScramblerInitialization,1)~=5), ...
                'wlan:wlanDMGConfig:InvalidScramblerInitialization','SC extended MCS',minScramblerInit,31,5);
        end
    else
        if isscalar(obj.ScramblerInitialization)
            % Check for correct range
            coder.internal.errorIf(any((obj.ScramblerInitialization<1) | (obj.ScramblerInitialization>127)), ...
                'wlan:wlanDMGConfig:InvalidScramblerInitialization','SC/OFDM',1,127,7);
        else
            % Check for non-zero binary vector
            coder.internal.errorIf( ...
                any((obj.ScramblerInitialization~=0) & (obj.ScramblerInitialization~=1)) || (numel(obj.ScramblerInitialization)~=7) ...
                || all(obj.ScramblerInitialization==0) || (size(obj.ScramblerInitialization,1)~=7), ...
                'wlan:wlanDMGConfig:InvalidScramblerInitialization','SC/OFDM',1,127,7);
        end
    end 
  end
  
  % TXTIME calculation in Section 21.12.3 IEEE 802.11ad-2012
  %   TXTIME is the transmission time in microseconds
  function TXTIME = plmeTXTIMEPrimitive(obj)
    
    FS = 2640e6;   % OFDM sample rate, Table 21-4
    FC = FS*(2/3); % SC chip rate, 1760 MHz, Table 21-4
    TC = 1/FC;     % SC chip time, 0.57 Nanoseconds (1/Fc), Table 21-4
    TSEQ = 128*TC; % 72.7 nanoseconds, Table 21-4
    Length = obj.PSDULength;
    if wlan.internal.isBRPPacket(obj)
        NTRN = obj.TrainingLength/4;  % Training field length defined in header, assume number of groups of 4
    else
        NTRN = 0;
    end
    TTRN_Unit = 4992*TC;     % aBRPTRNBlock*TC, Table 21-31

    if strcmp(phyType(obj),'Control')
        TSTF_CP = 50*TSEQ; % Control PHY short training field duration, 3.636 microseconds, Table 21-4
        TCE_CP = 9*TSEQ;   % Control PHY channel estimation field duration, 655 nanoseconds, Table 21-4
        p = wlan.internal.dmgControlEncodingInfo(obj);
        TXTIME = TSTF_CP+TCE_CP+(11*8+(Length-6)*8+p.NCW*168)*TC*32+NTRN*TTRN_Unit;
    else
        TSTF = 17*TSEQ; % SC/OFDM PHY short training field duration, 1236 nanoseconds, Table 21-4
        TCE = 9*TSEQ;   % SC/OFDM PHY channel estimation field duration, 655 nanoseconds, Table 21-4
        
        % From Table 21-31
        alpha = 18;  % aBRPminSCblocks, Table 21-31
        beta = 512;  % aSCBlockSize, Table 21-31
        gamma = 64;  % aSCGILength, Table 21-31
        delta = 20;  % aBRPminOFDMblocks, Table 21-31
        
        if strcmp(phyType(obj),'SC')
            % SC PHY
            Theader = 2*512*TC; % Header duration, 0.582e3 Nanoseconds , Table 21-4
            p = wlan.internal.dmgSCEncodingInfo(obj);
            TData = (p.NBLKS*512+64)*TC;
            if NTRN>0
                TXTIME = TSTF+TCE+Theader+max(TData,(alpha*beta+gamma)*TC)+NTRN*TTRN_Unit;
            else
                TXTIME = TSTF+TCE+Theader+TData;
            end
        else
            % OFDM PHY
            TDFT = 512/FS;
            TGI = TDFT/4;
            TSYM = TDFT+TGI; % Symbol duration, 0.242e3 nanoseconds, Table 21-4
            Theader = TSYM;  % Header duration, 0.242e3 nanoseconds (Tsym), Table 21-4
           
            p = wlan.internal.dmgOFDMEncodingInfo(obj);
            TData = p.NSYM*TSYM;
            if NTRN>0
                TXTIME = TSTF+TCE+Theader+max(TData,delta*TSYM)+NTRN*TTRN_Unit;
            else
                TXTIME = TSTF+TCE+Theader+TData;
            end
        end
    end
    TXTIME = TXTIME*1e6; % Convert seconds to microseconds
  end
end

end

