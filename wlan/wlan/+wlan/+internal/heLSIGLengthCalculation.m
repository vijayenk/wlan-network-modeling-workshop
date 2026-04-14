function length = heLSIGLengthCalculation(cfg,varargin)
%heLSIGLengthCalculation Returns the L-SIG length value of an HE packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   LENGTH = heLSIGLengthCalculation(cfg) returns the L-SIG length value of
%   the packet using IEEE P802.11ax/D4.1, Equation 27-11.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   LENGTH = heLSIGLengthCalculation(...,TXTIME) returns the L-SIG length
%   value of the packet using IEEE P802.11ax/D4.1, Equation 27-11 for the
%   given TXTIME.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

if nargin == 1
    [~,TXTIME] = wlan.internal.hePLMETxTimePrimative(cfg);
else
    TXTIME = varargin{1};
end

% Assume no signal extension in ns (5 GHz)
SignalExtension = 0;
if isa(cfg,'wlanHEMUConfig') || strcmp(packetFormat(cfg),'HE-EXT-SU')
    m = 1;
else
    m = 2; % Trigger or HE-SU
end

% The IEEE P802.11ax/D4.1, Equation 27-11 is updated to handle the TXTIME in ns
length = ceil((TXTIME-SignalExtension-20e3)/4e3)*3-3-m;

end