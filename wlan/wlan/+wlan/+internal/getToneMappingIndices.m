function y = getToneMappingIndices(channelBandwidth)
%getToneMappingIndices LDPC tone mapping indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = getToneMappingIndices(CHANBW) return the LDPC tone mapping indices
%   as specified in IEEE 802.11ac-2013, Section 22.3.10.9.2. CHANBW is a
%   character vector or string and must be one of 'CBW20', 'CBW40',
%   'CBW80', 'CBW80+80' or 'CBW160'.
%
%   See also wlanLDPCEncode, wlanLDPCDecode.

%   Copyright 2016-2018 The MathWorks, Inc.

%#codegen

wlan.internal.validateParam('CHANBW',channelBandwidth,mfilename);

switch channelBandwidth
    case 'CBW20'
        % Number of data symbols per frequency segment as specified in IEEE
        % 802.11ac-2013, Section 22.3.6, Table 22-5
        numSD = 52;
        % Tone mapping distance for each bandwidth as specified in IEEE
        % 802.11ac-2013, Section 22.3.10.9.2, Table 22-19
        mappingDistance = 4;
    case 'CBW40'
        numSD = 108;
        mappingDistance = 6;
    case {'CBW80', 'CBW80+80'}
        numSD = 234;
        mappingDistance = 9;
    otherwise % case 'CBW160'
        numSD = 468;
        mappingDistance = 9;
end

if strcmp(channelBandwidth,'CBW160')
    k = (0:numSD/2-1).';
    y = mappingDistance.*mod(k,((numSD/2)/mappingDistance)) + floor(k.*mappingDistance/(numSD/2))+1;  
else
    k = (0:numSD-1).';
    y = mappingDistance.*mod(k,(numSD/mappingDistance)) + floor(k.*mappingDistance/numSD)+1;   
end
   
end