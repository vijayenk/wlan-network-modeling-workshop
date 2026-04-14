function varargout = s1gLTF(cfgS1G,varargin)
%s1gLTF Long Training Field for S1G transmission format (S1G-LTF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y1,Y2N] = s1gLTF(CFGS1G) generates LTF1 (Y1) and LTF2...N (Y2N) for
%   the Short Preamble >= 2 MHz mode when CFGS1G.ChannelBandwidth is
%   'CBW2','CBW4','CBW8', or 'CBW16', and when CFGS1G.Preamble is 'Short'.
%   When CFGS1G.ChannelBandwidth is 'CBW1' the first and subsequent LTFs
%   for the 1 MHz mode are generated.
%
%   Y1 is the time-domain first LTF signal. It is a complex matrix of size
%   Ns1-by-Nt where Ns1 represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   Y2N is the time-domain 2..N LTF signal. It is a complex matrix of size
%   Ns2-by-Nt where Ns2 represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGS1G is the format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a> which
%   specifies the parameters for the S1G format.
%
%   Y = s1gLTF(cfgS1G,OSF) generates the S1G-LTF for the given oversampling
%   factor OSF. When not specified 1 is assumed.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

% Generate LTF as per IEEE P802.11ah/D5.0 Sections 24.3.8.2.1.3 and
% 24.3.8.3.3

nargoutchk(0,2);

% Validate S1G configuration object
validateattributes(cfgS1G,{'wlanS1GConfig'},{'scalar'},mfilename,'S1G format configuration object');
coder.internal.errorIf(strcmp(packetFormat(cfgS1G),'S1G-Long'),'wlan:shared:UndefinedFieldForS1GLong');
validateConfig(cfgS1G,'SMapping');

% Get LTF sequences
numSTSTotal = sum(cfgS1G.NumSpaceTimeStreams); 
[LTF,Pvhtltf,Nltf] = wlan.internal.vhtltfSequence(cfgS1G.ChannelBandwidth,numSTSTotal);

% Get OFDM parameters
cfgOFDM = wlan.internal.s1gOFDMConfig(cfgS1G.ChannelBandwidth,'Long','LTF',numSTSTotal);

% Apply tone rotation
ltfToneRotated = LTF.*cfgOFDM.CarrierRotations;

% Define LTF and output variable sizes
ltfSTS = complex(zeros(cfgOFDM.FFTLength,numSTSTotal,Nltf));
Adata = Pvhtltf(1:numSTSTotal,1:Nltf); % A matrix for data subcarriers (P matrix)
Apilots = Pvhtltf(1:numSTSTotal,1);    % A matrix for pilot subcarriers (first column of P matrix)
csh = wlan.internal.getCyclicShiftVal('S1G',numSTSTotal, ...
    wlan.internal.cbwStr2Num(cfgS1G.ChannelBandwidth));

% Generate each S1G-LTF symbol
for i = 1:Nltf
    % Each column of ltfSTS is a space time stream
    ltfSTS(cfgOFDM.DataIndices,:,i) = ltfToneRotated(cfgOFDM.DataIndices) .* Adata(:, i).';
    ltfSTS(cfgOFDM.PilotIndices,:,i) = ltfToneRotated(cfgOFDM.PilotIndices) .* Apilots.';
end

% Apply cyclic shift per space-time stream
ltfCycShift = wlan.internal.cyclicShift(permute(ltfSTS,[1 3 2]),csh,cfgOFDM.FFTLength);

% Spatial mapping
ltfSpatialMapped = wlan.internal.spatialMap(ltfCycShift, ...
    cfgS1G.SpatialMapping,cfgS1G.NumTransmitAntennas,cfgS1G.SpatialMappingMatrix);

% OFDM modulation
TGI2 = cfgOFDM.FFTLength/2; % Number of long GI samples
TGI = cfgOFDM.FFTLength/4;  % Number of  normal GI samples
if strcmp(packetFormat(cfgS1G),'S1G-1M')
    % First LTF; 2 LTS preceded by GI2, then 2 LTS each preceded by GI
    varargout{1} = wlan.internal.ofdmModulate(repmat(ltfSpatialMapped(:,1,:),1,4), ...
        [TGI2 0 TGI TGI],varargin{:})*cfgOFDM.NormalizationFactor;
    if nargout>1
        % Subsequent LTFs: LTS preceded by GI
        if numSTSTotal==1
            % No LTF preset for 1 space-time stream
            varargout{2} = complex(zeros(0,cfgS1G.NumTransmitAntennas));
        else
            varargout{2} = wlan.internal.ofdmModulate(ltfSpatialMapped(:,2:end,:), ...
                TGI,varargin{:})*cfgOFDM.NormalizationFactor;
        end
    end
else % cfgS1G.Preamble = 'Short'
    % First LTF; 2 LTS preceded by GI2
    varargout{1} = wlan.internal.ofdmModulate(repmat(ltfSpatialMapped(:,1,:),1,2), ...
        [TGI2 0],varargin{:})*cfgOFDM.NormalizationFactor;
    if nargout>1
        % Subsequent LTFs: LTS preceded by GI
        if numSTSTotal==1
            % No LTF preset for 1 space-time stream
            varargout{2} = complex(zeros(0,cfgS1G.NumTransmitAntennas));
        else
            varargout{2} = wlan.internal.ofdmModulate(ltfSpatialMapped(:,2:end,:), ...
                TGI,varargin{:})*cfgOFDM.NormalizationFactor;
        end
    end
end

end
