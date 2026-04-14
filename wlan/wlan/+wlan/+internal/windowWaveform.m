function [x,varargout] = windowWaveform(x,symLen,cpLen,extLen,tr,varargin)
%windowWaveform OFDM window a waveform
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   X = windowWaveform(X,SYMLEN,CPLEN,EXTLEN,TR) returns the time-domain
%   windowed signal for the OFDM signal. The windowing function for OFDM
%   waveform is defined in IEEE Std 802.11-2016. The start and end of the
%   waveform are windowed together to allow the waveform to be looped
%   without discontinuity.
%
%   SYMLEN is a row vector containing the number of samples for each OFDM
%   symbol (including cyclic prefix and extension).
%
%   CPLEN is a row vector containing the number of cyclic-prefix samples
%   for each OFDM symbol.
%
%   EXTLEN is a scalar or row vector containing the number of extension
%   (cyclic-postfix) samples for each OFDM symbol.
%
%   TR is the window transition time in samples.
%
%   X = windowWaveform(X,SYMLEN,CPLEN,EXTLEN,TR,NUMPACKETS,IDLELEN) windows
%   a waveform which contains NUMPACKET packets with IDLELEN samples
%   between each packet. All packets are assumed to have the same SYMLEN
%   and CPLEN.
%
%   [X,U,D] = windowWaveform(...) returns the windowed waveform X without
%   windowing the start and end of the waveform together. U and D are the
%   prefix and postfix samples.

%   Copyright 2017-2023 The MathWorks, Inc.

%#codegen

if nargin>5
    numPackets = varargin{1};
    numIdleSamples = varargin{2};
else
    numPackets = 1;
    numIdleSamples = 0;
end

[Ns,Nt] = size(x); % Number of samples and antennas
coder.internal.assert(isrow(symLen),'wlan:windowWaveform:SYMLENDims');

if isscalar(extLen)
    % If scalar treat as the same per symbol. For codegen create a new
    % variable.
    ceLen = repmat(extLen,size(cpLen));
else
    ceLen = extLen;
end

if numIdleSamples==0
    % Repeat pattern for all packets
    symLen = repmat(symLen,1,numPackets);
    cpLen = repmat(cpLen,1,numPackets);
    ceLen = repmat(ceLen,1,numPackets);
else
    % Repeat pattern for all packets with idle time
    symLen = repmat([symLen numIdleSamples],1,numPackets);
    cpLen = repmat([cpLen 0],1,numPackets);
    ceLen = repmat([ceLen 0],1,numPackets);
end
coder.internal.assert(Ns==sum(symLen),'wlan:windowWaveform:SYMLENMismatch');
coder.internal.assert(all(size(cpLen)==size(symLen)) && all(size(ceLen)==size(symLen)),'wlan:windowWaveform:CPLENMismatch');

% Offset in samples of each OFDM symbol (first sample of the CP if it is non-zero)
startOffset = cumsum([0 symLen]);

% Two symbols are windowed together over a transition time. In the diagram
% below TR1 is the transition between SYM1 and SYM2, and TR2 is the
% transition between SYM2 and SYM3.
%
% |------|------------:----|----:-|------------:----|----:-|
% |  CP1 |       SYM1 :    |  CP2 |       SYM2 :    |  CP3 |
% |------|------------:----|----:-|------------:----|----:-|
%                     <--------->              <--------->
%                         TR1                      TR2
%
% In the case of SYM1 with an extesion (cyclic postfix):
%
% |------|----------------|----:----|----:-|------------:----|----:-|
% |  CP1 |       SYM1     | E1 :    |  CP2 |       SYM2 :    |  CP3 |
% |------|----------------|----:----|----:-|------------:----|----:-|
%                              <--------->              <--------->
%                                  TR1                      TR2
%
% Two symbols make up each window transition. We define these as the
% "previous" and "next" symbol. The transition region is formed by
% cyclically extending both symbols over the transition region, creating a
% prefix and postfix. The diagram below shows how the samples are extended.
%
% |------|-----------------|----:
% |PREVCP|       PREV      |    :
% |7 8 9 |1 2 3 4 5 6 7 8 9|1 2 :
% |------|-----------------|----:
%                           <-->
%                           SYM1E (postfix)
%                     :----|------|-----------------|
%                     :    |NEXTCP|      NEXT       |
%                     : 5 6|7 8 9 |1 2 3 4 5 6 7 8 9|
%                     :----|------|-----------------|
%                      <-->
%                      SYM2E (prefix)
%                     <--------->
%                         TR1
%
% In the case of both symbols having an extesion (cyclic postfix):
%
% |------|-----------------|--------|----:
% |PREVCP|       PREV      |PREVEXT |    :
% |7 8 9 |1 2 3 4 5 6 7 8 9|1 2 3 4 |5 6 :
% |------|-----------------|--------|----:
%                                    <-->
%                                    SYM1E (postfix)
%                              :----|------|-----------------|--------|
%                              :    |NEXTCP|      NEXT       |NEXTEXT |
%                              : 5 6|7 8 9 |1 2 3 4 5 6 7 8 9|1 2 3 4 |
%                              :----|------|-----------------|--------|
%                               <-->
%                               SYM2E (prefix)
%                              <--------->
%                                  TR1

% Get the indices of samples in "next" symbols which will make up each
% transition region. This is made up from:
% 1 - samples creating a cyclic extended prefix
prefixIdx = (1:(tr/2-1)) + (((symLen-ceLen-cpLen)' - (tr/2-1)) + startOffset(1:end-1)');
% 2 - samples from the start of the symbol
startIdx = (1:(tr/2)) + startOffset(1:end-1)';
% Each row corresponds to the indices of samples in the transition for a symbol
nextIdx = [prefixIdx startIdx];

% Get the indices of samples in "previous" symbols which will make up the
% transition region. This is made up from:
% 1 - samples from the end of each symbol
endIdx = (symLen' - (tr/2-1) + startOffset(1:end-1)') + (1:(tr/2-1));
% 2 - samples creating a cyclic extended postfix
postfixIdx = (cpLen+ceLen)' + startOffset(1:end-1)' + (1:tr/2);
% Each row corresponds to the indices of samples in the transition for a symbol
prevIdx = [endIdx postfixIdx];

% Manipulate indices so they index all antennas
nextIdx3D = repmat(nextIdx,[1 1 Nt]) + permute((0:Nt-1)*Ns,[1 3 2]);
prevIdx3D = repmat(prevIdx,[1 1 Nt]) + permute((0:Nt-1)*Ns,[1 3 2]);

% The windowing equation is applied to the transition region of both
% symbols and the result summed.
%
% |------|------------:\
% |PREVCP|       PREV :  \
% |      |            :    \
% |      |            :    | \
% |      |            :    |   \
% |------|------------:----|----|
%                              /:-|-----------------|
%                            /  : |     NEXT        |
%                          /    : |                 |
%                        / |    : |                 |
%                      /   |    : |                 |
%                     :----|----:-|-----------------|
%                     <--------->
%                          TR
%
% |------|------------:\       /:-|-----------------|
% |PREVCP|       PREV :  \   /  : |     NEXT        |
% |      |            :    X    : |                 |
% |      |            :  / | \  : |                 |
% |      |            :/   |   \: |                 |
% |------|------------:----|----:-|-----------------|
%                     <--------->
%                          TR

% Symbol windowing equations - calculate the magnitude to apply to the
% previous and next symbols over the transition
nextWinIdx = -tr/2+1:tr/2-1;
nextMag = sin(pi/2*(0.5+(nextWinIdx)/(tr))).^2; % Ramp up
prevWinIdx = -tr/2+1:(+tr/2)-1;
prevMag = sin(pi/2*(0.5-(prevWinIdx)/tr)).^2; % Ramp down

% Apply the windowing gain to the transition regions for "previous" and
% "next" samples in all symbols.
Nsym = numel(symLen);
next = complex(zeros(Nsym+2,tr-1,Nt)); % Include zero sym at start and end to allow for ramp up and down after waveform
prev = complex(zeros(Nsym+2,tr-1,Nt));
if Nsym==1&&Nt==1
    % In this case x(nextIdx3D) results in a column so treat differently
    next(2:end-1,:,:) = x(nextIdx3D) .* nextMag.';
    prev(2:end-1,:,:) = x(prevIdx3D) .* prevMag.';
else
    next(2:end-1,:,:) = x(nextIdx3D) .* nextMag;
    prev(2:end-1,:,:) = x(prevIdx3D) .* prevMag;
end

% Overlap the "prev" and "next" symbols in each transition region.
%
% Implementation detail: tell coder that inputs have exactly same size
% and no implicit expansion is required. Generated C code for plus with
% implicit expansion triggers a GCC compiler bug.
overlap = coder.sameSizeBinaryOp(@plus, prev(1:end-1,:,:), next(2:end,:,:)); % NSYM-TR-NT

% In code generation, inlining permute here creates large complicated C
% code that hits an issue in the GCC compiler, producing a dll file with an
% incorrect answer. Permute is forced to use a non-inlined version to
% overcome the issue.
overlap = permute_non_inlined(overlap,[2 1 3]); % TR-NSYM-NT

% Calculate the indices of samples which have an overlap (transition) in
% the waveform. This will cover from the 2nd symbol to (N-1)th symbol.
% These must handled separately as there is only a partial overlap (as no
% data before and after).
overlapIdx = ((-tr/2+1):(tr/2-1)) + startOffset(2:end-1)' + 1;
% Manipulate indices so they index all antennas
overlapIdx3D = repmat(overlapIdx,[1 1 Nt]) + permute((0:Nt-1)*Ns,[1 3 2]);
% Over-write samples which are in a transition with calculated values
x(overlapIdx3D) = permute(overlap(:,2:end-1,:),[2 1 3]); % NSYM-TR-NT

% Add overlap for start of the first symbol and end of the last symbol
x(1:tr/2,:) = permute(overlap(tr/2:end,1,:),[1 3 2]); % TR-NT-NSYM
x(end-tr/2+2:end,:) = permute(overlap(1:tr/2-1,end,:),[1 3 2]); % TR-NT-NSYM

% First samples at output will be the ramp-up i.e. overlap with zeros
pre = permute(overlap(1:tr/2-1,1,:),[1 3 2]); % TR-NT-NSYM

% Last samples output will be ramp-down i.e. overlap with zeros
post = permute(overlap(tr/2:end,end,:),[1 3 2]); % TR-NT-NSYM

if nargout>1
    % Do not overlap-add ends of windowed packets
    varargout{1} = pre;
    varargout{2} = post;
else
    % Overlap-add the ends of the windowed packets
    aLen = height(pre);
    bLen = height(post);
    % Overlap start of packet with end
    x(1:bLen,:) = x(1:bLen,:)+post;
    % Overlap end of packet with start
    x(end-aLen+1:end,:) = x(end-aLen+1:end,:)+pre;
end

end

function out = permute_non_inlined(in, sz)
    coder.inline('never');
    out = permute(in, sz);
end
