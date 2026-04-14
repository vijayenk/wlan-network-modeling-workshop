function y = dmgSymBlkGIInsert(x,varargin)
%dmgSymBlkGIInsert DMG SC PHY blocking and GI insertion
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgSymBlkGIInsert(X) blocks and inserts a GI according to IEEE
%   802.11ad Section 21.6.3.2.5. A GI is not appended to the end of the
%   waveform.
%
%   Y = dmgSymBlkGIInsert(X,APPENDPOSTFIX) appends a GI postfix if
%   APPENDPOSTFIX is true.

%   Copyright 2016-2018 The MathWorks, Inc.

%#codegen

% Optional argument to append GI
narginchk(1,2)
if nargin>1
    postfixGI = varargin{1};
else
    postfixGI = false;
end

NumDataSymPerBlk = 448; % Symbols
NumBlks = size(x,1)/NumDataSymPerBlk;

% Block data and add GI with pi/2 rotation per sample
Ga = wlanGolaySequence(64);
yt = cat(1,repmat(rotate(Ga),1,NumBlks),reshape(x,NumDataSymPerBlk,NumBlks));

% Add postfix GI with pi/2 rotation per sample
if postfixGI
    y = cat(1,yt(:),rotate(Ga));
else
    y = yt(:);
end
end

% pi/2 rotation per sample
function y = rotate(x)
    % Equivalent to: y = x.*exp(1i*pi*(0:size(x,1)-1).'/2);
    y = x.*repmat(exp(1i*pi*(0:3).'/2),size(x,1)/4,1);
end