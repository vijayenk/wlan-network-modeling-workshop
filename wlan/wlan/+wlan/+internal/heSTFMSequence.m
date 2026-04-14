function M = heSTFMSequence
%heSTFMSequence M sequence of HE-STF field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   M = heTBSTFSequence(CBW,M) returns M sequence of HE-STF field as
%   defined in IEEE Std 802.11ax-2021, Equation 27-22

%   Copyright 2022 The MathWorks, Inc.

%#codegen

M = [-1; -1; -1; 1; 1; 1; -1; 1; 1; 1; -1; 1; 1; -1; 1];