function [y,varargout]= s1gSIGB(cfgS1G,varargin)
%s1gSIGB S1G SIG-B Field (S1G-SIGB)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y, BITS] = s1gSIGB(CFGS1G) generates the S1G Signal B (S1G-SIG-B)
%   field time-domain waveform for the S1G transmission format.
%
%   Y is the time-domain SIG-B field signal. It is a complex matrix of
%   size Ns-by-Nt where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   BITS is the non-repeated signaling bits used for the SIG-B field. It is
%   an int8-typed, real matrix of size Nb-by-Nu, where Nb is 26 for 2 MHz,
%   27 for 4 MHz, and 29 for 8 MHz and 16 MHz channel bandwidths,
%   respectively, and Nu is the number of users.
%
%   CFGS1G is the format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a> which
%   specifies the parameters for the S1G format.
%
%   Y = s1gSIGB(cfgS1G,OSF) generates the S1G-SIG-B for the given
%   oversampling factor OSF. When not specified 1 is assumed.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

% Generate SIG-B as per IEEE P802.11ah/D5.0 Section 24.3.8.2.2.2.5

nargoutchk(0,2);

% Validate S1G configuration object
validateattributes(cfgS1G,{'wlanS1GConfig'},{'scalar'},mfilename,'S1G format configuration object');
coder.internal.errorIf(~strcmp(packetFormat(cfgS1G),'S1G-Long'),'wlan:shared:UndefinedFieldForS1GShort1M');
validateConfig(cfgS1G,'SMappingMCS');

chanBW = cfgS1G.ChannelBandwidth;
numUsers = cfgS1G.NumUsers; 
numSTS = cfgS1G.NumSpaceTimeStreams;
numSTSTotal = sum(numSTS);

% Get OFDM parameters
cfgOFDM = wlan.internal.s1gOFDMInfo('S1G-SIG-B',cfgS1G);

% Special case for a single user; we repeat the first D-LTF
if cfgS1G.NumUsers==1
    nargoutchk(0,1); % No bits to return
    osf = 1;
    if nargin>1
        osf = varargin{1};
    end
    dltf = wlan.internal.s1gDLTF(cfgS1G,osf);
    y = dltf(1:cfgOFDM.NumSubchannels*80*osf,:); % 80 samples @ 2 MHz in 1st LTF symbol
    return;
end

% Number of bits in the symbol is dependent on bandwidth
switch chanBW
  case 'CBW2'
    numSIGBBits = 26;
  case 'CBW4'
    numSIGBBits = 27;
  case 'CBW8'
    numSIGBBits = 29;
  otherwise % 'CBW16'
    numSIGBBits = 29;
end

% Fill data subcarriers for all users       
vecMCS = repmat(cfgS1G.MCS,1,numUsers/length(cfgS1G.MCS));
data = complex(zeros(numel(cfgOFDM.DataIndices),1,numSTSTotal));
bits = zeros(numSIGBBits,numUsers,'int8');
for u = 1:cfgS1G.NumUsers
    [dataForThisUser,bits(:, u)] = getDataSubcarrierPerUser(chanBW,numUsers,numSIGBBits,vecMCS(u));
    data(:,sum(numSTS(1:u-1))+(1:numSTS(u))) = repmat(dataForThisUser,1,1,numSTS(u));
end
varargout{1} = bits;

% Generate pilot sequence
n = 0; % One OFDM symbol in SIG-B
z = 2; % Offset by 2 to allow for SIG-A pilot symbols
pilots = wlan.internal.vhtPilots(n,z,chanBW,numSTSTotal); % Pilots: Nsp-by-1-by-Nsts

% Apply first column to data and pilots
P = wlan.internal.mappingMatrix(numSTSTotal); % Orthogonal mapping matrix
Pd = P(1:numSTSTotal,1);
pilots = pilots.*repmat(permute(Pd,[2 3 1]),[size(pilots,1) 1 1]);
Pdp = permute(Pd,[3 2 1]);
data = data .* Pdp(:,1,:); % Index for codegen

% Cyclic shift addition
csh = wlan.internal.getCyclicShiftVal('S1G',numSTSTotal, ...
    wlan.internal.cbwStr2Num(cfgS1G.ChannelBandwidth));
% Perform spatial mapping, CSD and OFDM modulation
gamma = wlan.internal.s1gCarrierRotations(cfgS1G.ChannelBandwidth);
y = wlan.internal.vhtSIGBModulate(data,pilots,gamma,cfgOFDM,csh, ...
    cfgS1G.NumTransmitAntennas,cfgS1G.SpatialMapping,cfgS1G.SpatialMappingMatrix,varargin{:});

end

% Returns the spatial streams per user to encode the MCS
function [dataPerUser, bitsPerUser] = getDataSubcarrierPerUser(chanBW, ...
    numUsers,numSIGBBits,MCS)

% Table 24-16 - Fields in the SIG-B field for MU PPDU, IEEE P802.11ah/D5.0
bitsPerUser = zeros(numSIGBBits,1,'int8');
for u=1:numUsers
    switch chanBW
      case 'CBW2'
        bitsPerUser(1:4) = int2bit(MCS, 4, false); % MCS
        bitsPerUser(5:12) = ones(8,1,'int8'); % Reserved
        bitsPerUser(13:20) = wlan.internal.crcGenerate(bitsPerUser(1:12)); % CRC
        bitsPerUser(21:26) = zeros(1,6,'int8'); % Tail
      case 'CBW4'
        bitsPerUser(1:4) = int2bit(MCS, 4, false); % MCS
        bitsPerUser(5:13) = ones(9,1,'int8'); % Reserved
        bitsPerUser(14:21) = wlan.internal.crcGenerate(bitsPerUser(1:13)); % CRC
        bitsPerUser(22:27) = zeros(1,6,'int8'); % Tail
    otherwise % {'CBW8','CBW16'}
        bitsPerUser(1:4) = int2bit(MCS, 4, false); % MCS
        bitsPerUser(5:15) = ones(11,1,'int8'); % Reserved
        bitsPerUser(16:23) = wlan.internal.crcGenerate(bitsPerUser(1:15)); % CRC
        bitsPerUser(24:29) = zeros(1,6,'int8'); % Tail
    end
end

% Perform encoding, interleaving and constellation mapping
dataPerUser = wlan.internal.vhtSIGBEncodeInterleaveMap(bitsPerUser,chanBW);

end
