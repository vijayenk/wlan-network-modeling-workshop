function y = heCyclicShift(x,cbw,k,varargin)
%heCyclicShift Cyclic shift
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heCyclicShift(X,CBW,K) applies the cyclic shift for the HE-fields.
%
%   X is an Nst-by-Nsym-by-Nsts array containing the data to cyclic shift.
%
%   CBW is the channel bandwidth in MHz.
%
%   K is an Nst-by-1 column vector containing the subcarrier indices of the
%   subcarriers within X.
%
%   Y = heCyclicShift(X,CBW,K,STSVEC) applies the cyclic shift assuming the
%   space-time streams in X are indices STSVEC. STSVEC is a Nsts-by-1
%   vector. If not specified the indices are assumed to be 1:Nsts.

%   Copyright 2017-2018 The MathWorks, Inc.

%#codegen

if nargin>3
    stsVec = varargin{1};
    numSTSTotal = stsVec(end);
else
    [~,~,numSTSTotal] = size(x);
    stsVec = (1:numSTSTotal).';
end
Nfft = (cbw/20)*256;

% Get cyclic shift
csh = wlan.internal.getCyclicShiftVal('VHT',numSTSTotal,cbw);
cshSTS = csh(stsVec);

% Apply cyclic shift
y = wlan.internal.cyclicShift(x,cshSTS,Nfft,k);

end