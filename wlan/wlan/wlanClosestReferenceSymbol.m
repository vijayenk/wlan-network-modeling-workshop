function refSym = wlanClosestReferenceSymbol(sym,varargin)
%wlanClosestReferenceSymbol Find the closest constellation point
%   REFSYM = wlanClosestReferenceSymbol(SYM,MODSCHEME) returns the closest
%   constellation points for given symbols SYM and modulation scheme
%   MODSCHEME.
%
%   REFSYM is an array of the same size as SYM containing the reference
%   symbols.
%
%   SYM is an array containing equalized symbols.
%
%   MODSCHEME is the modulation scheme and must be one of 'BPSK',
%   'QBPSK', 'pi/2-BPSK', 'QPSK', 'pi/2-QPSK', '16QAM', 'pi/2-16QAM',
%   '64QAM', 'pi/2-64QAM', '256QAM', '1024QAM', or '4096QAM'.
%
%   REFSYM = wlanClosestReferenceSymbol(SYM,MODSCHEME,PHASE) returns the
%   closest constellation points for the given symbols with an additional
%   rotation counter-clockwise for a specified modulation scheme.
%
%   PHASE is the counter-clockwise rotation to apply in radians. PHASE and
%   SYM have compatible sizes if, for every dimension, the dimension sizes
%   are either the same or one of them is 1.
%
%   REFSYM = wlanClosestReferenceSymbol(SYM,CFGSU) returns the closest
%   constellation points for given symbols SYM and single-user format
%   configuration object CFGSU.
%
%   CFGSU is the format configuration object of type wlanEHTTBConfig,
%   wlanHESUConfig, wlanHETBConfig, wlanDMGConfig, wlanS1GConfig,
%   wlanVHTConfig, wlanHTConfig, or wlanNonHTConfig, which specifies
%   the properties for the EHT, HE, DMG, S1G, VHT, HT-Mixed or non-HT
%   formats. DSSS modulation in NonHT format is not supported.
%
%   REFSYM = wlanClosestReferenceSymbol(SYM,CFGMU,USERNUMBER) returns
%   the closest constellation points for given symbols for an individual
%   user of interest in a multi-user configuration.
%
%   CFGMU is a multi-user configuration object of type wlanEHTMUConfig,
%   wlanHEMUConfig, wlanS1GConfig or wlanVHTConfig.
%   For S1G and VHT objects, NumUsers property should be greater than one
%   for multi-user configuration.
%
%   USERNUMBER is the user of interest, specified as an integer from 1 to
%   NumUsers, where NumUsers is the number of users in the transmission.
%   For wlanHEMUConfig and wlanEHTMUConfig, USERNUMBER is the user
%   of interest specified from 1 to length of User property of
%   wlanHEMUConfig and wlanEHTMUConfig, where User property gives
%   properties of an individual user of interest.
%
%   REFSYM = wlanClosestReferenceSymbol(SYM,CFGRX) returns the closest
%   constellation points for the given symbols SYM and the recovered HE or
%   EHT configuration object CFGRX.
%
%   CFGRX is the format configuration object of type wlanHERecoveryConfig or
%   wlanEHTRecoveryConfig.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

narginchk(2,3);
% Validate input symbols 
validateattributes(sym,{'double','single'},{'finite'},mfilename,'input symbols');
% Validate second argument
validateattributes(varargin{1},...
    {'char','string','wlanDMGConfig','wlanS1GConfig','wlanVHTConfig','wlanHTConfig','wlanNonHTConfig','wlanHESUConfig','wlanHEMUConfig','wlanHETBConfig','wlanHERecoveryConfig','wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig'},{},mfilename,'second argument');
phase = 0; % Assume no phase rotation

% Return an empty matrix if first argument is empty
if isempty(sym)
    refSym = zeros(size(sym),'like',sym);
    return;
end

% Reference constellation
if ischar(varargin{1}) || isstring(varargin{1})
    % REFSYM = wlanClosestReferenceSymbol(SYM,MODSCHEME,PHASE)
    modScheme = varargin{1};
    if nargin==3
        wlan.internal.validatePhase(varargin{2},size(sym),mfilename);
        phase = varargin{2};
    end
    % Derotate phase for input symbols
    sym = sym .* exp(-1i*phase);
    
    const = wlanReferenceSymbols(modScheme);
else
    const = wlanReferenceSymbols(varargin{1:end});
end

% Determine the closest reference symbol for each symbol
refSym = coder.nullcopy(complex(zeros(size(sym),'like',sym)));
for i = 1:numel(sym)
    [~,idx] = min(abs(sym(i)-const));
    refSym(i) = const(idx);
end
refSym = complex(refSym); % Force to complex for BPSK

end
