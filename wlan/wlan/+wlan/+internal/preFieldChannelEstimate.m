function est = preFieldChannelEstimate(demodSym,chEstLLTF,cbw,filename,varargin)
%preFieldChannelEstimate Pre-HE and Pre-EHT channel estimate
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   EST = preFieldChannelEstimate(DEMODSYM,CHESTLLTF,CBW,FILENAME) returns
%   the full channel estiamte in the L-SIG field for Pre-HE or Pre-EHT.
%
%   EST = preFieldChannelEstimate(...,SPAN) also specifies the span of the
%   filter SPAN in order to perform frequency smoothing by using a moving
%   average filter across adjacent subcarriers to reduce noise in the
%   channel estimate.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

% Input validation
    validateattributes(demodSym,{'single','double'},{'3d','finite','nonempty'},filename,'DEMODSYM');
    validateattributes(chEstLLTF,{'single','double'},{'3d','finite'},filename,'CHESTLLTF');
    cbwVal = validatestring(cbw,{'CBW20','CBW40','CBW80','CBW160','CBW320'},filename,'CBW');

    [~,numSubchannels] = wlan.internal.cbw2nfft(cbwVal);
    [numSCLSIG,~,numRx] = size(demodSym);
    [numSCLLTF,numSTSLLTF,numRxLLTF] = size(chEstLLTF);

    % Validate the number of subcarriers in demodSym
    coder.internal.errorIf(numSCLSIG~=56*numSubchannels,'wlan:shared:InvalidDemodSym1D',56*numSubchannels);

    % Validate the number of subcarriers, STSs and receive antennas in
    % chEstLLTF
    coder.internal.errorIf(numSCLLTF~=52*numSubchannels,'wlan:shared:InvalidChEstLLTF1D',52*numSubchannels);
    coder.internal.errorIf(numSTSLLTF~=1,'wlan:shared:InvalidNumSTS','CHESTLLTF',numSTSLLTF,1);
    coder.internal.errorIf(numRx~=numRxLLTF,'wlan:shared:InvalidNumRx',numRx);

    if nargin > 4
        span = varargin{1};
        validateattributes(span,{'numeric'},{'>=',1,'odd','scalar'},filename,'smoothing span');
        est = wlan.internal.preHEChannelEstimate(demodSym,chEstLLTF,numSubchannels,span);
    else
        est = wlan.internal.preHEChannelEstimate(demodSym,chEstLLTF,numSubchannels);
    end
end
