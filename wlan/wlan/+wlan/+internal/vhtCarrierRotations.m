function [rot,numsc] = vhtCarrierRotations(x)
%vhtCarrierRotations VHT carrier rotation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [ROT,NUMSC] = vhtCarrierRotations(CHANBW) returns the carrier rotation
%   per subcarrier and number of subchannels given the channel bandwidth.
%   CHANBW is the channel bandwidth and must be 'CBW5', 'CBW10', 'CBW20',
%   'CBW40', 'CBW80', 'CBW160', or 'CBW320'.
%
%   ROT = vhtCarrierRotations(NUMSUBCHANNELS) returns the carrier rotation
%   per subcarrier given the number of subchannels. NUMSUBCHANNELS is 1, 2,
%   4, 8, or 16.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

% 802.11-2016 Section 21.3.7.5
switch x
    case {'CBW5','CBW10','CBW20',1}
        numsc = 1;
        gamma = 1;
    case {'CBW40',2}
        numsc = 2;
        gamma = [1 1i];            
    case {'CBW80',4}
        numsc = 4;
        gamma = [1 -1 -1 -1];
    case {'CBW160',8}
        numsc = 8;
        gamma = [1 -1 -1 -1 1 -1 -1 -1];
    otherwise % 320 MHz
        numsc = 16;
        gamma = [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1 1]; % IEEE 802.11-20/1262r15, Section 2.6.1
end
rot = reshape(repmat(gamma,64,1),[],1);

end