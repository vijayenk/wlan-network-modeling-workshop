function [y, bits]= wlanVHTSIGB(cfgVHT,varargin)
%wlanVHTSIGB VHT Signal B (VHT-SIG-B) field
%
%   [Y, BITS] = wlanVHTSIGB(CFGVHT) generates the VHT Signal B (VHT-SIG-B)
%   field time-domain waveform for the VHT transmission format.
%
%   Y is the time-domain VHT-SIG-B field signal. It is a complex matrix of
%   size Ns-by-Nt where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   BITS is the non-repeated signaling bits used for the VHT-SIG-B field.
%   It is an int8-typed, real matrix of size Nb-by-Nu, where Nb is 26 for
%   20 MHz, 27 for 40 MHz, and 29 for 80 MHz and 160 MHz channel
%   bandwidths, respectively, and Nu is the number of users.
%
%   CFGVHT is the format configuration object of type wlanVHTConfig which
%   specifies the parameters for the VHT format.
%
%   Y = wlanVHTSIGB(CFGVHT,'OversamplingFactor',OSF) generates the
%   VHT-SIG-B oversampled by a factor OSF. OSF must be >=1. The resultant
%   cyclic prefix length in samples must be integer-valued for all symbols.
%   The default is 1.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(1,3);
validateattributes(cfgVHT, {'wlanVHTConfig'}, {'scalar'}, mfilename, ...
                   'VHT format configuration object');
validateConfig(cfgVHT, 'SMappingMCS');

osf = wlan.internal.parseOSF(varargin{:});

chanBW      = cfgVHT.ChannelBandwidth;
numUsers    = cfgVHT.NumUsers;
numSTS      = cfgVHT.NumSpaceTimeStreams;
numSTSTotal = sum(numSTS);

% Set up constants related to channel bandwidth
%   Table 22-5, 22-14, IEEE Std 802.11ac-2013
switch chanBW
  case 'CBW20'
    numSD = 52;
    numSIGBBits = 26;
  case 'CBW40'
    numSD = 108;
    numSIGBBits = 27;
  case 'CBW80'
    numSD = 234;
    numSIGBBits = 29;
  otherwise  % 'CBW160'
    numSD = 468;
    numSIGBBits = 29;
end

% Fill data subcarriers for all users
APEPLen = repmat(cfgVHT.APEPLength, 1, numUsers/length(cfgVHT.APEPLength));
vecMCS  = repmat(cfgVHT.MCS, 1, numUsers/length(cfgVHT.MCS));
data    = complex(zeros(numSD, 1, numSTSTotal));
bits    = zeros(numSIGBBits, numUsers, 'int8');

for u = 1:cfgVHT.NumUsers
    [dataForThisUser, bits(:, u)] = getDataSubcarrierPerUser(chanBW, numUsers, APEPLen(u), vecMCS(u));
    data(:, :, sum(numSTS(1:u-1))+(1:numSTS(u))) = repmat(dataForThisUser, 1, 1, numSTS(u));
end

% Apply the first column of the PVHTLTF matrix
if any(numSTSTotal == [4 7 8])
    % Flip the 4th and 8th STS
    % For all other numSTS, PVHTLTF first column is all ones.
    data(:,:,4:4:end) = -data(:,:,4:4:end);
end

% Generate pilot sequence, from Eqn 22-47, IEEE Std 802.11ac-2013
n = 0; % One OFDM symbol (index 0) in VHT-SIG-B
z = 3; % Offset by 3 to allow for L-SIG and VHT-SIG-A pilot symbols
pilots = wlan.internal.vhtPilots(n, z, chanBW, numSTSTotal); % Pilots: Nsp-by-1-by-Nsts

% Get OFDM parameters
ofdm = wlan.internal.vhtOFDMInfo('VHT-SIG-B', chanBW, 1);

csh = wlan.internal.getCyclicShiftVal('VHT', numSTSTotal, ofdm.NumSubchannels*20);

% Perform spatial mapping, CSD and OFDM modulation
gamma = wlan.internal.vhtCarrierRotations(ofdm.NumSubchannels);
y = wlan.internal.vhtSIGBModulate(data, pilots, gamma, ofdm, csh, ...
                                  cfgVHT.NumTransmitAntennas, cfgVHT.SpatialMapping, cfgVHT.SpatialMappingMatrix, osf);

end

function [dataPerUser, bitsPerUser] = getDataSubcarrierPerUser(chanBW, numUsers, APEPLength, MCS)

% Set up the bits
if APEPLength == 0 % NDP support for a single user
    % IEEE Std 802.11ac-2013, Table 22-15.
    switch chanBW
      case 'CBW20' % 20
        sigbBits = [0 0 0 0 0 1 1 1 0 1 0 0 0 1 0 0 0 0 1 0];
      case 'CBW40' % 21
        sigbBits = [1 0 1 0 0 1 0 1 1 0 1 0 0 0 1 0 0 0 0 1 1];
      otherwise % {'CBW80', 'CBW80+80', 'CBW160'} % 23
        sigbBits = [0 1 0 1 0 0 1 1 0 0 1 0 1 1 1 1 1 1 1 0 0 1 0];
    end

    bitsPerUser = [sigbBits zeros(1,6,'int8')].';
else

    % Bit values as per IEEE Std 802.11ac-2013, Table 22-14.
    %   Right-msb orientation for the length bits
    APEPLenOver4 = ceil(APEPLength/4);
    if 1 == numUsers % SU PPDU allocation
        switch chanBW
          case 'CBW20' % 26
            bitsPerUser = [int2bit(APEPLenOver4, 17, false); ones(3,1, 'int8'); ...
                           zeros(6,1,'int8')];
          case 'CBW40' % 27
            bitsPerUser = [int2bit(APEPLenOver4, 19, false); ones(2,1, 'int8'); ...
                           zeros(6,1,'int8')];
          otherwise    % 29 for {'CBW80', 'CBW80+80', 'CBW160'}
            bitsPerUser = [int2bit(APEPLenOver4, 21, false); ones(2,1, 'int8'); ...
                           zeros(6,1,'int8')];
        end
    else % MU PPDU allocation
        switch chanBW
          case 'CBW20' % 26
            bitsPerUser = [int2bit(APEPLenOver4, 16, false); int2bit(MCS, 4, false); ...
                           zeros(6,1,'int8')];
          case 'CBW40' % 27
            bitsPerUser = [int2bit(APEPLenOver4, 17, false); int2bit(MCS, 4, false); ...
                           zeros(6,1,'int8')];
          otherwise    % 29 for {'CBW80', 'CBW80+80', 'CBW160'}
            bitsPerUser = [int2bit(APEPLenOver4, 19, false); int2bit(MCS, 4, false); ...
                           zeros(6,1,'int8')];
        end
    end
end

% Perform encoding, interleaving and constellation mapping
dataPerUser = wlan.internal.vhtSIGBEncodeInterleaveMap(bitsPerUser, chanBW);

end

