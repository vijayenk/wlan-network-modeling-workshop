function chanEstInterp = heInterpolateChannelEstimate(chanEst,nfft,N_LTF_Mode,kAct,varargin)
%heInterpolateChannelEstimate Interpolate HE/EHT channel estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CHANESTINTERP = heInterpolateChannelEstimate(chanEst,nfft,N_EHT_LTF_Mode,kAct)
%   interpolates over pilot locations and compressed subcarriers for HE-LTF
%   or EHT-LTF channel estimation.
%
%   CHANEST is the MIMO channel estimation and the size is Nst-by-Nsts-Nrx,
%   where Nst is the number of subcarriers, Nsts is the number of
%   space-time streams and Nrx is the number of received antennas.
%
%   NFFT is the FFT length.
%
%   N_LTF_mode represents the HE-LTF or EHT-LTF compression mode and it can
%   be 1, 2, or 4.
%
%   KACT represents the subcarrier indices within the length of FFT.
%
%   CHANESTINTERP is the interpolated channel estimation of size
%   Nact-by-Nsts-Nrx, where Nact represents the number of subcarriers
%   within the length of FFT.
%
%   CHANESTINTERP = heInterpolateChannelEstimate(chanEst,nfft,N_EHT_LTF_Mode,kAct,ruInd)
%   interpolates over pilot locations and compressed subcarriers for HE-LTF
%   or EHT-LTF channel estimations of RU indices of data subarriers.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

narginchk(4,5)

if nargin>4
    % Only the RU indices of data subarriers
    ruInd = varargin{1};
    kChanEstInputs = kAct(ruInd);
else
    % Assume chanEst is for the whole RU
    kChanEstInputs = kAct;
end

% Get the actual sample indices for channel estimates, depending on the
% LTF compression mode
kAll = 1:N_LTF_Mode:nfft;

% Find the subcarrier indices within the FFT contains the actual data
% within the channel estimate input (kToInterp) and the indices of
% these within the est input array (toInterpInd)
[kToInterp,toInterpInd] = intersect(kChanEstInputs,kAll);

% Interpolate between samples within the compression region and
% extrapolate other parts within the FFT
magPart = abs(chanEst(toInterpInd,:,:));
phasePart = unwrap(angle(chanEst(toInterpInd,:,:)));
combInterp = interp1(kToInterp.',cat(4,magPart,phasePart),kAct,'linear','extrap');

% Convert interpolated magnitude and phase to complex
magPartInterp = combInterp(:,:,:,1);
phasePartInterp = combInterp(:,:,:,2);
[~,Nsts,Nr] = size(chanEst);
chanEstInterp = coder.nullcopy(zeros(numel(kAct),Nsts,Nr,'like',chanEst)); % Pre-allocate to make sure the codegen works for the 2-D chanEst
chanEstInterp(:,:,:) = magPartInterp.*exp(1i*phasePartInterp);
end

