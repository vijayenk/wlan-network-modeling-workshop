function allowedPuncPatterns = ehtAllowedOFDMAPuncturingPatterns
%ehtAllowedOFDMAPuncturingPatterns Allowed OFDMA puncturing pattern
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   EHTALLOWEDOFDMAPUNCTURINGPATTERNS returns the allowed OFDMA puncturing
%   pattern in 80 MHz subblock as defined in Table 36-28 of IEEE
%   P802.11be/D3.0. A value of 0 indicates that the corresponding 20
%   MHz sub channel is punctured, and a value of 1 is used otherwise.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

allowedPuncPatterns = [0 1 1 1; 1 0 1 1; 1 1 0 1; 1 1 1 0; 0 0 1 1; 1 1 0 0; 1 0 0 1; 1 1 1 1]; % 0 indicates a punctured channel

end