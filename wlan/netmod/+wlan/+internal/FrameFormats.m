classdef FrameFormats
%FrameFormats Indicate the constant integer values to use for different
%frame formats
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   OBJ = FrameFormats creates an object with the all the supported frame
%   format constant values. All the supported values are mentioned below.
%
%   FrameFormats properties:
%
%   NonHT(1)         - Non-HT frame format
%   HTMixed(2)       - HT-Mixed frame format
%   VHT(3)           - VHT frame format
%   HE_SU(4)         - HE single user frame format
%   HE_EXT_SU(5)     - HE extended range single user frame format
%   HE_MU(6)         - HE multi-user frame format
%   HE_TB(7)         - HE trigger-based frame format
%   EHT_SU(8)        - EHT single user frame format
%   EHT_MU(9)        - EHT multi-user frame format
%   EHT_TB(10)       - EHT trigger-based frame format


%   Copyright 2022-2025 The MathWorks, Inc.

properties (Constant)
    % Non-HT frame format
    NonHT = 1

    % HT-Mixed frame format
    HTMixed = 2

    % VHT frame format
    VHT = 3

    % HE single user frame format
    HE_SU = 4

    % HE extended range single user frame format
    HE_EXT_SU = 5

    % HE multi-user frame format
    HE_MU = 6

    % HE trigger-based frame format
    HE_TB = 7

    % EHT single user frame format
    EHT_SU = 8

    % EHT multi-user frame format
    EHT_MU = 9

    % EHT trigger-based frame format
    EHT_TB = 10
end
end
