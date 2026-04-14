function [bits, failcrc] = wlanVHTSIGABitRecover(sym,noiseEst,csi)
%wlanVHTSIGABitRecover Recover bits from VHT-SIG-A field
%
% Inputs:
%   sym - Equalized vht-sig-a symbols of size 52-by-2 or 48-by-2
%   noiseEst - Noise variance of the channel
%   csi - Channel state information based on equalized symbols. Needs to be
%   same size as SYM input
%
% Outputs:
%   bits - A 48-by-1 vector of type int8 consisting of VHT-SIG-A bits
%   recovered from SYM
%   failcrc - A scalar logical that indicates if bit recovery was
%   successful

%   Copyright 2025 The MathWorks, Inc.

%#codegen
    arguments
        sym (:,2) {mustBeFloat,mustBeFinite,mustBeNonempty}
        noiseEst (1,1) {mustBeFloat,mustBeFinite,mustBeNonnegative}
        csi (:,1) {mustBeFloat,mustBeFinite,mustBeReal,mustBeNonempty}
    end

    % Validate subcarrier dimension and extract data only subcarriers
    preVHT = true;
    pOFDMInfo = wlan.internal.getPartialVHTOFDMInfo('CBW20',preVHT); % VHT-SIG-A will always have numsc for CBW20 as it is passed through equalizer
    [dataSym,dataCSI] = wlan.internal.validateNumSCBitRec(sym,csi,pOFDMInfo);

    % Recover bits
    [bits,failcrc] = wlan.internal.vhtSIGABitRecover(dataSym,noiseEst,dataCSI);

end
