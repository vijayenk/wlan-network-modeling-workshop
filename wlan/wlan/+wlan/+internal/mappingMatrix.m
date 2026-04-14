function P = mappingMatrix(numSTS)
%mappingMatrix HT-LTF and VHT-LTF orthogonal mapping matrix
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   P = mappingMatrix(NUMSTS) returns the orthogonal mapping matrix for a
%   given number of space-time streams NUMSTS.

%   Copyright 2016 The MathWorks, Inc.

%#codegen

% Mapping matrix
% IEEE Std 802.11-2012 Eqn 20-27
Phtltf = [1 -1 1 1; 1 1 -1 1; 1 1 1 -1; -1 1 1 1];
if (sum(numSTS) <= 4) % 1-4
    P = Phtltf;
elseif sum(numSTS) > 4 && sum(numSTS) <= 6  % numSTS = {5,6}
    w = exp(-2*pi*1i/6);
    % IEEE Std 802.11ac-2013 Eqn 22-44
    P = [1 -1   1    1    1    -1; ...
        1 -w   w^2  w^3  w^4  -w^5; ...
        1 -w^2 w^4  w^6  w^8  -w^10; ...
        1 -w^3 w^6  w^9  w^12 -w^15; ...
        1 -w^4 w^8  w^12 w^16 -w^20; ...
        1 -w^5 w^10 w^15 w^20 -w^25 ];
else    % numSTS ={7,8}
    P = [Phtltf Phtltf; Phtltf -Phtltf];
end

end