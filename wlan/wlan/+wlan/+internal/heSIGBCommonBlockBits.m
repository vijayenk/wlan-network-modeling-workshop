function y = heSIGBCommonBlockBits(ruAllocation,center26ToneRU,chanBW)
%heSIGBCommonBlockBits Generate HE SIG-B Common Block Field bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heSIGBCommonBlockBits(...) generates the HE SIG-B common block
%   field bits.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

% IEEE Std 802.11ax-2021 Table 27-24 - Common Block field
switch chanBW
    case {20,40}
        N = 1;
    case 80
        N = 2;
    otherwise % 160
        assert(chanBW==160)
        N = 4;
end

ruAllocationBits = coder.nullcopy(zeros(N*8,1));
for i = 1:N
    ruAllocationBits(1+(i-1)*8:8*i,1) = int2bit(ruAllocation(i),8,false);
end

% Center 26 tone RU bit is only present for full bandwidth 80, 160 and
% 80+80 MHz
if chanBW<80
    center26ToneRUBits = zeros(0,1);
else
    if center26ToneRU
        center26ToneRUBits = 1;
    else
        center26ToneRUBits = 0;
    end

end

y = [ruAllocationBits(:); center26ToneRUBits];
    
end