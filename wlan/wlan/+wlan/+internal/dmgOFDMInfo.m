function [const,varargout] = dmgOFDMInfo()
%dmgOFDMInfo Constants for DMG OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [CONST,IND] = dmgOFDMInfo() returns a structure containing constants
%   and a structure containing data and pilot indices for DMG OFDM PHY.

%   Copyright 2016-2018 The MathWorks, Inc.

%#codegen

nargoutchk(0,2);

ofdmInfo = wlanDMGOFDMInfo();

NSD = 336; % Number of data subcarriers, Table 21-4
NSP = 16;  % Number of pilot subcarriers, Table 21-4
NDC = 3;   % Number of DC subcarriers, Table 21-4
NST = 355; % Total number of subcarriers, Table 21-4
NSR = 177; % Highest subcarrier index, Table 21-4
NTONES = ofdmInfo.NumTones; % Number of active subcarriers
NFFT = ofdmInfo.FFTLength;  % FFT length
NGI = ofdmInfo.CPLength;    % Guard interval
normalizationFactor = (NFFT/sqrt(NTONES)); % OFDM normalization factor

const = struct();
const.NSD = NSD;
const.NSP = NSP;
const.NDC = NDC;
const.NST = NST;
const.NSD = NSD;
const.NSR = NSR;
const.NTONES = NTONES;
const.NFFT = NFFT;
const.NormalizationFactor = normalizationFactor;
const.NGI = NGI;

% If requested, calculate data and pilot indices
if nargout>1
    % Subcarrier indices for data and pilots
    pilotSubcarriers = ofdmInfo.ActiveFrequencyIndices(ofdmInfo.PilotIndices);
    dataSubcarriers = ofdmInfo.ActiveFrequencyIndices(ofdmInfo.DataIndices);

    % Indices for data and pilots with FFT size
    dataIndices = ofdmInfo.ActiveFFTIndices(ofdmInfo.DataIndices);
    pilotIndices = ofdmInfo.ActiveFFTIndices(ofdmInfo.PilotIndices);

    ind = struct;
    ind.DataSubcarriers = dataSubcarriers;
    ind.PilotSubcarriers = pilotSubcarriers;
    ind.DataIndices = dataIndices;
    ind.PilotIndices = pilotIndices;
    varargout{1} = ind;
end

end