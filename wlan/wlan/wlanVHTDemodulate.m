function sym = wlanVHTDemodulate(rx,field,cfg,nvp)
%wlanVHTDemodulate Demodulate VHT fields
%
% Inputs:
%   rx - Time domain waveform of field to be demodulated
%   field - Field to demodulate
%   cfg - wlanVHTConfig object
% Name-Value Inputs:
%   'OFDMSymbolOffset' - Sampling offset as a fraction of the cyclic prefix
%   'OversamplingFactor' - Factor by which rx is over the channel bandwidth
%
% Outputs:
%   sym - OFDM demodulated symbols

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    arguments
        rx (:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        field {mustBeTextScalar}
        cfg (1,1) {mustBeA(cfg,{'wlanVHTConfig'})}
        nvp.OFDMSymbolOffset (1,1) double {mustBeInRange(nvp.OFDMSymbolOffset,0,1)} = 0.75
        nvp.OversamplingFactor (1,1) double {mustBeGreaterThanOrEqual(nvp.OversamplingFactor,1)} = 1
    end

    fieldVal = validatestring(field,{'L-LTF','L-SIG','VHT-SIG-A','VHT-LTF','VHT-SIG-B','VHT-Data'},mfilename,'FIELD');

    ofdmInfo = wlan.internal.vhtOFDMInfo(fieldVal,cfg.ChannelBandwidth,cfg.GuardInterval,nvp.OversamplingFactor);

    % Validate that min num samples provided
    numSamples = size(rx,1);
    wlan.internal.demodValidateMinInputLength(numSamples,ofdmInfo);

    % Demodulate rx
    if matches(fieldVal,'L-LTF')
        sym = wlan.internal.demodulateLLTF(rx,ofdmInfo,nvp.OFDMSymbolOffset);
    else
        sym = wlan.internal.ofdmDemodulate(rx,ofdmInfo,nvp.OFDMSymbolOffset);
    end
end
