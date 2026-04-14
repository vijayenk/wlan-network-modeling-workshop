function [ofdmCfg,varargout] = s1gOFDMConfig(chanBW,CPType,field,varargin)
%s1gOFDMConfig S1G OFDM configuration
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OFDMCFG = s1gOFDMConfig(CHANBW,CPTYPE,FIELD,NUMSTSTX) returns a
%   structure containing the OFDM configuration.
%
%   CHANBW is a character vector representing the channel bandwidth
%
%   CPTYPE is a character vector representing the CP length used for data
%   field processing and must be 'Long' or 'Short'.
%
%   FIELD is a character vector specifying which field to return the OFDM
%   configuration for. It must be one of: 'STF', 'DSTF', 'LTF', 'LTF1',
%   'DLTF', 'SIG', 'SIG-A', 'SIG-B', 'Data'
%
%   NUMSTSTX is the number of space-time streams or transmit antennas used.
%   The number of transmit antennas should be used if the field is in the
%   omni-portion of the packet, e.g. >2MHz Long preamble STF, LTF1, SIGA.
%   Otherwise the number of space-time streams should be used.
%
%   OFDMCFG = s1gOFDMConfig(... TRAVELINGPILOTS,NSYM) additionally
%   specifies if traveling pilots are used as true or false and the number
%   of symbols required for the pilots. The default TRAVELINGPILOTS if not
%   specified is false and the default NSYM if not specified is 1.
%
%   [OFDMCFG,DATAIND,PILOTIND] additionally returns the indices of data and
%   pilot subcarriers within occupied subcarriers.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

narginchk(3,6);
nargoutchk(0,3);

numSTSTx = 1;
Nsym = 1;
travelingPilots = false;
if nargin>3
    numSTSTx = varargin{1};
    if nargin>4
        travelingPilots = logical(varargin{2}); % true or false
        if nargin>5
            Nsym = varargin{3};
        end
    end
end
[toneRotation,Nsubchan,subchanFFTLen] = wlan.internal.s1gCarrierRotations(chanBW);
FFTLen = subchanFFTLen*Nsubchan;
% Nominal sample rate
sr = 31.25e3*FFTLen;

% Guard interval timing related constants (Table 24-4)
if strcmp(CPType,'Long')
    CPLenField = FFTLen/4;  % Guard interval duration
else % strcmp(CPType,'Short')
    CPLenField = FFTLen/8; % Short guard interval
end

% Calculate indices of data and pilot carrying subcarriers
if any(strcmp(field,{'SIG','SIG-A'}))
% SIG and SIG-A fields are different in terms of construction to others as
% specified for 2 MHz segments then duplicated.
    if strcmp(chanBW,'CBW1')
        KPilot = wlan.internal.s1gKPilotFix('CBW1');
        [Nsd,Nsp,Nsr] = wlan.internal.s1gSubcarriersPerSymbol(field,'CBW1');
    else % CBW2,CBW4,CBW8,CBW16
        KPilot = wlan.internal.s1gKPilotFix('CBW2');
        [Nsd,Nsp,Nsr] = wlan.internal.s1gSubcarriersPerSymbol(field,'CBW2');
    end
    KData = coder.nullcopy(zeros(Nsd,1));
    KData(:) = setdiff((-Nsr:Nsr)',[KPilot; 0],'stable'); % Data excludes pilots and DC (no custom nulls)
    dataIdx = reshape(KData+(0:(Nsubchan-1))*subchanFFTLen, ...
        Nsd*Nsubchan,1)+subchanFFTLen/2+1;
    pilotIdx = reshape(KPilot+(0:(Nsubchan-1))*subchanFFTLen, ...
        Nsp*Nsubchan,1)+subchanFFTLen/2+1;
else %SIG-B, Data
    % Section 24.3.7, exclude subcarriers from carrying data or pilots
    % Get the number of occupied subcarriers
    [Nsd,~,Nsr] = wlan.internal.s1gSubcarriersPerSymbol(field,chanBW);
    switch chanBW
        case {'CBW1','CBW2'}
            customNullIdx = [];
        case {'CBW4','CBW8'}
            customNullIdx = [-1; 1];
        otherwise % 'CBW16'
            customNullIdx = [(-129:-127)'; (-5:-1)'; (1:5)'; (127:129)'];
    end
    % Calculate data and pilot indices
    if strcmp(field,'Data') && travelingPilots==true
        KPilot = wlan.internal.s1gKPilotTravel(chanBW,numSTSTx,Nsym);
        KData = coder.nullcopy(zeros(Nsd,Nsym));
        for isym = 1:Nsym
            % Data excludes pilots, custom nulls and DC
            KData(:,isym) = setdiff((-Nsr:Nsr)',[KPilot(:,isym); customNullIdx; 0],'stable');
        end
    else % Fixed pilots
        KPilot = wlan.internal.s1gKPilotFix(chanBW);
        % Data excludes pilots, custom nulls and DC
        KData = coder.nullcopy(zeros(Nsd,1));
        KData(:) = setdiff((-Nsr:Nsr)',[KPilot; customNullIdx; 0],'stable');
    end
    dataIdx = KData+FFTLen/2+1;
    pilotIdx = KPilot+FFTLen/2+1;
end

% The tone scaling factor in Table 24-7 is created for all fields except
% the STF with the following
Ntone = size(dataIdx,1)+size(pilotIdx,1);

% numSTS or numTX depending on field. NumTX for long preamble, fields STF,
% LTF1 or SIGA
normFactor = FFTLen/sqrt(Ntone*numSTSTx); 

ofdmCfg = struct( ...
    'FFTLength',           FFTLen, ...
    'SampleRate',          sr, ...
    'CyclicPrefixLength',  CPLenField, ...
    'DataIndices',         dataIdx, ...
    'PilotIndices',        pilotIdx, ...
    'CarrierRotations',    toneRotation, ...
    'NormalizationFactor', normFactor, ...
    'NumSubchannels',      Nsubchan, ...
    'NumTones',            numel(dataIdx)+numel(pilotIdx));

if nargout>1
    % Transform indices addressing whole FFT length, to indices addressing
    % occupied subcarriers
    allIndices = [dataIdx; pilotIdx];
    Nsd = size(dataIdx,1);
    [~,idxOccupiedSubcarriers] = ismember(allIndices,sort(allIndices));
    dataIndNst = idxOccupiedSubcarriers(1:Nsd,:); % Data indices within occupied subcarriers
    varargout{1} = dataIndNst;
    if nargout>2
        pilotIndNst = idxOccupiedSubcarriers(Nsd+1:end,:); % Pilot indices within occupied subcarriers
        varargout{2} = pilotIndNst;
    end
end
end