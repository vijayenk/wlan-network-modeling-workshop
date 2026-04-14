function [dataSym,dataCSI] = validateNumSCBitRec(sym,csi,ofdmInfo)
%validateNumSCBitRec Validates and extracts data subcarriers from SYM and CSI
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%

%   Copyright 2025 The MathWorks, Inc.

%#codegen

    nscSym = size(sym,1);
    nscCSI = size(csi,1);

    % Validate correct number of subcarriers
    numData = numel(ofdmInfo.DataIndices);
    onlyData = numData==nscSym;
    coder.internal.errorIf(~(onlyData || ofdmInfo.NumTones==nscSym),"wlan:bitRecovery:InvalidNumSC",nscSym,ofdmInfo.NumTones,numData);

    % Validate number of subcarriers within SYM and CSI are equal
    coder.internal.errorIf(nscSym ~= nscCSI,"wlan:bitRecovery:UnequalNumSC",nscSym,nscCSI);

    % Extract only data subcarriers if necessary
    if onlyData
        dataSym = sym;
        dataCSI = csi;
    else
        dataSym = sym(ofdmInfo.DataIndices,:,:);
        dataCSI = csi(ofdmInfo.DataIndices,:);
    end

end
