classdef uhrChannelCoding < uint8
%uhrChannelCoding Enumeration for ChannelCoding types
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Use the uhrChannelCoding enumeration to set the ChannelCoding property of
%   a <a href="matlab:help('uhrUser')">uhrUser</a> object used within a <a href="matlab:help('uhrMUConfig')">uhrMUConfig</a> object.
%
%   ChannelCoding enumeration:
%
%   bcc    - Binary convolution coding
%   ldpc   - Low-density-parity-check
%   ldpc2x - Low-density-parity-check for codeword size 2x1944
%
%   See also wlan.type.ChannelCoding

%   Copyright 2025 The MathWorks, Inc.

    enumeration
        bcc (0)
        ldpc (1)
        ldpc2x (2)
    end
end