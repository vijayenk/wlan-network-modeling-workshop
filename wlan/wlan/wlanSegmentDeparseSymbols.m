function y = wlanSegmentDeparseSymbols(x, chanBW)
%wlanSegmentDeparseSymbols Segment deparser of data subcarriers
%
%   Y = wlanSegmentDeparseSymbols(X, CHANBW) performs segment deparsing on
%   the input X as per IEEE 802.11ac-2013 Section 22.3.10.9.3 when CHANBW
%   is 'CBW16', or 'CBW160'.
%
%   Y is an array of size Nsd-by-Nsym-by-Nss containing the deparsed
%   frequency segments. Nsd is the number of data subcarriers, Nsym is the
%   number of OFDM symbols, and Nss is the number of spatial streams. 
%
%   X is an array of size (Nsd/Nseg)-by-Nsym-by-Nss-by-Nseg containing the
%   frequency segments to deparse. When CHANBW is 'CBW16' or 'CBW160', Nseg
%   is 2, otherwise it is 1.
%
%   CHANBW is a character vector or string scalar specifying the channel
%   bandwidth. It must be equal to 'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16',
%   'CBW20', 'CBW40', 'CBW80', or 'CBW160'.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Validate chanBW
chanBW = wlan.internal.validateParam('S1GVHTCHANBW', chanBW, mfilename);

% Validate input x
validateattributes(x, {'double'}, {}, mfilename, 'Input');

% IEEE Std 802.11ac-2013 Section 22.3.10.9.3
if any(strcmp(chanBW, {'CBW16', 'CBW160'}))
    NSD80 = 234;
    
    % Validate input x 
    [numSDx, ~, numSS, numSeg] = size(x);
    coder.internal.errorIf(~any(numSS == 1:8), 'wlan:wlanSegmentDeparseSymbols:InvalidInputNUMSS');
    if ndims(x) ~= 4
        coder.internal.error('wlan:wlanSegmentDeparseSymbols:InvalidInputSize');
    elseif numSDx ~= NSD80
        coder.internal.error('wlan:wlanSegmentDeparseSymbols:InvalidInputNUMSD');
    elseif numSeg ~= 2
        coder.internal.error('wlan:wlanSegmentDeparseSymbols:InvalidInputSegments');
    end
    
    % Return an empty matrix if x is empty
    if isempty(x)
        y = zeros(2*NSD80, 0, numSS);
        return;
    end
    
    % Deparse symbols
    y = wlan.internal.segmentDeparseSymbolsCore(x);
else
    y = x;
end

end
