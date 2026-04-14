function [eqSym,csi] = wlanVHTEqualize(sym,chEst,noiseEst,cfg,field,userIdx)
%wlanVHTEqualize Equalize VHT field symbols
%
% Inputs:
%   sym - Symbols to be equalized
%   chEst - Channel estimate
%   noiseEst - Noise estimate
%   cfg - wlanVHTConfig object
%   field - Field being equalized
%   userIdx - User of interest in MU-MIMO situation
%
% Outputs:
%   eqSym - Equalized symbols
%   csi - Channel state information

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    arguments
        sym (:,:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        chEst (:,:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        noiseEst (1,1) {mustBeFloat,mustBeFinite,mustBeNonnegative}
        cfg (1,1) {mustBeA(cfg,{'wlanVHTConfig'})}
        field {mustBeTextScalar}
        userIdx = 1
    end

    fieldVal = validatestring(field,{'L-SIG','VHT-SIG-A','VHT-SIG-B','VHT-Data'},mfilename,'FIELD');

    % Verify userIdx supplied for MU VHT config when VHT-SIG-B or VHT-Data selected
    coder.internal.errorIf(~cfg.STBC && ~isscalar(cfg.NumSpaceTimeStreams) && matches(fieldVal,{'VHT-SIG-B','VHT-Data'}) && nargin ~= 6,'wlan:shared:ExpectedUserNumber');

    % Cross validate inputs
    nsc20MHz = [4 48 52];
    wlan.internal.validateEqualizerInputs(sym,chEst,cfg,fieldVal,userIdx,mfilename,nsc20MHz);

    [eqSym,csi] = wlan.internal.vhtEqualize(sym,chEst,noiseEst,cfg,fieldVal,userIdx);
end
