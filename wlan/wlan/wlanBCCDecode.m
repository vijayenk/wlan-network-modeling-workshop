function y = wlanBCCDecode(x, rate, varargin)
%wlanBCCDecode Binary convolutional coding decoder.
%
%   Y = wlanBCCDecode(X,RATE) convolutionally decodes the input X using a
%   binary convolutional code (BCC) at the specified RATE.
%
%   Y is a binary int8 matrix containing decoded bits with convolutional
%   codes defined in IEEE 802.11-2012 Sections 18.3.5.6 and 20.3.11.6.
%   The number of rows of Y is equal to the number of rows of input X
%   multiplied by RATE, rounded to the next integer. The number of columns
%   of Y is equal to the number of columns of X.
%
%   X is a single, double, or int8 matrix with symbols to decode and the
%   number of columns being the number of encoded streams. Each stream is
%   decoded separately. X must be a double real matrix with log-likelihood
%   ratios when DECTYPE is 'soft' or it is not specified. Positive values
%   represent a logical 0 and negative values a logical 1.
%
%   RATE is a scalar, a character vector, or a string scalar specifying the 
%   coding rate. RATE must be a numeric value equal to 1/2, 2/3, 3/4, or 
%   5/6, or a character vector or string scalar equal to '1/2', '2/3', 
%   '3/4', or '5/6'.
%
%   Y = wlanBCCDecode(...,DECTYPE) allows the decoding type to be 
%   specified. DECTYPE is a character vector or a string scalar. It can be 
%   'hard' for a hard input Viterbi algorithm, or 'soft' for a soft input 
%   Viterbi algorithm without any quantization. Default DECTYPE is 'soft'.
%
%   Y = wlanBCCDecode(...,TDEPTH) allows the traceback depth to be 
%   specified. TDEPTH represents the traceback depth of the Viterbi
%   decoding algorithm and is a positive integer scalar not larger than the
%   number of input symbols in X.
%
%   Y = wlanBCCDecode(X,RATE,DECTYPE,TDEPTH) allows the decoding type and
%   the traceback depth to be specified. DECTYPE and TDEPTH can be placed
%   in any order after RATE.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(2,4);

% Reference: IEEE Std 802.11-2012, Sections 18.3.5.6, 18.3.5.7, 20.3.11.6 
% for polynomials and puncturing patterns.
trellis = poly2trellis(7, [133 171]);

% Validate rate and get BCC decoder parameters
[rateValue, puncPat, defaultTDepth] = wlan.internal.bccEncodeParameters(rate);
% Get default puncPat in vitdec for rate = 1/2
if rateValue == 1/2
    puncPat = ones(log2(trellis.numOutputSymbols), 1);
end

if nargin == 3
    if isnumeric(varargin{1}) % (X,RATE,TDEPTH)
        % Traceback depth
        tDepth = varargin{1};
        validateattributes(tDepth, {'double'}, {'scalar','positive','integer'}, mfilename, 'Traceback depth');
        applyDefaultTDepth = 0;
        % Set default decType
        vitDecType = 'unquant'; % vitdec LLR based decoder
    else % (X,RATE,DECTYPE)
        % Decoder type
        decType = varargin{1};
        vitDecType = mapDecType(decType);
        % Set default traceback depth
        tDepth = defaultTDepth;
        applyDefaultTDepth = 1;
    end
elseif nargin == 4 
    if isnumeric(varargin{1}) % (X,RATE,TDEPTH,DECTYPE)
        [tDepth, decType] = deal(varargin{:});
    else % (X,RATE,DECTYPE,TDEPTH)
        [decType, tDepth] = deal(varargin{:});
    end
    vitDecType = mapDecType(decType);
    validateattributes(tDepth, {'double'}, {'scalar','positive','integer'}, mfilename, 'Traceback depth');
    applyDefaultTDepth = 0;
else % (X,RATE)
    % Set default values
    vitDecType = 'unquant'; % vitdec LLR based decoder
    tDepth = defaultTDepth;
    applyDefaultTDepth = 1;
end

% Validate class of input x
% 'double' real input for 'unquant' decoding
% 'int8' or 'double' binary input for 'hard' decoding
if strcmp(vitDecType, 'unquant')
    validateattributes(x, {'single','double'}, {'2d','real'}, mfilename, 'BCC soft decoder input');
else
    validateattributes(x, {'single','double','int8'}, {'2d','binary'}, mfilename, 'BCC hard decoder input');
end

% Return an empty matrix if x is empty
if isempty(x)
    y = zeros(size(x), 'int8');
    return;
end

% Validate size input x
coder.internal.errorIf(mod(size(x,1),sum(puncPat)) ~= 0, 'wlan:wlanBCCEncode:InvalidInput', sum(puncPat));

% Validate traceback depth
if applyDefaultTDepth
    % When defaultTDepth is applied, check size of input x w.r.t. tDepth
    coder.internal.errorIf((tDepth > size(x,1)/(sum(puncPat)/length(puncPat))/2), ...
        'wlan:wlanBCCEncode:InvalidInputTDepth', ceil(tDepth*(sum(puncPat)/length(puncPat))*2));
else
    % When the user specifies tDepth
    coder.internal.errorIf((tDepth > size(x,1)/(sum(puncPat)/length(puncPat))/2), ...
        'wlan:wlanBCCEncode:InvalidTDepth', size(x,1)/(sum(puncPat)/length(puncPat))/2);
end

y = coder.nullcopy(zeros(round(size(x,1)*rateValue), size(x,2), 'int8'));
for n = 1:size(x,2) % per encoded stream
    temp = vitdec(x(:,n), trellis, tDepth, 'trunc', vitDecType, puncPat);
    y(:,n) = temp(:); % (:) for codegen
end

end

function vitDecType = mapDecType(decType)
% mapDecType maps 'hard' and 'soft' decType inputs into vitdec decoding
% types: 'hard' and 'unquant', respectively.
coder.internal.errorIf((~ischar(decType) && ~(isstring(decType) && isscalar(decType))) || ...
    (~any(strcmpi(decType, {'soft','hard'}))), 'wlan:wlanBCCEncode:InvalidDecType');
if strcmpi(decType, 'soft')
    vitDecType = 'unquant'; % vitdec LLR based decoder
else
    vitDecType = 'hard';
end
end

