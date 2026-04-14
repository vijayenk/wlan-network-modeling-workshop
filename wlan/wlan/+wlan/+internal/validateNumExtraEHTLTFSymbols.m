function validateNumExtraEHTLTFSymbols(cfg)
%validateNumExtraEHTLTFSymbols Validate extra number of EHT-LTF symbols
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

allocationInfo = ruInfo(cfg);
numLTFSym = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU));
coder.internal.errorIf(cfg.NumExtraEHTLTFSymbols>0 && all(cfg.NumExtraEHTLTFSymbols+numLTFSym~=[1 2 4 6 8]),'wlan:eht:InvalidNumExtraEHTLTFSymbols');

end