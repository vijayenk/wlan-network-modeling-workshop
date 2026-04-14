function heValidateGI(gi,varargin)
%heValidateGI Validate guard interval
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   heValidateGI(GI) validates the guard interval passed is a scalar
%   double, and 0.8, 1.6, or 3.2.
%
%   heValidateGI(GI,OPTIONS) validates the guard interval passed is a
%   scalar double, and is one of the values in the vector OPTIONS.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

if nargin>1
    opts = varargin{1};
else
    opts = [0.8 1.6 3.2];
end

validateattributes(gi,{'double'},{'scalar'})
mustBeMember(gi,opts);

end