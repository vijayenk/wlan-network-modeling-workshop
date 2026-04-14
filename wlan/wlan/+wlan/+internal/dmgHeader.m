function y = dmgHeader(varargin)
%dmgHeader DMG header processing
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgHeader(CFGDMG) generates the DMG format Header field time-domain
%   waveform for SC and OFDM PHYs.
%
%   Y is the time-domain DMG Header field signal. It is a complex column
%   vector of length Ns, where Ns represents the number of time-domain
%   samples.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.
%
%   Y = dmgHeader(PSDU,CFGDMG) generates the DMG format Header field
%   time-domain waveform for Control PHY.
%
%   PSDU is a column vector containing the PSDU bits.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

if nargin==1
    cfgDMG = varargin{1};
    coder.internal.errorIf(strcmp(phyType(cfgDMG),'Control'),'wlan:dmgHeader:NoPSDUControl');
    psdu = zeros(0,1); % Empty PSDU
else
    psdu = varargin{1};
    cfgDMG = varargin{2};
end

% Generate header bits
headerBits = wlan.internal.dmgHeaderBits(cfgDMG);

% Encode header bits
encodedBits = wlan.internal.dmgHeaderEncode(headerBits,psdu,cfgDMG);

% Modulate header bits
y = wlan.internal.dmgHeaderModulate(encodedBits,cfgDMG);

end