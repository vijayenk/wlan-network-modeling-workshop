function y = wlanVHTData(PSDU,cfgVHT,varargin)
%wlanVHTData VHT Data field processing of the PSDU input
% 
%   Y = wlanVHTData(PSDU,CFGVHT) generates the VHT format Data field
%   time-domain waveform for the input PHY Service Data Unit (PSDU).
%
%   Y is the time-domain VHT Data field signal. It is a complex matrix of
%   size Ns-by-Nt, where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   PSDU is the PHY service data unit input to the PHY. For single-user,
%   PSDU can be a double or int8 typed binary column vector of length
%   CFGVHT.PSDULength*8. Alternatively, PSDU can be a row cell array with
%   length equal to number of users. The ith element in the cell array must
%   be a double or int8 typed binary column vector of length
%   CFGVHT.PSDULength(i)*8.
%
%   CFGVHT is the format configuration object of type wlanVHTConfig which
%   specifies the parameters for the VHT format.
%
%   Y = wlanVHTData(...,SCRAMINIT) optionally allows specification of the
%   scrambler initialization. When not specified, it defaults to a value of
%   93. When specified, it can be a double or int8-typed integer scalar or
%   1-by-Nu row vector between 1 and 127, inclusive, where Nu represents
%   the number of users. Alternatively, SCRAMINIT can be a double or
%   int8-typed binary 7-by-1 column vector or 7-by-Nu matrix, without any
%   all-zero column. If it is a scalar or column vector, it applies to all
%   users. Otherwise, each user can have its own scrambler initialization
%   as indicated by the corresponding column.
%
%   Y = wlanVHTData(...,'OversamplingFactor',OSF) generates the VHT-Data
%   oversampled by a factor OSF. OSF must be >=1. The resultant cyclic
%   prefix length in samples must be integer-valued for all symbols. The
%   default is 1.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(2,5);

% Validate format configuration input
validateattributes(cfgVHT, {'wlanVHTConfig'}, {'scalar'}, mfilename, ...
    'VHT format configuration object');
cfgInfo = validateConfig(cfgVHT, 'SMappingMCS');
numUsers = cfgVHT.NumUsers;

% Default options
osf = 1;
scramInitBits = uint8(repmat([1; 0; 1; 1; 1; 0; 1], 1, numUsers)); % Default is 93
% Parse options
if nargin>2
    if ~(ischar(varargin{1}) || isstring(varargin{1}))
        scramInit = varargin{1};
        % Validate scrambler initialization input
        scramInitBits = wlan.internal.validateVHTScramblerInit(scramInit,numUsers,mfilename);
        osf = wlan.internal.parseOSF(varargin{2:end});
    else
        osf = wlan.internal.parseOSF(varargin{:});
    end
end

% Early return for NDP, if invoked by user.
if any(cfgVHT.APEPLength == 0)
    y = complex(zeros(0, cfgVHT.NumTransmitAntennas));
    return;
end

% Validate PSDU input
PSDUMU = wlan.internal.validateVHTPSDUInput(PSDU,cfgVHT.PSDULength,numUsers,mfilename);

% Set up implicit parameters
chanBW      = cfgVHT.ChannelBandwidth;
numSTS      = cfgVHT.NumSpaceTimeStreams; % [1 Nu]
numSTSTotal = sum(numSTS);
numOFDMSym  = cfgInfo.NumDataSymbols; % [1 1]
numPadBits  = cfgInfo.NumPadBits;     % [1 Nu]
mcsTable    = wlan.internal.getRateTable(cfgVHT);
numSD       = mcsTable.NSD(1);        % [1 1]
vecAPEPLen  = repmat(cfgVHT.APEPLength, 1, ...
                     numUsers/length(cfgVHT.APEPLength)); % [1 Nu]
vecMCS      = repmat(cfgVHT.MCS, 1, numUsers/length(cfgVHT.MCS)); % [1 Nu]

% Set channel coding to cell type
coder.varsize('channelCoding',[1,4]);
channelCoding = getChannelCoding(cfgVHT);

% Get data subcarriers for each symbol and space-time stream for all users
data = complex(zeros(numSD, numOFDMSym, numSTSTotal));
mSTBC = (cfgVHT.NumUsers == 1)*(cfgVHT.STBC ~= 0) + 1;
numSymMaxInit = numOFDMSym - cfgInfo.ExtraLDPCSymbol*mSTBC;  % Eq: 22-65

for u = 1:numUsers
    data(:, :, sum(numSTS(1:u-1))+(1:numSTS(u))) = ...        
        getDataSubcarrierPerUser(chanBW, vecAPEPLen(u), vecMCS(u), ...
        numOFDMSym, numPadBits(u), mcsTable, u, PSDUMU{u}, ...
        scramInitBits(:,u), numSTS(u), channelCoding{u}, numSymMaxInit, mSTBC);
end
    
% Get OFDM parameters
ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-Data', chanBW, 1, cfgVHT.GuardInterval);

% Generate pilots for VHT, IEEE Std 802.11ac-2013, Eqn 22-95
n = (0:numOFDMSym-1).';
z = 4; % Offset by 4 to allow for L-SIG, VHT-SIG-A, VHT-SIG-B pilot symbols
pilots = wlan.internal.vhtPilots(n, z, chanBW, numSTSTotal);

% Pack data and pilot carrying subcarriers
packedData = coder.nullcopy(complex(zeros(ofdmInfo.NumTones, numOFDMSym, numSTSTotal)));
packedData(ofdmInfo.DataIndices,:,:) = data;    
packedData(ofdmInfo.PilotIndices,:,:) = pilots;

% Tone rotation
carrierRotations = wlan.internal.vhtCarrierRotations(ofdmInfo.NumSubchannels);
rotatedData = packedData .* carrierRotations(ofdmInfo.NominalActiveFFTIndices);

% Cyclic shift
csh = wlan.internal.getCyclicShiftVal('VHT', numSTSTotal, wlan.internal.cbwStr2Num(chanBW));
dataCycShift = wlan.internal.cyclicShift(rotatedData, csh, ofdmInfo.FFTLength, ofdmInfo.ActiveFrequencyIndices);

% Spatial mapping
dataSpatialMapped = wlan.internal.spatialMap(dataCycShift, cfgVHT.SpatialMapping, cfgVHT.NumTransmitAntennas, cfgVHT.SpatialMappingMatrix);

% OFDM modulate
fftGrid = complex(zeros(ofdmInfo.FFTLength, numOFDMSym, cfgVHT.NumTransmitAntennas));
fftGrid(ofdmInfo.ActiveFFTIndices,:,:) = dataSpatialMapped;
scalingFactor = ofdmInfo.FFTLength/(sqrt(ofdmInfo.NumTones*numSTSTotal));
y = wlan.internal.ofdmModulate(fftGrid, ofdmInfo.CPLength,osf)*scalingFactor;

end

function dataPerUser = getDataSubcarrierPerUser(chanBW, APEPLength, MCS, ...
    numOFDMSym, numPadBits, mcsTable, userIdx, PSDU, scramInitBits, numSTS, ...
    channelCoding, numSymMaxInit, mSTBC)
% Only for Data packets, not for Null-Data-Packets

% Determine VHT-SIG-B bits per user, 
%   Section 22.3.8.3.6, IEEE Std 802.11ac-2013
APEPLenOver4 = ceil(APEPLength/4);
if length(mcsTable.Nss) == 1 % SU PPDU allocation
    switch chanBW
        case 'CBW20' % 20
            bitsPerUser = [int2bit(APEPLenOver4, 17, false); ones(3, 1, 'int8')];
        case 'CBW40' % 21
            bitsPerUser = [int2bit(APEPLenOver4, 19, false); ones(2, 1, 'int8')];
        otherwise    % 23 for {'CBW80', 'CBW80+80', 'CBW160'}
            bitsPerUser = [int2bit(APEPLenOver4, 21, false); ones(2, 1, 'int8')];
    end
else % MU PPDU allocation
    switch chanBW
        case 'CBW20' % 20
            bitsPerUser = int8([int2bit(APEPLenOver4, 16, false); int2bit(MCS, 4, false)]);
        case 'CBW40' % 21
            bitsPerUser = int8([int2bit(APEPLenOver4, 17, false); int2bit(MCS, 4, false)]);
        otherwise    % 23 for {'CBW80', 'CBW80+80', 'CBW160'}
            bitsPerUser = int8([int2bit(APEPLenOver4, 19, false); int2bit(MCS, 4, false)]);
    end
end

% Assemble the service bits,
%   Section 22.3.10.2 and 22.3.10.3, IEEE Std 802.11ac-2013
%   SERVICE = [scrambler init = 0; Reserved = 0; CRC of SIGB bits];
serviceBits = [zeros(7,1); 0; wlan.internal.crcGenerate(bitsPerUser)];

paddedData = [serviceBits; PSDU; zeros(numPadBits, 1)];

% Encode, parse and map bits to create space-time streams
dataPerUser = wlan.internal.vhtGetSTSPerUser(paddedData, scramInitBits, ...
    mcsTable, chanBW, numOFDMSym, userIdx, numSTS, channelCoding, ...
    numSymMaxInit, mSTBC);

end
