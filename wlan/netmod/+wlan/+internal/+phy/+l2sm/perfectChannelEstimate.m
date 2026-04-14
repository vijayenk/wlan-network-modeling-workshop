function H = perfectChannelEstimate(pathGains,pathFilters,ofdmInfo,offset)
%perfectChannelEstimate perfect channel estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   H = perfectChannelEstimate(PATHGAINS,PATHFILTERS,OFDMINFO) performs
%   perfect channel estimation.
%
%   H is an array of size Nst-by-Nsym-by-Nt-by-Nr. Nst is the number
%   of active subcarriers. Nsym is the number of OFDM symbols. Nt is the
%   number of transmit antennas. Nr is the number of receive antennas.
%
%   PATHGAINS must be an array of size Ns-by-Np-by-Nt-by-Nr, where Ns is
%   the number of path gain samples and, Np is the number of paths. The
%   channel impulse response is averaged across all samples and summed
%   across all transmit antennas and receive antennas before timing
%   estimation.
%
%   PATHFILTERS must be a matrix of size Np-by-Nh where Nh is the number of
%   impulse response samples. The path filters is assumed to be the same
%   for all links.
%
%   OFDMINFO is a structure with the these fields:
%     FFTLength        - FFT length
%     CPLength         - Cyclic prefix length
%     ActiveFFTIndices - Indices of active subcarriers within the FFT in
%                        the range [1, NFFT]
%
%   H = perfectChannelEstimate(...,OFFSET) performs perfect channel
%   estimation given a timing offset, OFFSET. If not provided, or OFFSET is
%   empty , the ideal offset is calculated internally.
%
%   OFFSET indicates estimated timing offset, an integer number of samples
%   relative to the first sample of the channel impulse response
%   reconstructed from PATHGAINS and PATHFILTERS.

%   See also channelDelay.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

if nargin>3 && isnumeric(offset) && ~isempty(offset)
    % perfectChannelEstimate(pathGains,pathFilters,ofdmInfo,offset)
else
    offset = channelDelay(pathGains,pathFilters);
end

% Get number of paths 'Np', number of transmit antennas 'Nt' and number of
% receive antennas 'Nr' in the path gains array. The pathGains are of size
% Ns-by-Np-by-Nt-by-Nr, where 'Ns' is the number of channel snapshots.
[Ns,Np,Nt,Nr] = size(pathGains);

% Get number of channel impulse response samples 'Nh'
Nh = size(pathFilters,2);

cpLen = ofdmInfo.CPLength(1);
fftLen = ofdmInfo.FFTLength;
symLength = fftLen + cpLen;
activeFFTIndices = ofdmInfo.ActiveFFTIndices;

% Establish the starting and ending sample indices of each OFDM symbol
% across the total number of subframes, taking into consideration the
% initial slot number, and update the cyclic prefix lengths to span all
% subframes.
% Establish how many OFDM symbols 'L' are spanned by 'T' time samples.
sampleIndex = (1:Ns).';

% Return OFDM symbols for all symbols worth of data passed
L = ceil(Ns/symLength); % Number of OFDM symbols covered by snapshots
inc = 0:symLength:((L-1)*symLength);

symbolStarts = inc+cpLen;
symbolEnds = symbolStarts + fftLen;

% Ensure that total number of samples 'Ns' is at least one symbol
Ns = max(Ns,symbolEnds(end));

% Establish which OFDM symbol start indices correspond to which channel
% coefficient sample indices 'sampleIndex'. 'idx' is a vector of length 'L'
% indicating the 1st dimension index of 'pathGains' for each OFDM symbol
% start time.
symbolStartIdx = symbolStarts + offset;
idx = sum(symbolStartIdx>=sampleIndex,1);

% Prepare the path gains matrix by indexing using 'idx' to select a first
% dimension element for each OFDM symbol start, and permute to put the
% multipath components in the first dimension and switch the antenna
% dimensions. The pathGains are now of size Np-by-Nr-by-Nt
pathGains = pathGains(idx,:,:,:);
pathGains = permute(pathGains,[2 4 3 1]);

% Create channel impulse response array 'h' for each impulse response
% sample, receive antenna, transmit antenna and OFDM symbol. For each path,
% add its contribution to the channel impulse response across all transmit
% antennas, receive antennas and OFDM symbols
h = reshape(pathFilters.' * reshape(pathGains,Np,[]),Nh,Nr,Nt,L);

% Create the empty received waveform (for each transmit antenna)
rxWave = zeros([Ns Nr Nt],'like',pathGains);

% For each OFDM symbol, add the corresponding impulse response samples
% across all transmit antennas and receive antennas to the received
% waveform. Note that the impulse responses are positioned according to the
% timing offset 'offset' and the channel filter delay so that channel
% estimate produced is as similar as possible to that produced for a
% filtered waveform (without incurring the time cost of the full filtering)
tl = fix(symbolStarts) - offset + (1:Nh).';
h = reshape(permute(h,[1 4 2 3]),[],Nr,Nt);
rxWave(tl,:,:) = rxWave(tl,:,:) + h; 

% Remove any samples from the end of the received waveforms that correspond
% to incomplete OFDM symbols
rxWave = rxWave(1:symbolEnds(L),:,:);

cpFraction = 0; % Use not offset to make sure entire CIR captured
symOffset = fix(cpLen * cpFraction);

tstart = min(symbolStarts-cpLen)+1;
ofdmStr = struct;
ofdmStr.NumReceiveAntennas = Nr;
ofdmStr.FFTLength = fftLen;
ofdmStr.NumSymbols = floor((Ns-tstart+1)/(fftLen+cpLen));
ofdmStr.SymbolOffset = symOffset;
ofdmStr.CyclicPrefixLength = cpLen;
ofdmStr.NumBatchObs = Nt; % Treat the samples per tx antenna as per batch observation in the demodulator
rxGrid = comm.internal.ofdm.demodulate(rxWave(tstart:end,:,:),ofdmStr); % Nst-by-Nsym-by-Nr-by-Nt
H = permute(rxGrid(activeFFTIndices,:,:,:),[1 2 4 3]); % Nst-by-Nsym-by-Nt-by-Nr
end
