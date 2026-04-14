function [x,varargout] = dmgWindowing(x,wLength,cfgDMG,varargin)
%dmgWindowing Window time-domain OFDM symbols for DMG OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   X = dmgWindowing(X,WLENGTH,CFGDMG) returns the time-domain windowed
%   signal for the DMG OFDM PHY. The windowing function for OFDM waveform
%   is defined in IEEE Std 802.11-2016, Section 20.3.5.2. The start and end
%   of the waveform are windowed together to allow the waveform to be
%   looped without discontinuity.
%
%   X is a complex Ns-by-1 vector array containing the time-domain waveform
%   for OFDM PHY.
%
%   WLENGTH is the windowing length in samples to apply. When WLENGTH is
%   zero, no windowing is applied.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.
%
%   [X,PREFIX,POSTFIX] = dmgWindowing(X,WLENGTH,CFGDMG) returns the
%   time-domain windowed signal with windowing prefix and postfix. The
%   start and end of the waveform are not windowed together.
%
%   PREFIX a WLENGTH/2-by-1 vector containing samples to overlap with any
%   waveform before.
%
%   POSTFIX is a WLENGTH/2-by-1 vector containing samples to overlap with
%   any waveform after.
%
%   See also wlanWaveformGenerator

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

if wLength == 0
    % No windowing for window length of zero
    prefix = zeros(0,1);
    postfix = zeros(0,1);
    varargout{1} = prefix;
    varargout{2} = postfix;
    return;
end

if nargin>4
    numPackets = varargin{1};
    numIdleSamples = varargin{2};
else
    numPackets = 1;
    numIdleSamples = 0;
end

isBRP = wlan.internal.isBRPPacket(cfgDMG);

symLength = 640; % OFDM symbol length in samples
GILength = 128;
[index,mag] = wlan.internal.windowingEquation(wLength,symLength);

p = wlan.internal.dmgOFDMEncodingInfo(cfgDMG);
ofdmIdx = 4992+(1:(p.NSYM+1)*symLength);
DMGCEEndIdx = 4992;
BRPStartIdx = ofdmIdx(end)+1;

Ns = length(x);
numPacketIdleSamples = Ns/numPackets;
numPacketSamples = numPacketIdleSamples-numIdleSamples;

% Offset of each packet within the waveform
pktOffset = 0:numPacketIdleSamples:(numPackets-1)*numPacketIdleSamples;

for i = 1:numPackets
    % Get Header plus Data fields of the packet
    ofdmFieldIdx = pktOffset(i)+ofdmIdx;
    ofdmField = x(ofdmFieldIdx);

    % Reshape by SymLength-by-NumSym
    ofdmSym = reshape(ofdmField,symLength,length(ofdmField)/symLength);

    % Extend symbol length before windowing
    ofdmSymExtended = [ofdmSym(end-(abs(index(1))+GILength)+1:end-GILength,:,:); ...
                       ofdmSym; ofdmSym(GILength+(1:wLength/2),:,:)];

    % Apply windowing on the extended symbol portion
    ofdmSymTappered = ofdmSymExtended .* mag;

    % Window data section
    ofdmSymWindowed = wlan.internal.windowSymbol(ofdmSymTappered,wLength);

    % Get prefix samples of first windowed symbol in OFDM portion
    prefixOFDMSym = ofdmSymWindowed(1:wLength/2-1,:);

    % Get the last preamble samples before the header + data portion
    preambleWinIdx = pktOffset(i)+(DMGCEEndIdx-wLength/2+2:DMGCEEndIdx);
    % Overlap and add the prefix samples of the preamble field with the suffix of the data field
    x(preambleWinIdx) = x(preambleWinIdx)+prefixOFDMSym;

    if ~isBRP
        % Replace with data OFDM with windowed symbols
        x(ofdmFieldIdx) = ofdmSymWindowed(wLength/2:end-wLength/2);

        if i>1 && numIdleSamples==0
            % Apply OFDM windowing suffix to preamble of next packet
            overlapIdx = pktOffset(i)+(1:wLength/2);
            coder.assumeDefined(postfix);
            x(overlapIdx) = x(overlapIdx)+postfix(numIdleSamples+1:end);
        end

        postfix = ofdmSymWindowed(end-wLength/2+1:end);

        if numIdleSamples>0
            % Apply OFDM windowing suffix to start of idle time following data
            coder.internal.assert(numIdleSamples>=wLength/2,'wlan:dmgWindowing:invalidWindowLength')
            overlapIdx = pktOffset(i)+numPacketSamples+(1:wLength/2);
            coder.assumeDefined(postfix);
            x(overlapIdx) = x(overlapIdx)+postfix;

            % No postfix to use externally
            postfix = zeros(wLength/2,1);
        end
    else
        % BRP fields present - overlap OFDM symbol into BRP

        % Get suffix samples of last windowed OFDM symbol
        suffixOFDMSym = ofdmSymWindowed(end-wLength/2+1:end);

        % Get index of start of BRP samples to window over
        brpIndex = pktOffset(i)+(BRPStartIdx:BRPStartIdx+wLength/2-1);
        % Overlap and add the prefix samples of the BRP field with the suffix of the data field
        x(brpIndex) = x(brpIndex)+suffixOFDMSym;

        % Replace with data OFDM with windowed symbols
        x(ofdmFieldIdx) = ofdmSymWindowed(wLength/2:end-wLength/2);

        % No postfix to use externally
        postfix = zeros(0,1);
    end
end
coder.assumeDefined(postfix);

% No prefix to use externally
prefix = zeros(0,1);

if nargout>1
    % Do not overlap-add ends of windowed packets
    varargout{1} = prefix;
    varargout{2} = postfix;
else
    % Overlap-add the ends of the windowed packets
    aLen = height(prefix);
    bLen = height(postfix);
    % Overlap start of packet with end
    x(1:bLen,:) = x(1:bLen,:)+postfix;
    % Overlap end of packet with start
    x(end-aLen+1:end,:) = x(end-aLen+1:end,:)+prefix;
end

end
