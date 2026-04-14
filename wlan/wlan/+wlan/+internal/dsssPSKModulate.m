function symbols = dsssPSKModulate(scrambledBits,dataRate)
%dsssPSKModulate DSSS PSK modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   SYMBOLS = dsssPSKModulate(SCRAMBLEDBITS,DATARATE)  
%

%   Copyright 2015-2021 The MathWorks, Inc.

%#codegen

    coder.internal.errorIf(~any(strcmpi(dataRate,{'1Mbps','2Mbps'})), ...
        'wlan:dsssPSKModulate:InvalidDataRate');
    
    if (strcmpi(dataRate,'1Mbps'))   
        x = scrambledBits;
        M = 2;
    else
       temp = fliplr(reshape(scrambledBits,2,numel(scrambledBits)/2).').';
       x = bit2int(temp(:),2,false);
       M=4;
    end
    
    symbols = dpskmod(x,M,0,'gray');

end