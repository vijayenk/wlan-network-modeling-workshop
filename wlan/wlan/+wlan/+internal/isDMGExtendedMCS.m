function flag = isDMGExtendedMCS(mcs)
%isExtendedMCS Determine if MCS is a SC extended MCS
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   FLAG = isDMGExtendedMCS(CFGDMG) returns true if the MCS is an SC
%   extended MCS, otherwise it returns false. MCS is a character vector or
%   numeric integer.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

if ischar(mcs)
    flag = any(strcmp(mcs,{'9.1','12.1','12.2','12.3','12.4','12.5','12.6'}));
else
    flag = false; % Extended MCS must be a char vector
end

end