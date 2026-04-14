function [eqSym,csi] = wlanEHTEqualize(sym,chEst,noiseEst,cfg,field,userIdx)
%wlanEHTEqualize EHT fields frequency domain channel equalization
%   [EQSYM,CSI] = wlanEHTEqualize(SYM,CHEST,NOISEEST,CFG,FIELD) returns the
%   equalized symbols EQSYM and soft channel state information CSI by
%   performing minimum mean squared equalization (MMSE) or zero-forcing
%   (ZF) on the OFDM symbols SYM using the channel estimate CHEST and noise
%   estimate NOISEEST. For Pre-EHT field equalization, if applicable, the
%   content channels are merged prior to equalization.
%
%   SYM is a Nsc-by-Nsym-by-Nr array of real or complex values, where Nsc
%   is the number of OFDM subcarriers, Nsym is the number of symbols, and
%   Nr is the number of receive antennas.
%
%   CHEST is a real or complex array for which dimensions are
%   Nsc-by-1-by-Nr for Pre-EHT field equalization or Nsc-by-Nsts-by-Nr for
%   data field equalization. Nsts is the number of space time streams
%   specified in the CFG object.
%
%   NOISEEST is a nonnegative real scalar value. If NOISEEST is 0 the
%   function chooses the ZF algorithm. Otherwise, the MMSE algorithm is
%   used.
%
%   CFG is a wlanEHTTBConfig, wlanEHTMUConfig, or wlanEHTRecoveryConfig
%   object.
%
%   FIELD is a character array or string scalar specifying which field the
%   SYM, CHEST, and NOISEEST inputs correspond to. FIELD must be one of
%   "L-SIG", "RL-SIG", "U-SIG", "EHT-SIG", or "EHT-Data". The "EHT-SIG"
%   value only applies when CFG is a wlanEHTMUConfig or
%   wlanEHTRecoveryConfig object.
%
%   EQSYM is a real or complex array that represents the equalized symbols.
%
%   #   When FIELD is "U-SIG", EQSYM dimensions are L*Nsc-by-Nsym where
%       Nsc is the number of pilots, data, or pilots+data subcarriers in a
%       20 MHz channel bandwidth and L is the number of subblocks. L is 1
%       for a 20, 40, and 80 MHz channel bandwidth, L is 2 for a 160 MHz
%       channel bandwidth, or L is 4 for a 320 MHz channel bandwidth.
%   #   When FIELD is "EHT-SIG" and the PPDU type is MU non-OFDMA, EQSYM
%       dimensions are C*Nsc-by-Nsym and C is the number of content
%       channels. C is 1 for a 20 MHz channel bandwidth. Otherwise, C is 2
%       for all other channel bandwidths.
%   #   When FIELD is "EHT-SIG" and the PPDU type is MU OFDMA, EQSYM
%       dimensions are C*L*Nsc-by-Nsym.
%   #   When FIELD is "EHT-SIG" and the PPDU type is SU or NDP, EQSYM
%       dimension are Nsc-by-Nsym.
%   #   When FIELD is "EHT-Data", EQSYM dimensions are Nsc-by-Nsym-by-Nsts
%       where Nsc is the number of subcarriers in the SYM input and Nsts is
%       the number of space time streams in the CHEST input.
%   #   For all other FIELD values, EQSYM dimensions are Nsc-by-Nsym where
%       Nsc is the number of pilots, data, or pilots+data subcarriers in a
%       20 MHz channel bandwidth.
%
%   CSI is a Nsc-by-1 or a Nsc-by-Nsts array that represents the soft
%   channel state information. Nsc is equal to the first dimension of the
%   EQSYM output.
%
%   [EQSYM,CSI] = wlanEHTEqualize(...,USERIDX) also specifies the user
%   index and is required when CFG is a wlanEHTMUConfig object, FIELD is
%   "EHT-Data", and the PPDU type is MU OFDMA or MU non-OFDMA.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

    arguments
        sym (:,:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        chEst (:,:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        noiseEst (1,1) {mustBeFloat,mustBeFinite,mustBeNonnegative}
        cfg (1,1) {mustBeA(cfg,{'wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig'})}
        field {mustBeTextScalar}
        userIdx = 1
    end

    % Validate field value
    pFormat = packetFormat(cfg);
    if matches(pFormat,"EHT-MU")
        fieldVal = validatestring(field,{'L-SIG','RL-SIG','U-SIG','EHT-SIG','EHT-Data'},mfilename,"FIELD");
    else
        fieldVal = validatestring(field,{'L-SIG','RL-SIG','U-SIG','EHT-Data'},mfilename,"FIELD");
    end

    % Verify userIdx supplied for EHT-MU Config in OFDMA or MU-MIMO mode
    % and when field is EHT-Data
    compMode = compressionMode(cfg);
    if isa(cfg,"wlanEHTMUConfig") && matches(fieldVal,"EHT-Data") && ...
            any(compMode==[0 2]) && nargin ~= 6
        coder.internal.error('wlan:shared:ExpectedUserNumber');
    end

    % Verify compression mode has been defined for a recovery object only
    % when equalizing EHT-SIG
    if isa(cfg,"wlanEHTRecoveryConfig") && matches(fieldVal,"EHT-SIG")
        wlan.internal.mustBeDefined(compMode,"CompressionMode");
    end

    % Validate inputs and determine number of unique subcarriers in a 20
    % MHz subchannel and number of 80 MHz subblocks
    [nSCUniqueDefault,nSubblock80] = wlan.internal.validateEqualizerInputs(sym,chEst,cfg,fieldVal,userIdx,mfilename);
    alg = wlan.internal.determineEqualizerAlgorithm(noiseEst);
    if matches(fieldVal,"EHT-Data")
        [eqSymAllUsers,csiAllUsers] = wlan.internal.equalize(sym,chEst,alg,noiseEst);
        [eqSym,csi] = wlan.internal.getUserSTS(eqSymAllUsers,csiAllUsers,cfg,userIdx);
    else % Pre-EHT equalization
         % Preform Pre- field merging as necessary then equalize
        nSC = size(sym,1);
        if matches(fieldVal,"U-SIG")
            % Each 20 MHz subchannel per 80 MHz subblock to be merged.
            nSCUnique = nSCUniqueDefault;
        elseif matches(fieldVal,"EHT-SIG") && compMode == 0
            % Each 40 MHz subchannel per 80 MHz subblock to be merged.
            % Confirm nSCUnique is no larger than nSC in sym.
            nSCUnique = min(nSC,nSCUniqueDefault*2);
        elseif matches(fieldVal,"EHT-SIG") && compMode == 2
            % Each 40 MHz subchannel to be merged. Confirm nSCUnique is no
            % larger than nSC in sym.
            nSCUnique = min(nSC,nSCUniqueDefault*2);
            % Override nSubblock80 as 40 MHz subchannels across the entire
            % channel are the same
            nSubblock80 = 1;
        else % "L-SIG", "RL-SIG", and "EHT-SIG" && compMode == 1
             % Each 20 MHz sub-channel to be merged.
            nSCUnique = nSCUniqueDefault;
            % Override nSubblock80 as 20 MHz subchannels across the entire
            % channel are the same
            nSubblock80 = 1;
        end

        % Merge content channels
        [symMerged,chanEstMerged] = wlan.internal.mergeSubcarriers(sym,chEst,nSCUnique,nSubblock80);

        % Equalize data
        [eqSym,csi] = wlan.internal.equalize(symMerged,chanEstMerged,alg,noiseEst);
    end

end
