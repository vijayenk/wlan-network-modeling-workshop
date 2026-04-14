function [encodedData,padding] = heRemovePostFECPadding(postFECpaddedData,channelCoding,userParams)
%heRemovePostFECPadding Remove post FEC padding bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    mSTBC = userParams.mSTBC;

    % Calculate bits per symbol to allow for the case where NCBPS does not
    % match NDBPS (some DCM cases). This will cause NSYMCalc to not be integer
    % in cases where the Pre-FEC padding factor is not 4.
    if strcmpi(string(channelCoding),'BCC')
        bitsPerSymbol = userParams.NDBPS/userParams.Rate;
    else
        % For LDPC there is no BCC interleaver padding therefore we don't have
        % to worry about NCBPS*rate != NDBPS.
        bitsPerSymbol = userParams.NCBPS;
    end
    NSYMCalc = floor(height(postFECpaddedData)/bitsPerSymbol);

    indBeforePadding = (NSYMCalc-mSTBC)*bitsPerSymbol;
    bitsBeforePadding = postFECpaddedData((1:indBeforePadding)');
    % The last symbol(s) may be NCBPS or bitsPerSymbol long, depending on
    % whether the pre-FEC padding factor is 4 or not, therefore use [] for
    % reshape, and when extracting the last symbol bits, allows us to extract
    % less than NCBPSLAST if the last symbol actually has bitsPerSymbol bits.
    bitsBeforeAfterPadding = reshape(postFECpaddedData((indBeforePadding+1:end)'),[],mSTBC);
    lastSymbolBits = bitsBeforeAfterPadding(1:min(end,userParams.NCBPSLAST),:);
    encodedData = [bitsBeforePadding; lastSymbolBits(:)];

    if nargout>1
        % Return padding bits
        lastSymbolPadding = bitsBeforeAfterPadding(min(end,userParams.NCBPSLAST)+1:end,:);
        padding = lastSymbolPadding(:);
    end

end