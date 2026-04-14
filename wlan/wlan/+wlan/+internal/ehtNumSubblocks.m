function L = ehtNumSubblocks(ppduType,cbw)
%ehtNumSubblocks Number of processed 80 MHz subblocks for the PPDU type
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   L = ehtNumSubblocks(PPDUTYPE,CBW) returns the number of 80 MHz
%   subblocks required for processing the pre-EHT signaling fields for the
%   given PPDUType and channel bandwidth. PPDU type must be 'su',
%   'dl_mumimo', 'dl_ofdma', or 'ndp'.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

switch ppduType
  case wlan.type.EHTPPDUType.dl_ofdma
    if cbw==320
        L = 4; % Different information in each 80 MHz subblock
    elseif cbw==160
        L = 2;
    else
        L = 1;
    end
  otherwise % 'su', 'dl_mumimo', or 'ndp'
    L = 1; % Same EHT-SIG bits in all 80 MHz subblock. Process single 80 MHz subblock.
end
