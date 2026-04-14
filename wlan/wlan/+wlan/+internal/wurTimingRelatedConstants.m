function t = wurTimingRelatedConstants(dataRate)
%wurTimingRelatedConstants defines the timing-related parameters for WUR
%PPDU formats.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   t = wurTimingRelatedConstants(dataRate) returns a structure containing timing
%   related constants as per IEEE 802.11ba/D8.0, December 2020, Table 30-3.
%   All the constants are in the unit of ns.
%
%   DATARATE specifies the transmission rate, and it is a character vector
%   or string scalar equal to 'LDR', or 'HDR'.
%   Set DATARATE to 'LDR', indicating the support for the low data rate (62.5 kb/s).
%   Set DATARATE to 'HDR', indicating the support for the high data rate (250 kb/s). 
%
%   See also wlanWURConfig.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

t = struct;
TDFTPreHE = 3200;
t.TDFTPreHE = TDFTPreHE;
TDFTHE = 12800;
t.TDFTHE = TDFTHE;
TGILegacyPreamble = 800;
t.TGILegacyPreamble = TGILegacyPreamble;
TGILLTF = 1600;
t.TGILLTF = TGILLTF;
t.TLSTF = 10*TDFTPreHE/4;
t.TLLTF = 2*TDFTPreHE+TGILLTF;
t.TLSIG = 4000;

t.DeltaF = 312.5e3; % Subcarrier frequency spacing in kHz
t.TDFTWUR = 3.2e3;
t.TGI2 = 1.6e3;
t.TSymLDR = 4e3;
t.TSymHDR = 2e3;
t.TSYNC = 2e3;
t.TBPSKMark1 = 4e3;
t.TBPSKMark2 = 4e3;
t.TWURSyncLDR = 128e3;
t.TWURSyncHDR = 64e3;
t.GISync = 0.4e3;
t.TGIDataHDR = 0.4e3;

% Initialize for codegen 
t.TSym = 0;
t.TWURSync = 0;
switch dataRate
    case 'LDR' % Low data rate, 4 us duration MC-OOK symbols
        t.TGIWUR = 0.8e3;
        t.TSym = t.TSymLDR;
        t.TWURSync = t.TWURSyncLDR;
    otherwise % High data rate, 2 us duration MC-OOK symbols
        t.TGIWUR = 0.4e3;
        t.TSym = t.TSymHDR;
        t.TWURSync = t.TWURSyncHDR;
end

end