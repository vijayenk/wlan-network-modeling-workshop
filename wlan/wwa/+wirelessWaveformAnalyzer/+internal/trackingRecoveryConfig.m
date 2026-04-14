classdef trackingRecoveryConfig < comm.internal.ConfigBase
%trackingRecoveryConfig Construct a configuration object for data recovery
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CFGREC = trackingRecoveryConfig constructs a configuration object for
%   recovering the data fields using function which perform sample rate
%   offset tracking: <a href="matlab:help('trackingNonHTDataRecover')">trackingNonHTDataRecover</a>, <a href="matlab:help('trackingHTDataRecover')">trackingHTDataRecover</a>, and
%   <a href="matlab:help('trackingVHTDataRecover')">trackingVHTDataRecover</a>. Adjust the property values of the object,
%   which indicate different algorithm parameters or operations at the
%   receiver, to achieve optimal recovery performance.
%
%   CFGREC = trackingRecoveryConfig(Name,Value) constructs a recovery
%   configuration object, CFGREC, with the specified property Name set to
%   the specified Value. You can specify additional name-value pair
%   arguments in any order as (Name1,Value1,...,NameN,ValueN).
%
%   trackingRecoveryConfig properties:
%
%   OFDMSymbolOffset           - OFDM symbol sampling offset
%   EqualizationMethod         - Equalization method
%   PilotTrackingWindow        - Pilot tracking averaging window
%   PilotTimeTracking          - Pilot time tracking
%   PilotPhaseTracking         - Pilot phase tracking
%   PilotGainTracking          - Pilot gain tracking
%   DataAidedEqualization      - Equalization using data-aided channel estimates
%   IQImbalanceCorrection      - Data field IQ imbalance correction
%   LDPCDecodingMethod         - LDPC decoding algorithm
%   MinSumScalingFactor        - Scaling factor for normalized min-sum LDPC
%                                decoding algorithm
%   MinSumOffset               - Offset for offset min-sum LDPC decoding
%                                algorithm
%   MaximumLDPCIterationCount  - Maximum number of decoding iterations
%   Termination                - Enable early termination of LDPC decoding
%
%   % Example:
%   %    Create a trackingRecoveryConfig object for performing ZF
%   %    equalization, OFDM symbol sampling offset of 0.5, and not pilot
%   %    tracking in a recovery process.
%
%   cfgRec = trackingRecoveryConfig( ...
%       'OFDMSymbolOffset',   0.5, ...
%       'EqualizationMethod', 'ZF')
%
%   See also trackingVHTDataRecover, trackingHTDataRecover,
%   trackingNonHTDataRecover.

% Copyright 2023-2025 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

    properties (Access = 'public')
        %OFDMSymbolOffset OFDM symbol offset
        %   Specify the sampling offset as a fraction of the cyclic prefix (CP)
        %   length for every OFDM symbol, as a double precision, real scalar
        %   between 0 and 1, inclusive. The OFDM demodulation is performed
        %   based on Nfft samples following the offset position, where Nfft
        %   denotes the FFT length. The default value of this property is 0.75,
        %   which means the offset is three quarters of the CP length.
        OFDMSymbolOffset = 0.75;
        %EqualizationMethod Equalization method
        %   Specify the equalization method as one of 'MMSE' | 'ZF'. The
        %   default value of this property is 'MMSE'.
        EqualizationMethod = 'MMSE';
        %PilotTrackingWindow Pilot tracking averaging window
        %   Specify the pilot phase tracking averaging window in OFDM symbols,
        %   as an odd, integer scalar greater than 0. When set to 1, no
        %   averaging is applied. The default is 9. Within the tracking
        %   algorithm the window is truncated to the number of OFDM symbols to
        %   demodulate if required.
        PilotTrackingWindow = 9;
        %PilotTimeTracking Pilot time tracking
        %   Enable or disable pilot time tracking. The default is true.
        PilotTimeTracking (1,1) logical = true;
        %PilotPhaseTracking Pilot phase tracking
        %   Enable or disable pilot phase tracking. The default is true.
        PilotPhaseTracking (1,1) logical = true;
        %PilotGainTracking Pilot gain tracking
        %   Enable or disable pilot gain tracking. The default is false.
        PilotGainTracking (1,1) logical = false;
        %DataAidedEqualization Data-aided equalization using demodulated
        %LTF and data symbols
        %   Enable or disable data aided equalization. The default is false.
        DataAidedEqualization (1,1) logical = false;
        %IQImbalanceCorrection % IQ imbalance estimation and correction.
        %   Enable or disable IQ imbalance correction. The default is false.
        IQImbalanceCorrection (1,1) logical = false;
        %LDPCDecodingMethod LDPC decoding algorithm
        %   Specify the LDPC decoding algorithm as one of these values:
        %       - 'bp'            : Belief propagation (BP)
        %       - 'layered-bp'    : Layered BP
        %       - 'norm-min-sum'  : Normalized min-sum
        %       - 'offset-min-sum': Offset min-sum
        %   The default is 'norm-min-sum'.
        LDPCDecodingMethod = 'norm-min-sum';
        %MinSumScalingFactor Scaling factor for normalized min-sum LDPC decoding algorithm
        %   Specify the scaling factor for normalized min-sum LDPC decoding
        %   algorithm as a scalar in the interval (0,1]. This argument applies
        %   only when you set LDPCDecodingMethod to 'norm-min-sum'. The default
        %   is 0.75.
        MinSumScalingFactor = 0.75;
        %MinSumOffset Offset for offset min-sum LDPC decoding algorithm
        %   Specify the offset for offset min-sum LDPC decoding algorithm as a
        %   finite real scalar greater than or equal to 0. This argument
        %   applies only when you set LDPCDecodingMethod to 'offset-min-sum'.
        %   The default is 0.5.
        MinSumOffset = 0.5;
        %MaximumLDPCIterationCount Maximum number of decoding iterations
        %   Specify the maximum number of iterations in LDPC decoding as an
        %   integer valued numeric scalar. This applies when you set the
        %   channel coding property to LDPC. The default is 12.
        MaximumLDPCIterationCount = 12;
        %Termination Enable early termination of LDPC decoding
        %   One of 'early' or 'max', specifies the decoding termination
        %   criteria. For 'early', the decoding is terminated when all
        %   parity checks are satisfied, up to a maximum number of iterations
        %   given by MaximumLDPCIterationCount. For 'max', decoding continues
        %   till MaximumLDPCIterationCount iterations are completed. The
        %   default is 'max'.
        Termination = 'max';
    end

    properties(Constant, Hidden)
        EqualizationMethod_Values = {'MMSE', 'ZF'};
        LDPCDecodingMethod_Values = {'bp','layered-bp','norm-min-sum','offset-min-sum'};
        Termination_Values = {'early','max'};
    end

    methods
        function obj = trackingRecoveryConfig(varargin)
            obj = obj@comm.internal.ConfigBase('EqualizationMethod', 'MMSE', varargin{:});
        end

        function obj = set.OFDMSymbolOffset(obj, val)
            prop = 'OFDMSymbolOffset';
            validateattributes(val, {'double'}, ...
                               {'real','scalar','>=',0,'<=',1}, ...
                               [class(obj) '.' prop], prop);
            obj.(prop) = val;
        end

        function obj = set.EqualizationMethod(obj, val)
            prop = 'EqualizationMethod';
            validateEnumProperties(obj, prop, val);
            obj.(prop) = '';
            obj.(prop) = val;
        end

        function obj = set.PilotTrackingWindow(obj,val)
            prop = 'PilotTrackingWindow';
            validateattributes(val,{'numeric'}, ...
                               {'real','integer','odd','scalar','>',0}, ...
                               [class(obj) '.' prop], prop);
            obj.(prop) = val;
        end

        function obj = set.LDPCDecodingMethod(obj, val)
            prop = 'LDPCDecodingMethod';
            validateEnumProperties(obj, prop, val);
            obj.(prop) = '';
            obj.(prop) = val;
        end

        function obj = set.MinSumScalingFactor(obj, val)
            prop = 'MinSumScalingFactor';
            validateattributes(val, {'double'}, ...
                               {'real','scalar','>',0,'<=',1}, ...
                               [class(obj) '.' prop], prop);
            obj.(prop) = val;
        end

        function obj = set.MinSumOffset(obj, val)
            prop = 'MinSumOffset';
            validateattributes(val, {'double'}, ...
                               {'real','scalar','>',0}, ...
                               [class(obj) '.' prop], prop);
            obj.(prop) = val;
        end

        function obj = set.MaximumLDPCIterationCount(obj, val)
            prop = 'MaximumLDPCIterationCount';
            validateattributes(val, {'double'}, ...
                               {'real','integer','scalar','>',0}, ...
                               [class(obj) '.' prop], prop);
            obj.(prop) = val;
        end

        function obj = set.Termination(obj, val)
            prop = 'Termination';
            validateEnumProperties(obj, prop, val);
            obj.(prop) = '';
            obj.(prop) = val;
        end
    end

end
