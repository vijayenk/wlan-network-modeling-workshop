function bits = wlanVHTSIGBBitRecover(sym,noiseEst,csi,cfg)
%wlanVHTSIGBBitRecover Recover bits from VHT-SIG-B field
%
% Inputs:
%   sym - Equalized vht-sig-b symbols of size Nsc-by-1 where Nsc is
%   the number of subcarriers.
%   noiseEst - Noise variance of the channel.
%   csi - Channel state information based on SYM. Needs to be same size as
%   SYM input.
%   cfg - A wlanVHTConfig object. Only ChannelBandwidth property is used.
%
% Outputs:
%   bits - A column vector of type int8 consisting of VHT-SIG-B bits
%   recovered from SYM. The size of the vector depends on the channel
%   bandwidth.

%   Copyright 2025 The MathWorks, Inc.

%#codegen
    arguments
        sym (:,1) {mustBeFloat,mustBeFinite,mustBeNonempty}
        noiseEst (1,1) {mustBeFloat,mustBeFinite,mustBeNonnegative}
        csi (:,1) {mustBeFloat,mustBeFinite,mustBeReal,mustBeNonempty}
        cfg (1,1) {mustBeA(cfg,'wlanVHTConfig')}
    end

    % Validate subcarrier dimension and extract data only subcarriers
    preVHT = false;
    pOFDMInfo = wlan.internal.getPartialVHTOFDMInfo(cfg.ChannelBandwidth,preVHT);
    [dataSym,dataCSI] = wlan.internal.validateNumSCBitRec(sym,csi,pOFDMInfo);

    % Recover PSDU
    bits = wlan.internal.vhtSIGBBitRecover(dataSym,noiseEst,dataCSI,cfg.ChannelBandwidth,pOFDMInfo);

end
