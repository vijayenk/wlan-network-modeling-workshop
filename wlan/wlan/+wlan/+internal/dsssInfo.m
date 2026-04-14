function info = dsssInfo(cfgDSSS)
%dsssInfo DSSS processing related information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   INFO = dsssInfo(CFGDSSS)
%

%   Copyright 2015-2022 The MathWorks, Inc.

%#codegen

% All clause references IEEE Std 802.11-2020

% For DSSS DataRate='1Mbps', Preamble='Short' should be ignored and
% Preamble='Long' used instead.
if (strcmpi(cfgDSSS.Preamble,'Short') && strcmpi(cfgDSSS.DataRate,'1Mbps'))
    cfgDSSS.Preamble = 'Long';
end

%---- Default scrambler initialization ----

if (strcmpi(cfgDSSS.Preamble,'Short'))
    % Clause 16.2.4 PLCP/High Rate PHY data scrambler
    info.ScramblerInitialization = int8([0 0 1 1 0 1 1]);
else
    % Clause 16.2.4 PLCP/High Rate PHY data scrambler
    % For DSSS modulation, no specific value needs to be used, but
    % here the value is as specified for Clause 16 modulation.
    info.ScramblerInitialization = int8([1 1 0 1 1 0 0]);
end

%---- Preamble information ----

if (strcmpi(cfgDSSS.Preamble,'Short'))
    % Short preamble
    % Clause 16.2.3.9 Short PLCP synchronization (shortSYNC)
    sync = zeros(56,1,'int8');
    % Clause 16.2.3.10 Short PLCP SFD field (shortSFD)
    sfd = int8(flipud([0 0 0 0  0 1 0 1  1 1 0 0  1 1 1 1].'));
    % Header modulation order and spreading factor for PPDU length
    % calculation
    headerSF = 11/2;
else
    % Clause 16.2.3.2 Long PLCP SYNC field
    % (same as Clause 15.3.3.2 PLCP SYNC field)
    sync = ones(128,1,'int8');
    % Long preamble
    % Clause 16.2.3.3 Long PLCP SFD
    % (same as Clause 15.3.3.3 PLCP SFD, defined as X'F3A0')
    sfd = int8(flipud([1 1 1 1  0 0 1 1  1 0 1 0  0 0 0 0].'));
    % Header modulation order and spreading factor for PPDU length
    % calculation
    headerSF = 11;
end

%---- Header information ----

% Create SIGNAL field - see createSIGNAL for details
% Also obtain data modulation order and spreading factor for PPDU
% length calculation
[signalField,dataSF] = createSIGNAL(cfgDSSS);

% Create LENGTH field - see createLENGTH for details
[lengthField,extensionBit] = createLENGTH(cfgDSSS);

% Create SERVICE field - see createSERVICE for details
[serviceField,info.LockedClocksBit,info.ModSelectionBit] = createSERVICE(cfgDSSS,extensionBit);

% These fields are added here to give the natural order (SIGNAL,
% SERVICE, LENGTH) in the output structure
info.LengthExtensionBit = extensionBit;

%---- Overall packet information ----

preambleSF = 11;
headerCRCLength = 16;
numPPDUSamples = ...
    (size(sync,1) + size(sfd,1)) * preambleSF + ... % Preamble
    (size(signalField,1) + size(serviceField,1) + size(lengthField,1) + headerCRCLength) * headerSF + ... % Header
    (cfgDSSS.PSDULength*8) * dataSF; % Data
info.NumPPDUSamples = numPPDUSamples;
info.TxTime = numPPDUSamples/11; % Microseconds (11 Msps)
info.Sync = sync;
info.SFD = sfd;
info.Signal = signalField;
info.Service = serviceField;
info.Length = lengthField;

end

% Create SIGNAL field
% Clause 16.2.3.4 Long PLCP SIGNAL field
% (same as Clause 16.2.3.11 Short PLCP SIGNAL field (shortSIGNAL), except
% 1Mbps is not supported there)
% (same as Clause 15.3.3.4 PLCP IEEE 802.11 SIGNAL field, except only 1Mbps
% and 2Mbps are supported there)
% Also obtain data modulation order and spreading factor 'dataSF' for PPDU
% length calculation
function [SIGNAL,dataSF] = createSIGNAL(cfgDSSS)

value = 10; % X'0A', 1Mbps
dataSF = 11; % 1Mbps
switch(cfgDSSS.DataRate)
    case '2Mbps'
        value = 20; % X'14';
        dataSF = 11/2;
    case '5.5Mbps'
        value = 55; % X'37';
        dataSF = 2;
    case '11Mbps'
        value = 110; % X'6E';
        dataSF = 1;
end

SIGNAL = int8(int2bit(value,8,false));

end

% Create SERVICE field
% Clause 16.2.3.5 Long PLCP SERVICE field
% (same as Clause 16.2.3.12 Short PLCP SERVICE field (shortSERVICE))
% Clause 15.3.3.5 PLCP IEEE 802.11 SERVICE field
function [SERVICE,b2,b3] = createSERVICE(cfgDSSS, lengthExtensionBit)

% Clause 16.2.3.5
% b2: Locked clocks bit: 0 = not, 1 = locked
% b3: Mod. selection bit: 0 = DBPSK/DQPSK/CC?, 1 = PBCC
% b7: Length extension bit

% PBCC modulation is not supported, so the modulation selection bit
% is zero
b3 = 0;

% Set locked clocks bit appropriately
% HR/DSSS modulation, Clause 16 (802.11b)
b2 = double(cfgDSSS.LockedClocks);

% Length extension bit arising from LENGTH field calculations
b7 = lengthExtensionBit;

% Create overall SERVICE field
SERVICE = int8([0 0 b2 b3 0 0 0 b7].');

end

% Create LENGTH field
% Clause 16.2.3.6 Long PLCP LENGTH field
% (same as Clause 16.2.3.13 Short PLCP LENGTH field (shortLENGTH))
% (same as Clause 15.3.3.6 PLCP LENGTH field for 1Mbps)
function [LENGTH,extensionBit] = createLENGTH(cfgDSSS)

% Get the data rate in Mbps (denoted 'R' in the example in
% Clause 16.2.3.6)
R = 1; %1Mbps
switch (cfgDSSS.DataRate)
    case '2Mbps'
        R = 2;
    case '5.5Mbps'
        R = 5.5;
    case '11Mbps'
        R = 11;
end

% Number of octets * 8 / R, rounded up to the next integer
microseconds = cfgDSSS.PSDULength*8 / R;
length = ceil(microseconds);
LENGTH = int8(int2bit(length,16,false));

% Length extension bit
if (strcmpi(cfgDSSS.DataRate,'11Mbps'))
    % Extension bit is set if ((length-microseconds)>=8/11), but to
    % avoid numeric issues set the extension bit based on receiver
    % equations.
    recoveredNumOctets = floor(length*R/8)-1; % IEEE Std 802.11-2020 page 2777
    % If use of extension bit recovers correct number of octets then
    % set it
    extensionBit = recoveredNumOctets==cfgDSSS.PSDULength;
else
    extensionBit = false;
end

end