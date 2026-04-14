function [aInt,bInt,varargout] = intersectRUIndices(ka,kb)
%intersectRUIndices RU indices intersection
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   [AINT,BINT,KINT] = intersectRUIndices(KA,KB) for subcarrier
%   indices in vectors KA and KB, returns the index vectors AINT and
%   BINT, and common subcarrier indices KINT, such that KINT = KA(AINT)
%   and KINT = KB(BINT).

%   Copyright 2021 The MathWorks, Inc.

%#codegen

[LIA,LOCB] = ismember(ka,kb);
tmp = (1:numel(ka))';
aInt = tmp(LIA);
bInt = LOCB(LIA);
if nargout>2
   varargout{1} = ka(LIA); % Common indices
end
end