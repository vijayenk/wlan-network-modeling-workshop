function [packetStarts,Mn,colIdxs] = detectPackets(rxSig, symbolLength, lenLSTF, threshold)
%detectPackets Estimate the start offsets of the preamble of the received WLAN packets,
%   using auto-correlation method [1,2].
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   INPUTS:
%   rxSig        - Reshaped waveform where num rows equals symbolLength, num col
%                  depends on original waveform size in 1 antenna and
%                  lenLSTF, and 3rd dimension is based on number of
%                  antennas
%   symbolLength - Number of samples in a single symbol (depends on sample rate)
%   lenLSTF      - Number of samples in an L-STF (depends on sample rate)
%   threshold    - Threshold for deciding where packet starts
%
%   OUTPUTS:
%   packetStarts - Indicies of all detected packets in rxSig
%   Mn           - Decision statistic
%   colIdxs      - Column indicies of packets detected in rxSig
%
%   [1] OFDM Wireless LANs: A Theoretical and Practical Guide 1st Edition
%       by Juha Heiskala (Author),John Terry Ph.D. ISBN-13:978-0672321573
%   [2] OFDM Baseband Receiver Design for Wireless Communications by
%       Tzi-Dar Chiueh, Pei-Yun Tsai. ISBN: 978-0-470-82234-0

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    pNoise = cast(eps,'like',real(rxSig)); % Adding noise to avoid the divide by zero
    weights = ones(symbolLength, 1,'like',real(rxSig));

    % Shift data for correlation
    rxDelayed = rxSig(symbolLength + 1:end,:,:); % Delayed samples
    rx = rxSig(1:end-symbolLength,:,:); % Actual samples

    % Sum output on multiple receive antennas
    C = sum(filter(weights, 1,(conj(rxDelayed).*rx)), 3);
    CS = C(symbolLength:end,:)./symbolLength;

    % Sum output on multiple receive antennas
    P = sum(filter(weights, 1, (abs(rxDelayed).^2+abs(rx).^2)/2)./symbolLength, 3);
    PS = P(symbolLength:end,:) + pNoise;

    % Calculate decision statistic (Mn) and identify the columns (colDesc)
    % where statistic is greater than the threshold and 1.5 times symbol
    % length
    Mn = abs(CS).^2./PS.^2;
    N = Mn > threshold;
    colDesc = sum(N) >= symbolLength*1.5;
    N(:,~colDesc) = false;
    colIdxs = find(colDesc);

    % Create a matrix of indicies where each column has the value 1:corrLen
    % then extract indices based on N and desc and calculate all possible
    % packet start locations
    corrLen = lenLSTF - (symbolLength*2) + 1;
    idxs = repmat((1:corrLen)',1,size(N,2));
    idxs(~N) = NaN;
    idxs = idxs(:,colDesc);
    packetStarts = min(idxs) + (colIdxs-1)*lenLSTF/2 - 1;

    % Check relative distances between peaks for all detected packets
    if ~isempty(packetStarts)
        packetStarts = arrayfun(@(x)checkRelativeDist(packetStarts(x),idxs(:,x),symbolLength),1:length(packetStarts));
    end

    % Extract non-NaN values
    colIdxs = colIdxs(~isnan(packetStarts));
    packetStarts = packetStarts(~isnan(packetStarts));

end

function pS = checkRelativeDist(pS,idxs,symbolLength)
% Check the relative distance between peaks relative to the first peak. If
% this exceed three times the symbol length then the packet is not
% detected.
    nonan = idxs(~isnan(idxs));
    if any(nonan(2:symbolLength) - nonan(1)>symbolLength*3)
        pS = NaN;
    end

end
