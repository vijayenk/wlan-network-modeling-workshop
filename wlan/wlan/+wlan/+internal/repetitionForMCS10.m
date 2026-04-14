function repeatedData = repetitionForMCS10(encodedData)
%repetitionForMCS10 Repetition as per Eqn 24-45 for S1G MCS 10
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = repetitionForMCS10(X) returns the repeated bits processed as per
%   Eqn 24-45 in IEEE P802.11ah/D5.0 for input bits X. X is a column vector
%   and the number of elements must be a multiple of 12.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

encodedLen = size(encodedData,1);
numRep = 2; % Number of repetitions
bpsPreRep = 12; % Number of bits per symbol pre repetition
s = [1; 0; 0; 0; 0; 1; 0; 1; 0; 1; 1; 1];  % Eqn 24-45
encBitsSym = reshape(encodedData,bpsPreRep,encodedLen/bpsPreRep); % Every column a symbol
repeatedData = reshape([encBitsSym; xor(encBitsSym,s)],encodedLen*numRep,1);

end
