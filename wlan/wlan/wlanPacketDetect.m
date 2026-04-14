function [startOffset,M] = wlanPacketDetect(x, chanBW, offset, threshold, nameValueArgs)
%wlanPacketDetect OFDM packet detection using the L-STF
%   STARTOFFSET = wlanPacketDetect(X, CHANBW) returns the offset from the
%   start of the input waveform to the start of the detected preamble using
%   auto-correlation. Only OFDM modulation is supported.
%
%   STARTOFFSET is an integer scalar indicating the location of the start
%   of a detected packet as the offset from the start of the matrix X. If
%   no packet is detected an empty value is returned.
%
%   X is the received time-domain signal. It is a single or double Ns-by-Nr
%   matrix of real or complex samples, where Ns represents the number of
%   time domain samples and Nr represents the number of receive antennas.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must be 'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or
%   'CBW320'.
%
%   STARTOFFSET = wlanPacketDetect(..., OFFSET) specifies the offset to
%   begin the auto-correlation process from the start of the matrix X. The
%   STARTOFFSET is relative to the input OFFSET when specified. It is an
%   integer scalar greater than or equal to zero. When unspecified a value
%   of 0 is used.
%
%   STARTOFFSET = wlanPacketDetect(..., OFFSET, THRESHOLD) specifies the
%   threshold which the decision statistic must meet or exceed to detect a
%   packet. THRESHOLD is a real scalar greater than 0 and less than or
%   equal to 1. When unspecified a value of 0.5 is used.
%
%   [STARTOFFSET, M] = wlanPacketDetect(...) returns the decision
%   statistics of the packet detection algorithm of matrix X. When
%   THRESHOLD is set to 1, the decision statistics of the complete waveform
%   will be returned and STARTOFFSET will be empty.
%
%   M is a real vector of size N-by-1, representing the decision statistics
%   based on auto-correlation of the input waveform. The length of N
%   depends on the starting location of the auto-correlation process till
%   the successful detection of a packet.
%
%   [STARTOFFSET, M] = wlanPacketDetect(...,'OversamplingFactor',OSF)
%   specifies the optional oversampling factor of the waveform. The
%   oversampling factor must be greater than or equal to 1. The default
%   value is 1. When you specify an oversampling factor greater than 1, the
%   function uses a larger FFT size and process the oversampled waveform to
%   determine the offset from the start of the input waveform to the start
%   of the detected preamble. The oversampling factor must result in an
%   integer number of samples in the cyclic prefix.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

    arguments
        x (:, :) {mustBeFloat, mustBeFinite};
        chanBW;
        offset (1, 1) {validateOffset(x, offset)} = 0;
        threshold (1, 1) {mustBeNumeric, mustBeGreaterThan(threshold, 0), mustBeLessThanOrEqual(threshold, 1)} = 0.5;
        nameValueArgs.OversamplingFactor (1, 1) {mustBeNumeric, mustBeFinite, mustBeGreaterThanOrEqual(nameValueArgs.OversamplingFactor, 1)} = 1;
    end

    % Check if M is requested
    if nargout==2
        M = [];
    end

    startOffset = [];
    if isempty(x)
        return;
    end

    chanBW = wlan.internal.validateParam('NONHTEHTCHANBW', chanBW, mfilename); % Validate Channel Bandwidth
    osf = nameValueArgs.OversamplingFactor;
    [fftLen,nsc] = wlan.internal.cbw2nfft(chanBW);
    wlan.internal.validateOFDMOSF(osf, fftLen, 0); % Validate OSF

    Td = 0.8e-6; % Time period of a short training symbol for 20 MHz
    symbolLength = Td*(osf*nsc*20e6);
    lenLSTF = symbolLength*10; % Length of 10 L-STF symbols
    lenHalfLSTF = lenLSTF/2;   % Length of 5 L-STF symbols
    inpLength = (size(x,1) - offset);

    % Append zeros to make the input equal to multiple of L-STF/2
    if inpLength<=lenHalfLSTF
        numPadSamples = lenLSTF - inpLength;
    else
        numPadSamples = lenHalfLSTF*ceil(inpLength/lenHalfLSTF) - inpLength;
    end
    padSamples = zeros(numPadSamples, size(x,2), 'like', x);
    x = [x; padSamples];
    % Process the input waveform in blocks of L-STF length. The processing
    % blocks are offset by half the L-STF length.
    numBlocks = (inpLength + numPadSamples)/lenHalfLSTF;

    % Define decision statistics vector
    DS = coder.nullcopy(zeros(size(x,1) + numPadSamples - offset - 2*symbolLength + 1, 1));
    corrLen = lenLSTF - (symbolLength*2) + 1;
    out = coder.nullcopy(zeros(corrLen, 1, 'like', real(x)));
    % Pre-define for code generation
    loopEnd = 0;
    for n = 1:numBlocks-1
        loopEnd = n;
        % Update buffer
        buffer = x((n-1)*lenHalfLSTF + (1:lenLSTF) + offset, :);
        buffer = permute(buffer,[1 3 2]);
        [startOffset, out] = wlan.internal.detectPackets(buffer, symbolLength, lenLSTF, threshold);

        DS((n-1)*lenHalfLSTF + 1:lenHalfLSTF*n, 1) = double(out(1:lenHalfLSTF));

        if ~isempty(startOffset)
            % Packet detected
            startOffset = startOffset + (n-1)*lenHalfLSTF;
            break;
        end
    end
    DS((loopEnd-1)*lenHalfLSTF + (1:length(out)), 1) = double(out);
    % Resize decision statistics
    M = DS(1:(loopEnd-1)*lenHalfLSTF + length(out));
end

function validateOffset(x, offset)
% Validate Offset value
    mustBeNumeric(offset);
    mustBeFinite(offset);
    mustBeInteger(offset);
    mustBeGreaterThanOrEqual(offset, 0);
    coder.internal.errorIf(~isempty(x) && offset>size(x, 1)-1, 'wlan:shared:InvalidOffsetValue')
end
