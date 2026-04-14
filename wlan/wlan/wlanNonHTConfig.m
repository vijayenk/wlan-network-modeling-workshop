classdef wlanNonHTConfig < comm.internal.ConfigBase
%wlanNonHTConfig Create a non-HT format configuration object
%   CFGNONHT = wlanNonHTConfig creates a non-HT format configuration
%   object. This object contains the transmit parameters for the OFDM
%   and DSSS modulations of the IEEE 802.11a/b/g/j/p standards.
%
%   CFGNONHT = wlanNonHTConfig(Name,Value) creates a non-HT object,
%   CFGNONHT, with the specified property Name set to the specified
%   Value. You can specify additional name-value pair arguments in any
%   order as (Name1,Value1,...,NameN,ValueN).
%
%   wlanNonHTConfig methods:
%
%   packetFormat   - Non-HT packet format
%   scramblerRange - Scrambler initialization range
%   transmitTime   - Time required to transmit a packet
%
%   wlanNonHTConfig properties:
%
%   Modulation             - Modulation type
%   ChannelBandwidth       - Channel bandwidth (MHz) for OFDM modulation
%   InactiveSubchannels    - Indicates punctured 20 MHz subchannels
%   MCS                    - Modulation and coding scheme for OFDM modulation
%   DataRate               - Data rate for DSSS modulation
%   Preamble               - Preamble type for DSSS modulation
%   LockedClocks           - Clock locking indication for DSSS modulation
%   PSDULength             - Length of the PSDU in bytes
%   NumTransmitAntennas    - Number of transmit antennas
%   CyclicShifts           - Cyclic shift values for >8 transmit chains
%   PhaseRotation          - Phase rotation values for 320 MHz
%   SignalChannelBandwidth - Signal channel bandwidth in the scrambler sequence
%   BandwidthOperation     - Signal bandwidth operation in the scrambler sequence

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

% Define properties in order of intended display
% Public properties
    properties (SetAccess = 'public')
        %Modulation Modulation type
        %   Specify the modulation type as one of 'OFDM' | 'DSSS' for the
        %   non-HT transmission packet. The default is 'OFDM'.
        Modulation = 'OFDM';

        %ChannelBandwidth Channel bandwidth (MHz) for OFDM modulation
        %   Specify the channel bandwidth for the packet as one of 'CBW20',
        %   'CBW10', or 'CBW5' to indicate 20MHz or 10MHz or 5MHz use
        %   respectively, or 'CBW40', 'CBW80', 'CBW160', 'CBW320', to
        %   indicate non-HT duplicate. The default is 'CBW20'.
        ChannelBandwidth = 'CBW20';

        %InactiveSubchannels Indicates punctured 20 MHz subchannels in a non-HT duplicate packet
        %   Specify inactive 20 MHz subchannels as a logical vector. The
        %   number of elements must be 1 or equal to the number of 20 MHz
        %   subchannels given ChannelBandwidth. Set an element to true if a
        %   20 MHz subchannel is inactive (punctured). Subchannels are
        %   ordered from lowest to highest absolute frequency. If a scalar
        %   is provided, this value is assumed for all subchannels. This
        %   property applies only when ChannelBandwidth is 'CBW80',
        %   'CBW160', or 'CBW320'. At least one subchannel must be active.
        %   The default value for this property is false.
        InactiveSubchannels logical = false;

        %MCS OFDM modulation and coding scheme
        %   Specify the modulation and coding scheme used for the
        %   transmission of a PPDU in the range of 0 to 7, inclusive, for
        %   OFDM modulation. The default is 0.
        MCS (1,1) {mustBeUnderlyingType(MCS,"double"),mustBeInteger,mustBeInRange(MCS,0,7)} = 0;

        %DataRate Data rate in Mbps for DSSS modulation
        %   Specify the rate used to transmit the PSDU as one of the
        %   following:
        %   '1Mbps'           - Differential Binary Phase Shift Keying
        %                       (DBPSK) modulation with 1Mbps data rate.
        %   '2Mbps'           - Differential Quadrature Phase Shift Keying
        %                       (DQPSK) modulation with 2Mbps data rate.
        %   '5.5Mbps'         - Complementary Code Keying (CCK) modulation
        %                       with 5.5Mbps data rate.
        %   '11Mbps'          - Complementary Code Keying (CCK) modulation
        %                       with 11Mbps data rate.
        % The default is '1Mbps'.
        DataRate = '1Mbps';

        %Preamble Preamble type for DSSS modulation
        %   Specify the PLCP preamble type as one of 'Long' | 'Short' to
        %   indicate use of the long PLCP preamble and short PLCP preamble
        %   respectively. For HR/DSSS modulation (Clause 17), the short
        %   PLCP preamble corresponds to the HR/DSSS/short mode. The
        %   default is 'Long'.
        Preamble = 'Long';

        %LockedClocks Clock locking indication for DSSS modulation
        %   Specify the "locked clocks bit" (b2) of the SERVICE field as
        %   one of true | false to indicate if the PHY implementation has
        %   its transmit frequency and symbol clocks derived from the same
        %   oscillator. For ERP-DSSS/CCK modulation, the PHY standard
        %   (Clause 19.1.3) requires that the implementation has locked
        %   clocks (b2 = 1) therefore LockedClocks should be set to true.
        %   The default is true.
        LockedClocks (1,1) logical = true;

        %PSDULength PSDU length
        %   Specify the PSDU length, in bytes, for the data carried in a
        %   packet. The PSDU length must be between 1 and 4095, inclusive.
        %   The default is 1000 bytes.
        PSDULength (1,1) {mustBeUnderlyingType(PSDULength,"double"),mustBeInteger,mustBeInRange(PSDULength,1,4095)} = 1000;

        %NumTransmitAntennas Number of transmit antennas
        %   Specify the number of transmit antennas as a numeric, positive
        %   integer scalar. The default is 1.
        NumTransmitAntennas (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThan(NumTransmitAntennas,0)} = 1;

        %CyclicShifts Cyclic shift values for >8 transmit chains
        %   Specify the cyclic shift values in nanoseconds for >8 transmit
        %   antennas as a row vector of length L = NumTransmitAntennas-8.
        %   The cyclic shift values must be between -200 and 0 inclusive.
        %   The first 8 antennas use the cyclic shift values defined in
        %   Table 21-10 of IEEE Std 802.11-2016. The remaining antennas use
        %   the cyclic shift values defined in this property. If the length
        %   of this row vector is specified as a value greater than L the
        %   object only uses the first L, CyclicShifts values. For example,
        %   if you specify the NumTransmitAntennas property as 16 and this
        %   property as a row vector of length N>L, the object only uses
        %   the first L = 16-8 = 8 entries. This property applies only when
        %   you set the NumTransmitAntennas property to a value greater
        %   than 8. The default value of this property is -75.
        CyclicShifts {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(CyclicShifts,-200), mustBeLessThanOrEqual(CyclicShifts,0)}  = -75;

        %PhaseRotation Phase rotation values for 320 MHz
        %   Specify the phase rotation values of the waveform as a row
        %   vector of size 1-by-16. Each element of the vector corresponds
        %   to a 20 MHz subchannel in increasing order of frequency as
        %   defined in Equation 36-13 of IEEE P802.11be/D5.0. This property
        %   only applies when ChannelBandwidth is CBW320. The default value
        %   is [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1 1].
        PhaseRotation (1,16) {mustBeNumeric,mustBeFinite,mustBeNonzero} = [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1 1];

        %SignalChannelBandwidth Signal channel bandwidth in the scrambler sequence
        %   Signal channel bandwidth using the scrambler initial sequence
        %   as per IEEE Std 802.11-2016 Section 17.3.5.5. Set to true to
        %   signal the channel bandwidth. This property only applies if
        %   ChannelBandwidth is greater than or equal to 'CBW20'. The
        %   default is false.
        SignalChannelBandwidth (1,1) logical = false;

        %BandwidthOperation Signal bandwidth operation in the scrambler sequence
        %   Signal bandwidth operation using the scrambler initial sequence
        %   as per IEEE Std 802.11-2016 Section 17.3.5.5.
        %   BandwidthOperation must be 'Dynamic', 'Static' or 'Absent'.
        %   When 'Absent' the bandwidth operation is not signaled. This
        %   property only applies if ChannelBandwidth is greater than or
        %   equal to 'CBW20', and SignalChannelBandwidth is true. The
        %   default is 'Absent'.
        BandwidthOperation = 'Absent';

    end

    properties(Constant, Hidden)
        Modulation_Values = {'OFDM', 'DSSS'};
        ChannelBandwidth_Values = {'CBW320','CBW160','CBW80','CBW40','CBW20', 'CBW10', 'CBW5'};
        DataRate_Values = {'1Mbps', '2Mbps', '5.5Mbps', '11Mbps'};
        Preamble_Values = {'Long', 'Short'};
        BandwidthOperation_Values = {'Absent','Static','Dynamic'};
    end

    methods
        function obj = wlanNonHTConfig(varargin)
        % For codegen set maximum dimensions to force varsize
            if ~isempty(coder.target)
                channelBandwidth = 'CBW20';
                coder.varsize('channelBandwidth',[1 6],[0 1]); % Add variable-size support
                obj.ChannelBandwidth = channelBandwidth; % Default

                dataRate = '1Mbps';
                coder.varsize('DataRate',[1 7],[0 1]); % Add variable-size support
                obj.DataRate = dataRate; % Default

                preamble = 'Long';
                coder.varsize('preamble',[1 5],[0 1]); % Add variable-size support
                obj.Preamble = preamble; % Default

                bandwidthOperation = 'Absent';
                coder.varsize('bandwidthOperation',[1 7],[0 1]); % Add variable-size support
                obj.BandwidthOperation = bandwidthOperation; % Default
            end
            obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
        end

        % Self-validate and set properties
        function obj = set.Modulation(obj,val)
            val = validateEnumProperties(obj, 'Modulation', val);
            obj.Modulation = val;
        end

        function obj = set.ChannelBandwidth(obj,val)
            val = validateEnumProperties(obj, 'ChannelBandwidth', val);
            obj.ChannelBandwidth = val;
        end

        function obj = set.BandwidthOperation(obj,val)
            val = validateEnumProperties(obj, 'BandwidthOperation', val);
            obj.BandwidthOperation = val;
        end

        function obj = set.DataRate(obj,val)
            val = validateEnumProperties(obj, 'DataRate', val);
            obj.DataRate = val;
        end

        function obj = set.Preamble(obj,val)
            val = validateEnumProperties(obj, 'Preamble', val);
            obj.Preamble = val;
        end

        function format = packetFormat(obj) %#ok<MANU>
            %packetFormat Returns the packet format
            %   Returns the packet format as a character vector
            format = 'Non-HT';
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
            if strcmp(obj.Modulation, 'OFDM')
                txTime = privInfo(obj).TxTime;
            else
                txTime = wlan.internal.dsssInfo(obj).TxTime;
            end
            t = wlan.internal.convertTransmitTime(txTime,varargin{:});
        end


        function varargout = validateConfig(obj, varargin)
        % validateConfig Validate the wlanNonHTConfig object.
        %
        %   validateConfig(CFGNONHT) validates the dependent properties
        %   for the specified wlanNonHTConfig parameter object.

        %   For INTERNAL use only, subject to future changes:
        %
        %   validateConfig(CFGNONHT, MODE) validates only the subset of
        %   dependent properties as specified by the MODE input.
        %   MODE must be one of: TBD

            narginchk(1,2);
            nargoutchk(0,1);
            if (nargin==2)
                mode = varargin{1};
            else
                mode = 'Full';
            end

            s = struct('NumDataSymbols', -1, ...
                       'NumPadBits',     -1, ...
                       'NumPPDUSamples', -1, ...
                       'TxTime',         -1, ...
                       'PSDULength',     obj.PSDULength); % PSDULength always valid

            if strcmp(obj.Modulation, 'OFDM')
                if strcmp(mode, 'Full')
                    validateCyclicShifts(obj); % Validate CyclicShifts values against NumTransmitAntennas
                    validateInactiveSubchannels(obj);
                    s = validate(obj);
                elseif strcmp(mode, 'CyclicShift')
                    % Validate CyclicShifts and InactiveSubchannels - used
                    % for all field apart from Data
                    validateCyclicShifts(obj);
                    validateInactiveSubchannels(obj);
                end
                % else
                % None needed for DSSS
            end

            if nargout==1
                varargout{1} = s;
            end

        end % end of validation function

        function [range,numBits] = scramblerRange(cfgNonHT)
        %scramblerRange Scrambler initialization range
        %   [RANGE,NUMBITS] = scramblerRange(CFGNONHT) returns the range
        %   and number of pseudorandom bits required for scrambler
        %   initialization given the bandwidth signaling configuration.
        %
        %   RANGE is a 1-by-2 vector [MIN MAX] giving the minimum and
        %   maximum value of the pseudorandom bits required for scrambler
        %   initialization.
        %
        %   NUMBITS is a scalar giving the required number of pseudorandom
        %   scrambler initialization bits required by wlanWaveformGenerator
        %   and wlanNonHTData.

            bandwidthSignaling = any(strcmp(cfgNonHT.ChannelBandwidth,{'CBW20','CBW40','CBW80','CBW160','CBW320'})) && cfgNonHT.SignalChannelBandwidth;

            % The number of required bits depends on dynamic bandwidth
            % signaling, IEEE Std 802.11-2016 Table 17-7.
            if bandwidthSignaling
                if strcmp(cfgNonHT.BandwidthOperation,'Absent')
                    numBits = 5;
                else
                    numBits = 4;
                end
                if any(strcmp(cfgNonHT.ChannelBandwidth,{'CBW20','CBW320'})) && ~strcmp(cfgNonHT.BandwidthOperation,'Dynamic') % Table 17-7 of IEEE P802.11be/D5.0
                    minVal = 1;
                else
                    minVal = 0;
                end
            else
                numBits = 7;
                minVal = 1;
            end

            maxVal = 2^numBits-1;
            range = [minVal,maxVal];
        end
    end

    methods (Access=protected)
        function flag = isInactiveProperty(obj, prop)
        % Controls the conditional display of properties

            flag = false;
            isOFDM = strcmp(obj.Modulation, 'OFDM');

            switch prop
                % ChannelBandwidth only for OFDM
              case 'ChannelBandwidth'
                flag = ~isOFDM;

                % NumTransmitAntennas only for OFDM and for bandwidths >=CBW20
              case 'NumTransmitAntennas'
                flag = ~(isOFDM && any(strcmp(obj.ChannelBandwidth, {'CBW20','CBW40','CBW80','CBW160'})));

                % MCS only for OFDM
              case 'MCS'
                flag = ~isOFDM;

                % Hide CyclicShifts when modulation is DSSS,
                % NumTransmitAntennas <=8 and the ChannelBandwidth is CBW5 or
                % CBW10
              case 'CyclicShifts'
                flag = ~(isOFDM && obj.NumTransmitAntennas>8 && any(strcmp(obj.ChannelBandwidth, {'CBW20','CBW40','CBW80','CBW160'})));

                % DataRate only for DSSS
              case 'DataRate'
                flag = isOFDM;

                % Preamble only for DSSS and for DataRate > 1 Mbps
              case 'Preamble'
                flag = isOFDM || strcmp(obj.DataRate, '1Mbps');

                % LockedClocks only for DSSS
              case 'LockedClocks'
                flag = isOFDM;

              case 'InactiveSubchannels'
                % Hide InactiveSubchannels for when ChannelBandwidth is
                % CBW5, CBW10, CBW20, and 'CBW40'
                flag = ~(isOFDM && any(strcmp(obj.ChannelBandwidth, {'CBW80','CBW160','CBW320'})));

              case 'SignalChannelBandwidth'
                % Hide InactiveSubchannels for when ChannelBandwidth is
                % CBW5, CBW10, CBW20, and 'CBW40'
                flag = ~(isOFDM && any(strcmp(obj.ChannelBandwidth, {'CBW20','CBW40','CBW80','CBW160','CBW320'})));

              case 'BandwidthOperation'
                % Hide InactiveSubchannels for when ChannelBandwidth is
                % CBW5, CBW10, CBW20, and 'CBW40'
                flag = ~(isOFDM && obj.SignalChannelBandwidth && any(strcmp(obj.ChannelBandwidth, {'CBW20','CBW40','CBW80','CBW160','CBW320'})));

              case 'PhaseRotation'
                % Hide PhaseRotation for all bandwidth except 320 MHz
                flag = ~strcmp(obj.ChannelBandwidth, 'CBW320') || ~isOFDM;

            end
        end
    end

    methods (Access=private)
        function s = privInfo(obj)
        %privInfo Returns information relevant to the object
        %   S = privInfo(CFGNONHT) returns a structure, S, containing
        %   the relevant information for the wlanNonHTConfig object,
        %   CFGNONHT. Only OFDM modulation type is supported.
        %
        %   The output structure S has the following fields:
        %
        %   NumDataSymbols - Number of OFDM symbols for the Data field
        %   NumPadBits     - Number of pad bits in the Data field
        %   NumPPDUSamples - Number of PPDU samples per transmit antenna
        %   TxTime         - The time in microseconds, required to
        %                    transmit the PPDU.
        %   PSDULength     - The PSDU length in octets (bytes)

        % Compute the number of OFDM symbols in Data field
            mcsTable  = wlan.internal.getRateTable(obj);
            numDBPS = mcsTable.NDBPS;

            Ntail = 6; Nservice = 16;
            numDataSym = ceil((8*obj.PSDULength + Nservice + Ntail)/numDBPS);
            numPadBits = numDataSym * numDBPS - (8*obj.PSDULength + Nservice + Ntail);

            % Compute the number of PPDU samples at CBW
            Nfft = wlan.internal.cbw2nfft(obj.ChannelBandwidth);
            cpLen = Nfft/4; % Always long

            numSymbols = 2 + 2 + 1 + numDataSym;
            numSamples = numSymbols*(Nfft + cpLen);
            switch obj.ChannelBandwidth
              case 'CBW10'
                txTime = numSymbols*8;
              case 'CBW5'
                txTime = numSymbols*16;
              otherwise % CBW20
                txTime = numSymbols*4;
            end

            % Set output structure
            s = struct('NumDataSymbols', numDataSym, ...
                       'NumPadBits',     numPadBits, ...
                       'NumPPDUSamples', numSamples, ...
                       'TxTime',         txTime, ...
                       'PSDULength',     obj.PSDULength);
        end

        function s = validate(obj)
            s = privInfo(obj);
        end

        function validateCyclicShifts(obj)
        %validateCyclicShifts Validate CyclicShifts values against NumTransmitAntennas

            numTx = obj.NumTransmitAntennas;
            csh = obj.CyclicShifts;
            if numTx>8
                coder.internal.errorIf(~(numel(csh)>=numTx-8),'wlan:shared:InvalidCyclicShift','CyclicShifts',numTx-8);
            end
        end

        function validateInactiveSubchannels(obj)
        %validateInactiveSubchannels Validate InactiveSubchannels of wlanHESUConfig object
        %   Validated property-subset includes:
        %     Modulation, ChannelBandwidth, InactiveSubchannels

            if ~isInactiveProperty(obj,'InactiveSubchannels')
                wlan.internal.validateInactiveSubchannels(obj);
            end
        end
    end
end

