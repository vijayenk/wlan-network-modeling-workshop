function [eqSym,csi] = wlanHEEqualize(sym,chEst,noiseEst,cfg,field,userIdx)
%wlanHEEqualize HE fields frequency domain channel equalization
%   [EQSYM,CSI] = wlanHEEqualize(SYM,CHEST,NOISEEST,CFG,FIELD) returns the
%   equalized symbols EQSYM and soft channel state information CSI by
%   performing minimum mean squared equalization (MMSE) or zero-forcing
%   (ZF) on the OFDM symbols SYM using the channel estimate CHEST and noise
%   estimate NOISEEST. For Pre-HE field equalization, if applicable, the
%   content channels are merged prior to equalization.
%
%   SYM is a Nsc-by-Nsym-by-Nr array of real or complex values, where Nsc
%   is the number of OFDM subcarriers, Nsym is the number of symbols, and
%   Nr is the number of receive antennas.
%
%   CHEST is a real or complex array for which dimensions are
%   Nsc-by-1-by-Nr for Pre-HE field equalization, Nsc-by-2-by-Nr for STBC
%   combining, or Nsc-by-Nsts-by-Nr for data field equalization. Nsts is
%   the number of space time streams specified in the CFG object.
%
%   NOISEEST is a nonnegative real scalar value. If NOISEEST is 0 the
%   function chooses the ZF algorithm. Otherwise, the MMSE algorithm is
%   used.
%
%   CFG is a wlanHESUConfig, wlanHETBConfig, wlanHEMUConfig, or
%   wlanHERecoveryConfig object. For data field equalization, if the STBC
%   property of these objects is 1, then this function performs space time
%   block coding (STBC) combining.
%
%   FIELD is a character array or string scalar specifying which field the
%   SYM, CHEST, and NOISEEST inputs correspond to. FIELD must be one of
%   "L-SIG", "RL-SIG", "HE-SIG-A", "HE-SIG-B", or "HE-Data". The "HE-SIG-B"
%   value only applies when CFG is a wlanHEMUConfig or wlanHERecoveryConfig
%   object.
%
%   EQSYM is a real or complex array that represents the equalized symbols.
%
%   #   When FIELD is "HE-SIG-B", EQSYM dimensions are C*Nsc-by-Nsym where
%       Nsc is the number of pilots, data, or pilots+data subcarriers in a
%       20 MHz channel bandwidth and C is the number of content channels. C
%       is 1 for a 20 MHz channel bandwidth. Otherwise, C is 2 for all
%       other channel bandwidths.
%   #   When FIELD is "HE-Data", EQSYM dimensions are Nsc-by-Nsym-by-Nsts
%       where Nsc is the number of subcarriers in the SYM input and Nsts is
%       the number of space time streams in the CHEST input or Nsts is 1
%       when STBC is true in the CFG object.
%   #   For all other FIELD values, EQSYM dimensions are Nsc-by-Nsym where
%       Nsc is the number of pilots, data, or pilots+data subcarriers in a
%       20 MHz channel bandwidth.
%
%   CSI is a Nsc-by-1 or a Nsc-by-Nsts array that represents the soft
%   channel state information. Nsc is equal to the first dimension of the
%   EQSYM output.
%
%   [EQSYM,CSI] = wlanHEEqualize(...,USERIDX) also specifies the user index
%   and is required when CFG is a wlanHEMUConfig object and FIELD is
%   "HE-Data".

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen
    arguments
        sym (:,:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        chEst (:,:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        noiseEst (1,1) {mustBeFloat,mustBeFinite,mustBeNonnegative}
        cfg (1,1) {mustBeA(cfg,{'wlanHEMUConfig','wlanHESUConfig','wlanHETBConfig','wlanHERecoveryConfig'})}
        field {mustBeTextScalar}
        userIdx = 1
    end

    % Check that the packet format is defined for wlanHERecoveryConfig
    pFormat = packetFormat(cfg);
    if isa(cfg,"wlanHERecoveryConfig")
        wlan.internal.mustBeDefined(pFormat,"PacketFormat")
    end

    % Validate field value
    % The extra conditions are needed for code generation
    if ~matches(pFormat,"HE-MU") && (coder.target("MATLAB") || ~matches(field,"HE-SIG-B","IgnoreCase",true))
        fieldVal = validatestring(field,{'L-SIG','RL-SIG','HE-SIG-A','HE-Data'},mfilename,"FIELD");
    else
        fieldVal = validatestring(field,{'L-SIG','RL-SIG','HE-SIG-A','HE-SIG-B','HE-Data'},mfilename,"FIELD");
    end

    % Verify userIdx supplied for HE-MU Config when field is HE-Data
    if isa(cfg,"wlanHEMUConfig") && matches(fieldVal,"HE-Data") && ...
            nargin ~= 6
        coder.internal.error("wlan:shared:ExpectedUserNumber");
    end

    % Validate inputs and determine number of unique subcarriers in a 20
    % MHz subchannel
    nSCUniqueDefault = wlan.internal.validateEqualizerInputs(sym,chEst,cfg,fieldVal,userIdx,mfilename);

    alg = wlan.internal.determineEqualizerAlgorithm(noiseEst);
    if ~matches(fieldVal,"HE-Data") % Pre-HE equalization
                                    % Preform Pre- field merging as necessary then equalize
        if matches(fieldVal,"HE-SIG-B")
            % Each 40 MHz subchannel to be merged
            nSC = size(sym,1);
            % Confirm nSCUnique is no larger than nSC in sym
            nSCUnique = min(nSC,nSCUniqueDefault*2);
        else % "L-SIG", "RL-SIG", and "HE-SIG-A"
             % Each 20 MHz sub-channel to be merged.
            nSCUnique = nSCUniqueDefault;
        end

        % Merge content channels
        [symMerged,chanEstMerged] = wlan.internal.mergeSubcarriers(sym,chEst,nSCUnique);

        % Equalize data
        [eqSym,csi] = wlan.internal.equalize(symMerged,chanEstMerged,alg,noiseEst);
    elseif cfg.STBC && mod(size(chEst,2),2)==0 % HE-Data STBC combining. Check that second dimension is even (for codegen)
        nSS = size(chEst,2)/2; % Number of spatial streams
        [eqSym,csi] = wlan.internal.stbcCombine(sym,chEst,nSS,alg,noiseEst);
    else % HE-Data equalization
        [eqSymAllUsers,csiAllUsers] = wlan.internal.equalize(sym,chEst,alg,noiseEst);
        [eqSym,csi] = wlan.internal.getUserSTS(eqSymAllUsers,csiAllUsers,cfg,userIdx);
    end
end
