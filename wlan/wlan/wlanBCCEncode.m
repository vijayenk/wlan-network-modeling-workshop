function y = wlanBCCEncode(x, rate)
%wlanBCCEncode Binary convolutional coding encoder.
%
%   Y = wlanBCCEncode(X,RATE) convolutionally encodes the binary input
%   data X using a binary convolutional code (BCC) at the specified RATE.
%
%   Y is a binary matrix of the same class of X with binary convolutionally
%   encoded bits as defined in IEEE 802.11-2012 Sections 18.3.5.6 and
%   20.3.11.6. The number of rows of Y is the result of dividing the number
%   of rows of input X by RATE, rounded to the next integer. The number of
%   columns of Y is equal to the number of columns of X.
%
%   X is a binary 'int8' or 'double' matrix with data bits to encode and 
%   the number of columns being the number of encoded streams. Each stream
%   is encoded separately.
%
%   RATE is a scalar, a character vector, or a string scalar specifying the 
%   coding rate. RATE must be a numeric value equal to 1/2, 2/3, 3/4, or 
%   5/6, or a character vector or string scalar equal to '1/2', '2/3', 
%   '3/4', or '5/6'.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Reference: IEEE Std 802.11-2012, Sections 18.3.5.6, 18.3.5.7, 20.3.11.6 
% for polynomials and puncturing patterns.
trellis = poly2trellis(7, [133 171]);

% Validate rate and get BCC encoder parameters
[rateValue, puncPat] = wlan.internal.bccEncodeParameters(rate);

% Validate class input x
validateattributes(x, {'int8','double'}, {'2d','binary'}, mfilename, 'BCC encoder input');
% Return an empty matrix if x is empty
if isempty(x)
    y = zeros(size(x), 'like', x);
    return;
end

% Validate size of input x
if ~isempty(puncPat)
    coder.internal.errorIf((mod(size(x,1)*2, length(puncPat)) ~= 0), 'wlan:wlanBCCEncode:InvalidInput', length(puncPat)/2);
end

y = coder.nullcopy(zeros(round(size(x,1)/rateValue), size(x,2), 'like', x));
for n = 1:size(x,2) % per encoded stream
    temp = convenc(x(:,n), trellis, puncPat);
    y(:,n) = temp(:); % (:) for codegen
end

end

