function y = s1gData(PSDU,cfgS1G,varargin)
%s1gData S1G Data field processing of the PSDU input
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = s1gData(PSDU,cfgS1G) generates the S1G format Data field
%   time-domain waveform for the input PHY Service Data Unit (PSDU).
%
%   Y is the time-domain S1G Data field signal. It is a complex matrix of
%   size Ns-by-Nt, where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   PSDU is the PHY service data unit input to the PHY. For single-user,
%   PSDU can be a double or int8 typed binary column vector of length
%   cfgS1G.PSDULength*8. Alternatively, PSDU can be a row cell array with
%   length equal to number of users. The ith element in the cell array must
%   be a double or int8 typed binary column vector of length
%   cfgS1G.PSDULength(i)*8.
%
%   cfgS1G is the format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a> which
%   specifies the parameters for the S1G format.
%
%   Y = s1gData(...,SCRAMINIT) optionally allows specification of the
%   scrambler initialization. When not specified, it defaults to a value of
%   93. When specified, it can be a double or int8-typed integer scalar or
%   1-by-Nu row vector between 1 and 127, inclusive, where Nu represents
%   the number of users. Alternatively, SCRAMINIT can be a double or
%   int8-typed binary 7-by-1 column vector or 7-by-Nu matrix, without any
%   all-zero column. If it is a scalar or column vector, it applies to all
%   users. Otherwise, each user can have its own scrambler initialization
%   as indicated by the corresponding column.
%
%   Y = s1gData(cfgS1G,SCRAMINIT,OSF) generates the S1G-Data for the given
%   oversampling factor OSF. When not specified 1 is assumed.
% 
%   Example: 
%   %  Generate signal for a 8MHz S1G Data field for single-user single
%   %  transmit antenna configuration.
% 
%      cfgS1G = wlanS1GConfig('ChannelBandwidth', 'CBW8', ...
%                            'NumTransmitAntennas', 1, ...
%                            'NumSpaceTimeStreams', 1, ...
%                            'MCS', 4);
%      inpPSDU = randi([0 1], cfgS1G.PSDULength*8, 1);    % PSDU in bits
%      y = wlan.internal.s1gData(inpPSDU,cfgS1G);
%
%   %  Generate signal for a 2MHz S1G Data field for two-user multiple
%   %  transmit antenna configuration.
% 
%      cfgS1G = wlanS1GConfig('ChannelBandwidth', 'CBW2', ...
%                            'NumUsers', 2, ...
%                            'Preamble', 'Long', ...
%                            'GroupID', 2, ...
%                            'NumTransmitAntennas', 2, ...
%                            'NumSpaceTimeStreams', [1 1], ...
%                            'MCS', [4 8],...
%                            'APEPLength', [1024 2048]);
%      inp1PSDU = randi([0 1], cfgS1G.PSDULength(1)*8, 1); % User 1 PSDU 
%      inp2PSDU = randi([0 1], cfgS1G.PSDULength(2)*8, 1); % User 2 PSDU
%      inpPSDUs = {inp1PSDU, inp2PSDU};               % Concatenate PSDUs
%      y = wlan.internal.s1gData(inpPSDUs,cfgS1G);
%    
%   See also wlanS1GConfig, wlanWaveformGenerator.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

narginchk(2,4);
% Validate S1G configuration object
validateattributes(cfgS1G,{'wlanS1GConfig'},{'scalar'},mfilename, ...
    'S1G format configuration object');
cfgInfo = validateConfig(cfgS1G,'SMappingMCSTPilots');
numUsers = cfgS1G.NumUsers;

% Default baseband rate
osf = 1;

if nargin == 2
    % As per IEEE Std 802.11-2012 Section L.1.5.2.
    scramInitBits = uint8(repmat([1; 0; 1; 1; 1; 0; 1], 1, numUsers)); % Default is 93      
else
    scramInit = varargin{1};
    % Validate scrambler initialization input
    scramInitBits = wlan.internal.validateVHTScramblerInit(scramInit,numUsers,mfilename);
    
    if nargin == 4
       osf = varargin{2}; 
    end
end

% Early return for NDP, if invoked by user
if any(cfgS1G.APEPLength==0)
    y = complex(zeros(0,cfgS1G.NumTransmitAntennas));
    return;
end

% Validate PSDU input
PSDUMU = wlan.internal.validateVHTPSDUInput(PSDU,cfgS1G.PSDULength,numUsers,mfilename);

% Set up implicit parameters
chanBW      = cfgS1G.ChannelBandwidth;
numSTS      = cfgS1G.NumSpaceTimeStreams; % [1 Nu]
numSTSTotal = sum(numSTS);
numOFDMSym  = cfgInfo.NumDataSymbols; % [1 1]
numPadBits  = cfgInfo.NumPadBits;     % [1 Nu]
mcsTable    = wlan.internal.getRateTable(cfgS1G);
numSD       = mcsTable.NSD(1);        % [1 1]

% Get data subcarriers for all users
data = complex(zeros(numSD,numOFDMSym,numSTSTotal));
for u = 1:numUsers
    data(:,:,sum(numSTS(1:u-1))+(1:numSTS(u))) = getDataSubcarrierPerUser( ...
        chanBW,numOFDMSym,numPadBits(u),mcsTable,u,PSDUMU{u},scramInitBits(:,u),numSTS(u));
end

% Get OFDM parameters
cfgOFDM = wlan.internal.s1gOFDMConfig(chanBW,cfgS1G.GuardInterval,'Data',numSTSTotal,cfgS1G.TravelingPilots,numOFDMSym);

% Generate pilots as per Eqns 24-51 to 24-53.
pilots = s1gPilots(chanBW,numSTSTotal,numOFDMSym,cfgS1G.TravelingPilots,numUsers);

% Permute to Nsp-by-Nsts-by-Nsym for efficient accessing
pilots = permute(pilots,[1 3 2]);

% Use the number of pilot symbols to repeat indices for mapping; this
% allows traveling or fixed pilots for S1G
numPsym = size(cfgOFDM.PilotIndices,2);

packedData = complex(zeros(cfgOFDM.FFTLength,numOFDMSym,numSTSTotal));
for i = 1:numOFDMSym
    % Data packing with pilot insertion
    packedData(cfgOFDM.DataIndices(:,mod(i-1,numPsym)+1),i,:) = data(:,i,:);    
    packedData(cfgOFDM.PilotIndices(:,mod(i-1,numPsym)+1),i,:) = pilots(:,:,i);
end

% Perform spatial mapping, CSD and OFDM modulation
TGI = cfgOFDM.FFTLength/4; % Number of long GI samples
cpLen = [TGI cfgOFDM.CyclicPrefixLength*ones(1,numOFDMSym-1)]; % First CP is always long

% Tone rotation
rotatedData = packedData .* cfgOFDM.CarrierRotations;

% Cyclic shift
csh = wlan.internal.getCyclicShiftVal('S1G',numSTSTotal,wlan.internal.cbwStr2Num(chanBW));
dataCycShift = wlan.internal.cyclicShift(rotatedData,csh,cfgOFDM.FFTLength);

% Spatial mapping
dataSpatialMapped = wlan.internal.spatialMap(dataCycShift,cfgS1G.SpatialMapping,cfgS1G.NumTransmitAntennas,cfgS1G.SpatialMappingMatrix);

% OFDM modulate
y = wlan.internal.ofdmModulate(dataSpatialMapped,cpLen,osf)*cfgOFDM.NormalizationFactor;

end

function dataPerUser = getDataSubcarrierPerUser(chanBW, ...
    numOFDMSym,numPadBits,mcsTable,userIdx,PSDU,scramInitBits,numSTS)
% Only for Data packets, not for Null-Data-Packets

% Assemble the service bits,
%   Section 4.3.9.2, IEEE P802.11ah/D5.0
%   SERVICE = [scrambler init = 0; Reserved = 0;];
serviceBits = zeros(8,1,'int8');

paddedData = [serviceBits; PSDU; zeros(numPadBits,1)];

% Get the IQ per space-time stream for each user
dataPerUser = wlan.internal.vhtGetSTSPerUser( ...
    paddedData,scramInitBits,mcsTable,chanBW,numOFDMSym,userIdx,numSTS);
end

% Returns Np-by-Nsym-by-Nsts pilot values for S1G data field. Np is the
% number of pilots, Nsym is the number of OFDM symbols and Nsts is the
% number of space time streams.
function pilots = s1gPilots(chanBW,numSTSTotal,numOFDMSym,travelingPilots,numUsers)
% Pilot sequence dependent on bandwidth, preamble and MU/SU
if strcmp(chanBW,'CBW1') % 1 MHz
    z = 6; % Eqn 24.53
    n = (0:numOFDMSym-1).';
else % >= 2 MHz
    if numUsers>1  
        % MU bit set to 1 in SIG-A (Eqn 24-52). Approximate
        % p_z(n) and P^k_(z(n)-2) which works out as p_(n+3)
        % and P^k_(n+1) by using sym number + 1
        z = 3-1; % The is +3 in the standard
        n = (0:numOFDMSym-1).'+1; 
    else
        % Long preamble, MU bit set to 0 in SIG-A (Eqn 24-52) or short
        % preamble (Eqn 24-51)
        z = 2;
        n = (0:numOFDMSym-1).';
    end
end

% Generate pilots for VHT, IEEE Std 802.11ac-2013, Eqn 22-95
pilots = wlan.internal.vhtPilots(n,z,chanBW,numSTSTotal); % Np-by-Nsym-by-Nsts

% Apply mapping matrix (Eqn 24-51,52,53) with revision for CID 8082 in
% 11r16/0020r1
P = wlan.internal.mappingMatrix(numSTSTotal);
if (travelingPilots==true) && (numSTSTotal==2)
    gn = mod(0:(numOFDMSym-1),2)+1; % Index 1st or 2nd column of P matrix
else
    gn = ones(1,numOFDMSym); % Index 1st column of P matrix
end
Pd = P(1:numSTSTotal,gn); % Nsys-by-Nsym
Pd_permute = repmat(permute(Pd,[3 2 1]),size(pilots,1),1,1);
pilots = pilots .* Pd_permute;

if travelingPilots==true
    pilots = pilots*1.5; % Power boost as per Eqn 24-47
end
end
