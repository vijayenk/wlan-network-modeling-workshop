function [eqSymU,csiU] = getUserSTS(eqSym,csi,cfg,userIdx)
%getUserSTS Extract STSs for specified user
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [EQSYMU,CSIU] = getUserSTS(EQSYM,CSI,CFG,USERIDX) returns the data
%   field equalized symbols EQSYMU and the soft channel state information
%   CSIU for a particular user. The USERIDX input applies only when CFG is
%   a wlanHEMUConfig object, a wlanEHTMUConfig object, or a wlanVHTConfig
%   object in an MU configuration. USERIDX determines the indicies for
%   extracting the equalized symbols and CSI.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

% Determine space time stream indicies for the specified user
    stsIdxs = wlan.internal.getSTSIndices(cfg,userIdx);

    % Extract equalized symbols and csi for user
    eqSymU = eqSym(:,:,stsIdxs);
    csiU = csi(:,stsIdxs);

end
