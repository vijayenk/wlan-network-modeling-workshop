function y = wlanHTLTF(cfgHT,varargin)
%wlanHTLTF HT Long Training Field (HT-LTF)
%
%   Y = wlanHTLTF(CFGHT) generates the HT Long Training Field (HT-LTF)
%   time-domain waveform for the HT-Mixed transmission format.
%
%   Y is the time-domain HT-LTF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and
%   Nt represents the number of transmit antennas.
%
%   CFGHT is the format configuration object of type wlanHTConfig which
%   specifies the parameters for the HT-Mixed format.
%
%   Y = wlanHTLTF(CFGHT,'OversamplingFactor',OSF) generates the HT-LTF
%   oversampled by a factor OSF. OSF must be >=1. The resultant cyclic
%   prefix length in samples must be integer-valued for all symbols. The
%   default is 1.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(1,3);
validateattributes(cfgHT, {'wlanHTConfig'}, {'scalar'}, mfilename, ...
                   'HT-Mixed format configuration object');
validateConfig(cfgHT, 'SMapping'); 
osf = wlan.internal.parseOSF(varargin{:});

chanBW = cfgHT.ChannelBandwidth;
numSTS = cfgHT.NumSpaceTimeStreams;
numTx = cfgHT.NumTransmitAntennas;
spatialMapMtx = cfgHT.SpatialMappingMatrix;
if wlan.internal.inESSMode(cfgHT)
    numESS = cfgHT.NumExtensionStreams;
else
    numESS = 0;
end

% Get OFDM parameters
ofdm = wlan.internal.vhtOFDMInfo('HT-LTF', chanBW, 1);
dataIdx     = ofdm.ActiveFFTIndices(ofdm.DataIndices);
pilotIdx    = ofdm.ActiveFFTIndices(ofdm.PilotIndices);
chanBWInMHz = ofdm.NumSubchannels * 20;

% HT training fields are subset of VHT
[HTLTF, Phtltf, Ndltf, Neltf] = wlan.internal.vhtltfSequence(chanBW, ...
    numSTS, numESS);
Nltf = Ndltf + Neltf;

gamma = wlan.internal.vhtCarrierRotations(ofdm.NumSubchannels);
htltfToneRotated = HTLTF .* gamma;

% Define HTLTF and output variable sizes
htltfLen = (ofdm.FFTLength + ofdm.CPLength)*osf;
y = coder.nullcopy(complex(zeros(htltfLen*Nltf, numTx)));

% Generate HT-Data LTFs
htltfSTS = complex(zeros(ofdm.FFTLength, numSTS, Ndltf));
Pd = Phtltf(1:numSTS,1:Ndltf);
for i = 1:Ndltf
    htltfSTS(dataIdx,:,i) = repmat(htltfToneRotated(dataIdx), 1, numSTS) .* ...
        repmat(Pd(:,i).', length(dataIdx), 1);
    
    htltfSTS(pilotIdx,:,i)= repmat(htltfToneRotated(pilotIdx), 1, numSTS) .* ...
        repmat(Pd(:,i).', length(pilotIdx), 1);
end

% Cyclic shift addition
% The cyclic shift is applied per stream.
csh = wlan.internal.getCyclicShiftVal('VHT', numSTS, chanBWInMHz); 
htltfCycShift = wlan.internal.cyclicShift(permute(htltfSTS,[1 3 2]), csh, ofdm.FFTLength);

% Spatial mapping
if strcmp(cfgHT.SpatialMapping, 'Custom')
    if ismatrix(spatialMapMtx)
        if isscalar(spatialMapMtx) || isvector(spatialMapMtx)
            htlfSpatialMapped = wlan.internal.spatialMap( ...
                htltfCycShift, cfgHT.SpatialMapping, numTx, spatialMapMtx);
        else
            htlfSpatialMapped = wlan.internal.spatialMap( ...
                htltfCycShift, cfgHT.SpatialMapping, numTx, ...
                spatialMapMtx(1:numSTS, :));
        end
    else % 3D
        htlfSpatialMapped = wlan.internal.spatialMap( ...
            htltfCycShift, cfgHT.SpatialMapping, ...
            numTx, spatialMapMtx(:, 1:numSTS, :));
    end
else
    htlfSpatialMapped = wlan.internal.spatialMap(htltfCycShift, ...
        cfgHT.SpatialMapping, numTx, spatialMapMtx);
end

% OFDM modulation
modOut = wlan.internal.ofdmModulate(htlfSpatialMapped,ofdm.CPLength,osf);
y(1:htltfLen*Ndltf,:) = modOut * ofdm.FFTLength/sqrt(numSTS*ofdm.NumTones); 

% Append the HT-Extension LTFs as well, if specified
if numESS>0
    htltfESS = complex(zeros(ofdm.FFTLength, numESS, Neltf));
    Pe = Phtltf(1:numESS,1:Neltf);
    for i = 1:Neltf
        htltfESS(dataIdx,:,i) = repmat(htltfToneRotated(dataIdx),1, ...
            numESS).*repmat(Pe(:,i).', length(dataIdx), 1);
        
        htltfESS(pilotIdx,:,i) = repmat(htltfToneRotated(pilotIdx),1, ...
            numESS).*repmat(Pe(:,i).', length(pilotIdx), 1);
    end
        
    % Cyclic shift addition
    % The cyclic shift is applied per stream.
    csh = wlan.internal.getCyclicShiftVal('VHT', numESS, chanBWInMHz);
    htltfCycShift = wlan.internal.cyclicShift(permute(htltfESS,[1 3 2]), csh, ofdm.FFTLength);

    % Spatial mapping
    % Only 'Custom' spatial mapping can be used with ESS
    if ismatrix(spatialMapMtx)
        % No scalar or vector is possible, only a matrix as always at least
        % 2 transmit antennas when expansion used
        htlfSpatialMapped = wlan.internal.spatialMap( ...
            htltfCycShift, cfgHT.SpatialMapping, numTx, ...
            spatialMapMtx(numSTS+1:end, :) );
    else % 3D
        htlfSpatialMapped = wlan.internal.spatialMap(htltfCycShift, ...
            cfgHT.SpatialMapping, numTx, spatialMapMtx(:, numSTS+1:end, :) );
    end

    % OFDM modulation
    modOut = wlan.internal.ofdmModulate(htlfSpatialMapped,ofdm.CPLength,osf);
    y(htltfLen*Ndltf+1:end,:) = modOut * ofdm.FFTLength/sqrt(numESS*ofdm.NumTones); 

end
