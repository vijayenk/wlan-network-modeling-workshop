function y = ehtScramble(x,scramInit)
%ehtScramble Scramble and descramble the binary input
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtScramble(X,SCRAMINIT) scrambles and descrambles the binary
%   input X using a frame-synchronous scrambler.
%
%   Y is a binary column vector or a matrix of type int8 or double with the
%   same size and type as the input X.
%
%   X is a binary column vector or a matrix of type int8 or double and is
%   scrambled with a length-2047 frame-synchronous scrambler. Each column
%   of X is scrambled independently with the same initial state. The
%   frame-synchronous scrambler uses the generator polynomial defined in
%   IEEE P802.11be/D1.5, Section 36.3.13.2. The same scrambler structure
%   is used to scramble bits at the transmitter and descramble bits at the
%   receiver.
%
%   SCRAMINIT is the initial state of the scrambler. It is an integer
%   between 1 and 2047 inclusive, or a corresponding 11-by-1 column vector
%   of binary bits of type int8 or double. The mapping of the
%   initialization bits on scrambler schematic X1 to X11 is specified in
%   IEEE P802.11be/D1.5, Section 36.3.13.2.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

inputClass = class(x);
buffSize = min(2047,size(x,1));
I = zeros(buffSize,1,'int8');

if isscalar(scramInit)
    scramblerInitBits = int2bit(scramInit,11);
else % iscolumn(scramInit)
    scramblerInitBits = scramInit;
end

% Scrambling sequence generated using generator polynomial
for d = 1:buffSize
    I(d) = xor(scramblerInitBits(1),scramblerInitBits(3)); % x11 xor x9
    scramblerInitBits(1:end-1) = scramblerInitBits(2:end); % Left-shift
    scramblerInitBits(11) = I(d); % Update x1
end

% Generate a periodic sequence from I to be xor-ed with the input
if isempty(coder.target)
    scramblerSequence = repmat(I,ceil(size(x,1)/buffSize),1);
    y = cast(xor(x,scramblerSequence(1:size(x,1))),inputClass);
else % Codegen branch
    y = coder.nullcopy(cast(zeros(size(x)),inputClass));
    for j = 1:size(x,2)
        k = 0;
        for i = 1:size(x,1)
            if k == buffSize
                k = 1;
            else
                k = k + 1;
            end
            y(i,j) = xor(x(i,j),I(k));
        end
    end
end

end