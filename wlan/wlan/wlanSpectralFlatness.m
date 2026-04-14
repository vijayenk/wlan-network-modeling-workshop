function [pass,deviation,testSC] = wlanSpectralFlatness(channelEst,format,cbw,varargin)
%wlanSpectralFlatness Test spectral flatness.
%
%   PASS = wlanSpectralFlatness(CHANNELEST,FORMAT,CBW) tests spectral
%   flatness by using channel estimates CHANNELEST for WLAN packet format
%   FORMAT and channel bandwidth CBW. The function compares the spectral
%   flatness measurements with the standard-specified range and outputs
%   test result PASS.
%
%   PASS is a logical 0 or 1, specifying whether the measured spectral
%   flatness is within the standard-specified range.
%
%   CHANNELEST is a complex Nst-by-Nsts-by-Nr array characterizing the
%   estimated channel for the data and pilot subcarriers, where Nst is the
%   number of occupied subcarriers, Nsts is the total number of space-time
%   streams, and Nr is the number of receive antennas.
%
%   FORMAT is a character vector or string scalar specifying the packet
%   format and must be 'Non-HT', 'HT', 'VHT', 'S1G', 'HE', or 'EHT'.
%
%   CBW is a character vector or string specifying the channel bandwidth
%   and must be 'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW5', 'CBW10', 'CBW16',
%   'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.
%
%   PASS = wlanSpectralFlatness(CHANNELEST,FORMAT,CBW,RUINDICES) tests
%   spectral flatness by using channel estimates CHANNELEST for an HE
%   packet format FORMAT, channel bandwidth CBW, and resource unit (RU)
%   indices RUINDICES. The function compares the spectral flatness
%   measurements with the standard-specified range and outputs test result
%   PASS.
%
%   CHANNELEST is a complex cell array, where each cell has a dimension of
%   Nst-by-Nsts-by-Nr.  Nst is the number of occupied subcarriers, Nsts is
%   the total number of space-time streams, and Nr is the number of receive
%   antennas. Each cell array supports these RUs for OFDMA, mixed OFDMA and
%   MU-MIMO waveforms for WLAN packet format HE.
%
%   ---------------------------------------------
%   |     RU     |       Channel Bandwidth      |
%   ---------------------------------------------
%   |   26-tone  |  (CBW20,CBW40,CBW80,CBW160)  |
%   |   52-tone  |  (CBW20,CBW40,CBW80,CBW160)  |
%   |  106-tone  |  (CBW20,CBW40,CBW80,CBW160)  |
%   |  242-tone  |     (CBW40,CBW80,CBW160)     |
%   |  484-tone  |        (CBW80,CBW160)        |
%   |  996-tone  |          (CBW160)            |
%   ---------------------------------------------
%
%   RUINDICES is a vector containing the index of each RU with the same
%   size as the CHANNELEST cell array. The RU index specifies the location
%   of the RU within the channel. For example, in a 20 MHz transmission
%   with allocation index 0, there are nine possible 26 tone RUs. RU# 26-1
%   (size 26, index 1) is the RU occupying the lowest absolute frequency
%   within the 20 MHz, and RU# 26-9 (size 26, index 9) is the RU occupying
%   the highest absolute frequency. Specify RUINDICES as [1 2 3 4 5 6 7 8
%   9]. RUINDICES can also be a scalar when a 20 MHz subchannel is
%   punctured. RUINDICES is required only when the CHANNELEST is cell type
%   and format is HE.
%
%   PASS = wlanSpectralFlatness(CHANNELEST,FORMAT,CBW,RUINDICES,RUSIZES,PREAMBLEPUNC)
%   tests spectral flatness by using channel estimates CHANNELEST for an
%   EHT packet format FORMAT, channel bandwidth CBW, RU indices RUINDICES,
%   RU sizes RUSIZES, and the preamble puncturing flag PREAMBLEPUNC. The
%   function compares the spectral flatness measurements with the
%   standard-specified range and outputs test result PASS.
%
%   CHANNELEST is a complex cell array for OFDMA waveforms where each cell
%   has a dimension of Nst-by-Nsts-by-Nr. For non-OFDMA and OFDMA waveforms
%   with single RU, CHANNELEST is a single or double matrix with dimensions
%   Nst-by-Nsts-by-Nr. Nst is the number of occupied subcarriers, Nsts is
%   the total number of space-time streams, and Nr is the number of receive
%   antennas.
%
%   RUINDICES is a cell array containing the index of each RU or Multi-RU
%   (MRU). The RU index specifies the location of the RU/MRU within the
%   channel. For example, in a 20 MHz transmission, the allocation index
%   49 has a 106+26 MRU, a 52+26 MRU, and a 26 RU. Specify RUINDICES as
%   {[1 5], [3 8], 9}.
%
%   RUSIZES is a cell array containing the RU sizes of each RU/MRU. For
%   example, in a 20 MHz transmission, the allocation index 49 has a 106+26
%   MRU, a 52+26 MRU, and a 26 RU. Specify RUSIZES as
%   {[106 26], [52 26], 26}.
%
%   PREAMBLEPUNC is a logical scalar specifying the presence of preamble
%   puncturing. PREAMBLEPUNC is an optional input with the default value
%   set to FALSE.
%
%   [PASS,DEVIATION,TESTSC] = wlanSpectralFlatness(CHANNELEST,FORMAT,CBW)
%   returns the power deviations DEVIATION, in dB, in each test subcarrier
%   from the average power level across lower test subcarriers. The
%   function splits the subcarrier indices into two sets based on their
%   absolute frequency and returns these indices in two-element cell array
%   TESTSC. The first entry of TESTSC contains the lower test subcarriers,
%   and the second entry contains the upper test subcarriers.
%
%   DEVIATION is a 1-by-2 cell array containing matrices of size Nlsc-by-Nr
%   and Nusc-by-Nr, representing the power deviations per antenna across
%   lower and upper test subcarriers, respectively. Nr is the number
%   of receiver antennas, Nlsc is the number of lower test subcarriers, and
%   Nusc is the number of upper test subcarriers.
%
%   TESTSC is a 1-by-2 cell array containing column vectors of length Nlsc
%   and Nusc representing the lower and upper test subcarrier indices,
%   respectively.

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

narginchk(3,6);

format = validatestring(format,{'Non-HT','HT','VHT','S1G','HE','EHT'},mfilename,'Format');
cbw = validatestring(cbw,{'CBW1','CBW2','CBW4','CBW5','CBW8','CBW10','CBW16','CBW20','CBW40','CBW80','CBW160','CBW320'},mfilename,'channel bandwidth');
channelBW = wlan.internal.cbwStr2Num(cbw);

isPreamblePunc = false;
if nargin>3
    if strcmp(format,'EHT')
        if iscell(varargin{1})
            % Validate channel estimates
            if iscell(channelEst)
                validateattributes(channelEst,{'cell'},{'vector'},mfilename,'Channel Estimates');
                for ii = 1:numel(channelEst)
                    validateChannelEstValues(channelEst{ii}); % values in the cells
                end
            else
                validateChannelEstValues(channelEst);
            end

            if nargin==4
                % RU Sizes must be specified when RU Indices are provided.
                coder.internal.error(...
                    'wlan:wlanSpectralFlatness:NoRUSizes',format);
            else
                % Validate RU indices and RU sizes cell arrays
                validateattributes(varargin{1},{'cell'},{'vector'},mfilename,'RU Indices');
                validateattributes(varargin{2},{'cell'},{'vector'},mfilename,'RU Sizes');
                validateattributes(cell2mat(reshape(varargin{1},1,[])),{'single','double'},{'vector','positive','integer','nonempty'},mfilename,'RU indices');
                validateattributes(cell2mat(reshape(varargin{2},1,[])),{'single','double'},{'vector','positive','integer','nonempty'},mfilename,'RU indices');
                ruIndices = varargin{1};
                ruSizes = varargin{2};

                if iscell(channelEst) % OFDMA
                    % Number of cells of ruIndices must be same as that of channelEst
                    coder.internal.errorIf(~(isequal(numel(channelEst),numel(ruIndices))), ...
                        'wlan:wlanSpectralFlatness:InvalidNumRUIndices1',numel(channelEst));
                else
                    % RU indices must be a scalar cell for non-OFDMA waveforms
                    coder.internal.errorIf(~isscalar(ruIndices),...
                        "wlan:wlanSpectralFlatness:InvalidNumRUIndices2");
                end

                % RU indices and RU sizes must be of same length
                coder.internal.errorIf(~isequal(numel(ruIndices),numel(ruSizes)),...
                    "wlan:wlanSpectralFlatness:InvalidNumRUSizes1",numel(ruIndices));

                fullBWNumSCVec = [242 484 996 1992 3984]; % for 20, 40, 80, 160, 320 MHz bandwidths
                idx = log2(channelBW/20)+1;
                fullBWNumSC = fullBWNumSCVec(idx);

                if nargin==6
                    validateattributes(varargin{3},{'logical'},{'scalar'},mfilename,'Preamble Puncturing');

                    % Preamble-puncturing must be true only for BW >= 80 MHz
                    coder.internal.errorIf(varargin{3} && channelBW<80,...
                        "wlan:wlanSpectralFlatness:PreamblePuncNotSupported");

                    if channelBW>=80
                        if ~iscell(channelEst) && size(channelEst,1)==fullBWNumSC % non-OFDMA full-bandwidth
                            isPreamblePunc = false;
                        else % non-OFDMA preamble-punctured and all configurations of OFDMA
                            isPreamblePunc = varargin{3};
                        end
                    end
                end
            end
        else
            coder.internal.error('wlan:wlanSpectralFlatness:InvalidRUIndicesType',format,'cell');
        end
    elseif strcmp(format,'HE')
        if isnumeric(varargin{1})
            % Validate input arguments
            validateattributes(varargin{1},{'single','double'},{'vector','positive','integer','nonempty'},mfilename,'RU indices');
            validateattributes(channelEst,{'cell'},{'vector'},mfilename,'Channel Estimates');
            for ii = 1:numel(channelEst)
                validateChannelEstValues(channelEst{ii});
            end
            ruIndices = varargin{1};
            numCells = numel(channelEst);
            coder.internal.errorIf(~(isequal(numCells, numel(ruIndices))), ...
                'wlan:wlanSpectralFlatness:InvalidNumRUIndices1',numCells);
        else
            coder.internal.error('wlan:wlanSpectralFlatness:InvalidRUIndicesType',format,'numeric');
        end
    else
        if islogical(varargin{1})
            % Validate input arguments
            validateChannelEstValues(channelEst);
            validateattributes(varargin{1},{'logical'},{'scalar'},mfilename,'Preamble Puncturing');
            if strcmp(format,'Non-HT')
                isPreamblePunc = varargin{1};
                coder.internal.errorIf(isPreamblePunc && channelBW<80,...
                    "wlan:wlanSpectralFlatness:PreamblePuncNotSupported");
            end
        else
            coder.internal.error('wlan:wlanSpectralFlatness:InvalidPreamblePuncType');
        end
    end
else
    % Validate channel estimates
    validateChannelEstValues(channelEst);
end

% Check the number of output arguments
nargoutchk(0,3);

% Get the required parameters for spectral flatness test
[tempActiveSubCarriers,tempTestSCIndices,fftLength] = wlan.internal.spectralFlatnessTestParams(format,cbw);

% Specify the maximum and minimum deviation across each test subcarrier.
devVal = cell(1,2);
if(isPreamblePunc)
    devVal{1} = [-6 4];
    devVal{2} = [-6 4];
else
    devVal{1} = [-4 4];
    devVal{2} = [-6 4];
end

% Initiate fullBW flag
fullBW = true;
testSCIndices = cell(1,2);

% 80 MHz EHT MU PPDU transmitted as EHT DUP mode are constructed in an
% identical manner to those of an 80 MHz OFDMA transmission with 484-tone
% RU1 and RU2 occupied. Refer Section 36.3.5
isEHTDUP80 = (strcmp(format,'EHT') && strcmp(cbw,'CBW80') && (size(channelEst,1)==968));

% Combine channel estimates when the number of input arguments are > 3 for
% HE and EHT formats
if nargin > 3 && ~islogical(varargin{1}) % not Non-HT
    if ~iscell(varargin{1}) % HE OFDMA
        [mapChannelEst,scIndToTest] = processChannelEstimates(channelEst,format,channelBW,ruIndices);
    else % EHT OFDMA or EHT non-OFDMA
        [mapChannelEst,scIndToTest] = processChannelEstimates(channelEst,format,channelBW,ruIndices,ruSizes);
    end
    fullBW = false;
    channelEstMat = mapChannelEst;
    testSCIndices{1} = intersect(scIndToTest,tempTestSCIndices{1}); % Averaging subcarrier indices
    testSCIndices{2} = intersect(scIndToTest,tempTestSCIndices{2});
    activeSubCarriers = scIndToTest;
else
    channelEstMat = channelEst;
    if isEHTDUP80
        activeSubCarriers = [-500:-259 -253:-12 12:253 259:500];
        testSCIndices{1} = intersect(activeSubCarriers,tempTestSCIndices{1}); % Averaging subcarrier indices
        testSCIndices{2} = intersect(activeSubCarriers,tempTestSCIndices{2});
    else % Full bandwidth
        testSCIndices{1} = tempTestSCIndices{1};
        testSCIndices{2} = tempTestSCIndices{2};
        activeSubCarriers = tempActiveSubCarriers;
    end
end

% Provide pass value as false when averaging subcarrier indices are not
% provided as input to wlanSpectralFlatness
if isempty(testSCIndices{1})
    % Do not compute the test results when averaging subcarrier indices are
    % empty and return
    pass = false;
    deviation = {};
    testSC = testSCIndices;
    return
end

% Validate number of subcarriers
[numSC,numSTS,numRxAnts] = size(channelEstMat);
if fullBW && ~isEHTDUP80
    coder.internal.errorIf(numSC~=numel(activeSubCarriers), ...
        'wlan:wlanSpectralFlatness:InvalidNumSC',numel(activeSubCarriers));
end

% Spectral flatness test assumes wired link between each transmit and
% receive antenna, therefore only use the appropriate channel estimates (an
% identity matrix for each subcarrier).
if numRxAnts<numSTS
    numSTS = numRxAnts;
end
channelEstMat = channelEstMat(:,1:numSTS,1:numSTS);
t = reshape(repelem(eye(numSTS),numSC,1),numSC,numSTS,[]);
estUse = reshape(channelEstMat(t==1),numSC,[]);

% Store channel estimates in subcarrier locations with nulls
estFullFFT = complex(zeros(fftLength,numSTS));
estFullFFT(activeSubCarriers+fftLength/2+1,:) = estUse;

avgSubCarIndices = testSCIndices{1}; % Average subcarrier indices
% Calculate average magnitude of channel estimate
avgChanEst = 20*log10(mean(abs(estFullFFT(avgSubCarIndices+fftLength/2+1,:))));

% For each set of subcarrier indices calculate the deviation from the
% average magnitude
chanEstDeviation = cell(1,2);
for i = 1:numel(testSCIndices)
    avgPow = 20*log10(abs(estFullFFT(testSCIndices{i}+fftLength/2+1,:)));
    chanEstDeviation{i} = minus(avgPow,avgChanEst);
end

% Compare the deviations with standard-specified range
lowDevFlag1 = any(chanEstDeviation{1}(:)<(devVal{1}(1)));
lowDevFlag2 = any(chanEstDeviation{1}(:)>(devVal{1}(2)));
uppDevFlag1 = any(chanEstDeviation{2}(:)<(devVal{2}(1)));
uppDevFlag2 = any(chanEstDeviation{2}(:)>(devVal{2}(2)));
pass = ~(((lowDevFlag1)||(lowDevFlag2))||((uppDevFlag1)||(uppDevFlag2)));

% Output deviation and test subcarriers
deviation = chanEstDeviation;
testSC = testSCIndices;
end

function [mapChannelEst,scIndToTest] = processChannelEstimates(channelEst,format,channelBW,varargin)
%processChannelEstimates Parameters for estimating spectral flatness for
% non-full bandwidth HE and EHT waveforms.
%
%  [MAPCHANNELEST,SCINDTOTEST] = processChannelEstimates(CHANNELEST,CBW)
%  outputs the parameters required for estimating the spectral flatness for
%  a given channel bandwidth, CBW, using the channel estimates CHANNELEST.
%
%  MAPCHANNELEST specifies the channel estimates mapped to the
%  available subcarrier indices for the given channel bandwidth.
%  SCINDTOTEST specifies the subcarrier indices to be tested for spectral
%  flatness.

if nargin > 4
    % For EHT, split channel estimates and RU indices of MRUs into RUs
    ruIndicesCell = varargin{1};
    ruSizes = varargin{2};
    ruSizesArray = cell2mat(reshape(ruSizes,1,[]));
    numRUSizes = numel(ruSizesArray);
    channelEstCell = coder.nullcopy(cell(numRUSizes,1));
    ruIndices = coder.nullcopy(zeros(numRUSizes,1));
    ruCount = 0;
    for ii = 1:numel(ruSizes)
        count = 0;
        currRUSizes = ruSizes{ii};
        currRUIndices = ruIndicesCell{ii};

        % Number of RU Indices in a cell must be same as number of RU Sizes
        % in corresponding cell
        coder.internal.errorIf(numel(currRUIndices)~=numel(currRUSizes),'wlan:wlanSpectralFlatness:InvalidNumRUSizes2',ii,numel(currRUIndices));

        for jj = 1:numel(currRUSizes)
            if iscell(channelEst) % OFDMA
                currChanEst = channelEst{ii};
            else % preamble-punctured
                currChanEst = channelEst;
            end
            ruCount = ruCount+1;
            ruIndices(ruCount) = currRUIndices(jj);

            % Sum of RU Sizes in a cell must be equal to the length of
            % channelEst
            coder.internal.errorIf(sum(currRUSizes)~=size(currChanEst,1),'wlan:wlanSpectralFlatness:IncorrectRUSize1',ii,size(currChanEst,1));
            channelEstCell{ruCount} = currChanEst(count+(1:currRUSizes(jj)),:,:);
            count = count+currRUSizes(jj);
        end
    end
else
    ruIndices = varargin{1};
    channelEstCell = channelEst;
end

numRUs = numel(channelEstCell);
numChanEst = coder.nullcopy(zeros(numRUs,1));
numSTSPerRU = coder.nullcopy(zeros(numRUs,1));
numRxAntsPerRU = coder.nullcopy(zeros(numRUs,1));
for i = 1:numRUs
    [numChanEst(i),numSTSPerRU(i),numRxAntsPerRU(i)]  = size(channelEstCell{i});
end

% Define valid RU sizes for non-full bandwidth (OFDMA or
% preamble-punctured) waveforms for corresponding channel bandwidths
switch channelBW % in MHz
    case 20
        validRUSize = [26 52 106];
        validRUSizeStr = sprintf("%d ",[26 52 106]);
    case 40
        validRUSize = [26 52 106 242];
        validRUSizeStr = sprintf("%d ",[26 52 106 242]);
    case 80
        validRUSize = [26 52 106 242 484];
        validRUSizeStr = sprintf("%d ",[26 52 106 242 484]);
    case 160
        validRUSize = [26 52 106 242 484 996];
        validRUSizeStr = sprintf("%d ",[26 52 106 242 484 996]);
    otherwise % 320
        validRUSize = [26 52 106 242 484 996 1992];
        validRUSizeStr = sprintf("%d ",[26 52 106 242 484 996 1992]);
end

% Error check for valid ruSize (size of each cell of channelEstCell) based
% on BW
if iscell(channelEst)
    coder.internal.errorIf(~all(ismember(numChanEst,validRUSize)),...
        'wlan:wlanSpectralFlatness:IncorrectRUSize2',channelBW,validRUSizeStr);
end

% Check for this condition when the Spatial Mapping is not Direct and
% consider the minimum of either SpaceTimeStreams or receive antennas
minSTS = min(numSTSPerRU);
minRxAnts = min(numRxAntsPerRU);
numSTS = min(minSTS, minRxAnts);
numRxAnts = numSTS;

totalNumChanEst = sum(numChanEst);
scIndToTest = coder.nullcopy(zeros(totalNumChanEst,1));
mapChannelEst = coder.nullcopy(zeros(totalNumChanEst,numSTS,numRxAnts,'like',channelEstCell{1}));
prevEndIdx = 0;
for j = 1:numRUs
    ruSize = numChanEst(j);
    ruIndex = ruIndices(j);
    subcarrierIndices = validateRUIndex(channelBW, ruSize, ruIndex, format);
    if j ~= 1
        startIdx = prevEndIdx + 1;
        endIdx = startIdx + ruSize - 1;
        prevEndIdx = endIdx;
    else
        startIdx = 1;
        endIdx = ruSize;
        prevEndIdx = endIdx;
    end
    scIndToTest(startIdx:endIdx) = subcarrierIndices;
    channelEstUse = channelEstCell{j};
    mapChannelEst(startIdx:endIdx,:,:) = channelEstUse(:,1:numSTS,1:numRxAnts);
end
uniqueSize = size(unique(scIndToTest));
actualSize = size(scIndToTest);
coder.internal.errorIf(~(isequal(uniqueSize, actualSize)),...
    'wlan:wlanSpectralFlatness:RepeatedRUIndex');
end


function subcarrierIndices = validateRUIndex(chanBW,ruSize,ruIndex,format)
%validateRUIndex Validate RU index
if strcmp(format,'HE')
    ind = wlan.internal.heRUSubcarrierIndices(chanBW,ruSize);
else
    ind = wlan.internal.ehtRUSubcarrierIndices(chanBW,ruSize);
end
validRUIndices = 1:size(ind,2);
isRUIndexValid = ismember(ruIndex,validRUIndices);
coder.internal.errorIf(~isRUIndexValid,...
    'wlan:wlanSpectralFlatness:InvalidRUIndex',validRUIndices(end));
subcarrierIndices = ind(:,ruIndex);
end

function validateChannelEstValues(channelEst)
validateattributes(channelEst,{'single','double'},{'3d','finite','nonempty'},mfilename,'Channel Estimates');
end