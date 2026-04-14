function y = wlanSegmentParseSymbols(x, chanBW)
%wlanSegmentParseSymbols Segment parser of data subcarriers.
%
%   Y = wlanSegmentParseSymbols(X, CHANBW) performs the inverse operation
%   of the segment deparsing on the input X defined in IEEE 802.11ac-2013
%   Section 22.3.10.9.3 when CHANBW is 'CBW16', or 'CBW160'.
%
%   Y is an array of size (Nsd/Nseg)-by-Nsym-by-Nss-by-Nseg containing the 
%   the frequency segments obtained from the inverse operation of segment 
%   deparsing. Nsd is the number of data subcarriers, Nsym is the number of
%   OFDM symbols, Nss is the number of spatial streams, and Nseg is the
%   number of frequency segments. When CHANBW is 'CBW16' or 'CBW160', Nseg
%   is 2, otherwise it is 1.
%
%   X is an array of size Nsd-by-Nsym-by-Nss containing the equalized data
%   to be segmented.
%
%   CHANBW is a character vector or string scalar specifying the channel
%   bandwidth. It must be equal to 'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16',
%   'CBW20', 'CBW40', 'CBW80', or 'CBW160'.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Validate chanBW
chanBW = wlan.internal.validateParam('S1GVHTCHANBW', chanBW, mfilename);

% Validate input x
validateattributes(x, {'double','single'}, {'3d'}, mfilename, 'Input');

% Inverse operation of IEEE Std 802.11ac-2013 Section 22.3.10.9.3
if any(strcmp(chanBW, {'CBW16', 'CBW160'}) )
    NSD160 = 468;
    
    % Validate input x
    [numSDx, ~, numSS] = size(x);
    coder.internal.errorIf(~any(numSS == 1:8), 'wlan:wlanSegmentDeparseSymbols:InvalidInputNUMSS');
    if numSDx ~= NSD160
        coder.internal.error('wlan:wlanSegmentDeparseSymbols:InvalidInputNUMSDParse');
    end
    y = wlan.internal.segmentParseSymbolsCore(x);
else
    y = x;
end
