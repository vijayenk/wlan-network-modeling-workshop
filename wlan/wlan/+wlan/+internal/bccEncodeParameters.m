function [rateValue, puncPat, tDepth] = bccEncodeParameters(rate)
% bccEncodeParameters Returns BCC encoder and BCC decoder parameters for a 
% given rate
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [RATEVALUE, PUNCPAT] = bccEncodeParameters(RATE) returns the numeric
%   value of the coding rate and the puncture pattern vector for a given
%   RATE. RATE can be a scalar, a character vector, or a string scalar 
%   specifying the coding rate. RATE must be a numeric value equal to 1/2,
%   2/3, 3/4, or 5/6, or a character vector or string scalar equal to 
%   '1/2', '2/3', '3/4', or '5/6'.
%
%   [RATEVALUE, PUNCPAT, TDEPTH] = bccEncodeParameters(RATE) also returns
%   the default value of the traceback depth to apply to the Viterbi
%   decoding algorithm.
%
%   See also wlanBCCEncode and wlanBCCDecode.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

% Validate rate
if ischar(rate) || (isstring(rate) && isscalar(rate))
    coder.internal.errorIf(~any(strcmp(rate, {'1/2','2/3','3/4','5/6'})), 'wlan:wlanBCCEncode:InvalidCodingRate');
    switch rate
        case '1/2'
            rateValue = 1/2;
        case '2/3'
            rateValue = 2/3;
        case '3/4'
            rateValue = 3/4;
        otherwise % '5/6'
            rateValue = 5/6;
    end
else
    coder.internal.errorIf(~isscalar(rate) || ~any(rate == [1/2, 2/3, 3/4, 5/6]), 'wlan:wlanBCCEncode:InvalidCodingRate');
    rateValue = rate;
end

% For wlanBCCDecode based on Viterbi decoder:
% Traceback depth thumb rule = 2.5m/(1-r), where m=6
% Override the thumb rule:
%   for SIG-B decoding in 20 MHZ = 26.
%   for L-SIG decoding = 24.

switch rateValue
    case 1/2
        % rate 1/2 - no puncturing
        puncPat = zeros(0,1); % empty is the default value in convenc
        tDepth = 30;
    case 2/3
        puncPat = [1 1 1 0].';
        tDepth = 45;
    case 3/4
        puncPat = [1 1 1 0 0 1].';
        tDepth = 60;
    otherwise % 5/6
        puncPat = [1 1 1 0 0 1 1 0 0 1].';
        tDepth = 90;
end

end
