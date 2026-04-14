function dataBits = wlanDMGDataBitRecover(rx,noiseVarEst,varargin)
%wlanDMGDataBitRecover Recover data bits from DMG Data field
%
%   DATABITS = wlanDMGDataBitRecover(RX,NOISEVAREST,CFGDMG) recovers the
%   data bits given the Data field from a DMG transmission (OFDM, SC, or
%   Control PHY), the noise variance estimate, and the DMG configuration
%   object.
%
%   DATABITS is an int8 column vector of length 8*CFGDMG.PSDULength
%   containing the recovered information bits.
%
%   The contents and size of RX are physical layer dependent:
%
%   SC PHY:      RX is the time-domain DMG-Data field signal, specified
%                as a 448-by-Nblks matrix of real or complex values, where
%                448 is the number of symbols in a DMG-Data symbol and
%                Nblks is the number of DMG-Data blocks.
%
%   OFDM PHY:    RX is the demodulated DMG-Data field OFDM symbols,
%                specified as a 336-by-Nsym matrix of real or complex
%                values, where 336 is the number of data subcarriers in the
%                DMG-Data field and Nsym is the number of OFDM symbols.
%
%   Control PHY: RX is the time-domain signal containing the header
%                and data fields, specified as an Nb-by-1 column vector of
%                real or complex values, where Nb is the number of despread
%                symbols.
%
%   NOISEVAREST is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   CFGDMG is the format configuration object of type wlanDMGConfig, which
%   specifies the parameters for the DMG format.
%
%   DATABITS = wlanDMGDataBitRecover(...,CSI,CFGDMG) uses the channel state
%   information to enhance the demapping of OFDM subcarriers.
%
%   CSI is a 336-by-1 column vector of real values, where 336 is the number
%   of data subcarriers in the DMG-Data field. The function uses this input
%   only if you specify an OFDM PHY configuration in the CFGDMG input.
%   Otherwise, the function ignores this input.
%
%   DATABITS = wlanDMGDataBitRecover(...,Name,Value) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
%
%   'LDPCDecodingMethod'        Specify the LDPC decoding algorithm as one
%                               of these values:
%                               - 'bp'            : Belief propagation (BP)
%                               - 'layered-bp'    : Layered BP
%                               - 'norm-min-sum'  : Normalized min-sum
%                               - 'offset-min-sum': Offset min-sum
%                               The default is 'bp'.
%
%   'MinSumScalingFactor'       Specify the scaling factor for normalized
%                               min-sum LDPC decoding algorithm as a scalar
%                               in the interval (0,1]. This argument
%                               applies only when you set
%                               LDPCDecodingMethod to 'norm-min-sum'. The
%                               default is 0.75.
%
%   'MinSumOffset'              Specify the offset for offset min-sum LDPC
%                               decoding algorithm as a finite real scalar
%                               greater than or equal to 0. This argument
%                               applies only when you set
%                               LDPCDecodingMethod to 'offset-min-sum'. The
%                               default is 0.5.
%
%   'MaximumLDPCIterationCount' Specify the maximum number of iterations in
%                               LDPC decoding as a positive scalar integer.
%                               The default is 12.
%
%   'EarlyTermination'          To enable early termination of LDPC
%                               decoding, set this property to true. Early
%                               termination applies if all parity-checks
%                               are satisfied before reaching the number of
%                               iterations specified in the
%                               'MaximumLDPCIterationCount' input. To let
%                               the decoding process iterate for the number
%                               of iterations specified in the
%                               'MaximumLDPCIterationCount' input, set this
%                               argument to false. The default is true.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

% Check minimum and maximum number of input arguments
narginchk(3,14);

% If input rx is empty then do not attempt to decode; return empty
if isempty(rx)
    dataBits = zeros(0,1,'int8');
    return;
end

csiFlag = 0;
if isa(varargin{1},'wlanDMGConfig')
    % If no CSI input is present
    cfgDMG = varargin{1};
    csi = [];
elseif nargin>3 && isa(varargin{2},'wlanDMGConfig')
    csi = varargin{1};
    cfgDMG = varargin{2};
    csiFlag = 1;
else
    coder.internal.error('wlan:shared:ExpectedDMGObject');
end

% Validate configuration object
validateattributes(cfgDMG,{'wlanDMGConfig'},{'scalar'},mfilename,'DMG format configuration object');

% Input CSI is only required for OFDM PHY
coder.internal.errorIf(~isempty(csi) && ~strcmp(phyType(cfgDMG),'OFDM'),'wlan:shared:InvalidInputCSI');

% Validate and parse P-V pair optional inputs
coder.internal.errorIf((length(varargin)-(1+csiFlag))==1,'wlan:shared:InvalidNumOptionalInputs');
ldpcParams = wlan.internal.parseOptionalInputs(mfilename,varargin{2+csiFlag:end});

% Validate input
validateattributes(rx,{'double'},{'2d','finite'},mfilename,'input');

% Validate input noise estimate
validateattributes(noiseVarEst,{'double'},{'real','scalar','nonnegative','finite'},mfilename,'noiseVarEst');

if csiFlag
    softBits = wlan.internal.dmgDataDemap(rx,noiseVarEst,csi,cfgDMG);
else
    softBits = wlan.internal.dmgDataDemap(rx,noiseVarEst,cfgDMG);
end

dataBits = wlan.internal.dmgDataDecode(softBits,cfgDMG,...
     ldpcParams.LDPCDecodingMethod,ldpcParams.alphaBeta,ldpcParams.MaximumLDPCIterationCount,ldpcParams.Termination);

end

