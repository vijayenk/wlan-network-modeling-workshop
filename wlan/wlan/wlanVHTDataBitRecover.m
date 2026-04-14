function [bits, vhtsigbCRC] = wlanVHTDataBitRecover(sym,noiseEst,csi,cfg,varargin)
%wlanVHTDataBitRecover Recover bits from VHT data field
%
% Inputs:
%   sym - Equalized data symbols
%   noiseEst - Noise variance of the channel
%   csi - Channel state information based on equalized symbols
%   cfg - wlanVHTConfig object
%   userIdx - User of interest, only required for MU-VHT
% Name-Value Inputs:
%   The following Name-Value inputs are only applicable when
%   cfg.ChannelCoding=='LDPC'
%   'LDPCDecodingMethod' - LDPC decoding algorithm
%   'MinSumScalingFactor' - Scaling factor for the normalized min-sum LDPC
%   decoding algorithm
%   'MinSumOffset' - Offset for the offset min-sum LDPC decoding algorithm
%   'MaximumLDPCIterationCount' - Max number iterations in LDPC decoding
%   'EarlyTermination' - Finish LDPC decoding early if all parity-checks
%   are satisfied
%
% Outputs:
%   bits - Data bits recovered from sym
%   vhtsigbCRC - CRC for the VHT-SIG-B bits recovered from sym

%   Copyright 2024-2025 The MathWorks, Inc.

%#codegen
    arguments
        sym (:,:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        noiseEst (1,1) {mustBeFloat,mustBeFinite,mustBeNonnegative}
        csi (:,:) {mustBeFloat,mustBeFinite,mustBeReal,mustBeNonempty}
        cfg (1,1) {mustBeA(cfg,'wlanVHTConfig')}
    end
    arguments (Repeating)
        varargin
    end
    narginchk(4,15)
    numRequiredInputs = 4;

    % Validate config
    stsVal = cfg.NumSpaceTimeStreams;
    if cfg.STBC
        coder.internal.errorIf(~isscalar(stsVal),'wlan:shared:VectorSTSWithSTBC')
        coder.internal.errorIf(mod(stsVal,2) ~= 0,'wlan:shared:OddNumSTSWithSTBC');
    end
    cfgInfo = validateConfig(cfg,'MCS');

    % Validate userIdx if supplied and is needed to be validated
    userIdxProvided = nargin>numRequiredInputs && isnumeric(varargin{1});
    validateUserIdx = ~cfg.STBC && ~isscalar(stsVal);
    coder.internal.errorIf(validateUserIdx && ~userIdxProvided,'wlan:shared:ExpectedUserNumber');
    userIdx = 1;
    if userIdxProvided && validateUserIdx
        userIdx = double(varargin{1});
        validateattributes(userIdx,'double',{'scalar','positive','integer'},mfilename,'USERIDX',5);
        stsVecLen = numel(stsVal);
        coder.internal.errorIf(userIdx > stsVecLen,'wlan:shared:InvalidUserIdxWithSTS',userIdx,stsVecLen);
    end

    % Parse NV pairs, if any, and return LDPC parameters
    coder.internal.errorIf(logical(mod(length(varargin)-userIdxProvided,2)),'wlan:shared:InvalidNumOptionalInputs');
    ldpcParams = wlan.internal.getLDPCBitRecoveryParams(mfilename,varargin{userIdxProvided+1:end});

    % Validate subcarrier dimension and extract data only subcarriers
    preVHT = false;
    pOFDMInfo = wlan.internal.getPartialVHTOFDMInfo(cfg.ChannelBandwidth,preVHT);
    [dataSym,dataCSI] = wlan.internal.validateNumSCBitRec(sym,csi,pOFDMInfo);

    % Validate symbol dimension
    [nsc,nsym,nss] = size(sym);
    coder.internal.errorIf(nsym < cfgInfo.NumDataSymbols,'wlan:shared:IncorrectNumOFDMSym',cfgInfo.NumDataSymbols,nsym)

    % Validate spatial stream dimension
    expectedNss = cfg.NumSpaceTimeStreams(userIdx)/(1+cfg.STBC);
    coder.internal.errorIf(nss ~= expectedNss,'wlan:shared:IncorrectNumSS',expectedNss,nss)

    % Validate csi spatial stream dimension
    coder.internal.errorIf(size(csi,2) ~= nss,'wlan:he:InvalidCSISize',nsc,nss)

    % Recover PSDU
    [bits,vhtsigbCRC] = wlan.internal.vhtDataBitRecover(dataSym,noiseEst,dataCSI,cfg,ldpcParams,userIdx);

end
