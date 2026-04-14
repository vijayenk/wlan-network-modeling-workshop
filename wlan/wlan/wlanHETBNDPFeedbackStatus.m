function feedbackStatus = wlanHETBNDPFeedbackStatus(rxSym,cfg)
%wlanHETBNDPFeedbackStatus Recover feedback status from an HE TB feedback NDP
%   FEEDBACKSTATUS = wlanHETBNDPStatusRecover(RXSYM,CFG) recovers the
%   feedback status from the demodulated HE-LTF field of an HE TB feedback
%   NDP transmission as defined in IEEE Std 802.11ax-2021, Table 27-32.
%
%   FEEDBACKSTATUS indicates the value of the bit used to modulate the
%   tones in each tone set for a given RUToneSetIndex as defined in IEEE
%   Std 802.11ax-2021, Table 27-32. FEEDBACKSTATUS is a scalar double and
%   is estimated using the algorithm defined in IEEE 802.11-17/0044r4. The
%   recovered FEEDBACKSTATUS is set to:
%
%   # 1 if the transmission is detected on the first tone set
%   # 0 if the transmission is detected on the second tone set
%   # -1 if the transmission is not detected on either of the tone sets
%
%   RXSYM is a complex Nst-by-Nsym-by-Nr array containing demodulated
%   HE-LTF symbols. Where Nst is the number of subcarriers and is either:
%   # 242, 484, 996 and 1992 for 20, 40, 80 and 160 MHz channel bandwidth
%   or.
%   # 12 for all channel bandwidths which includes active (6) and
%   complementary (6) subcarriers.
%   Nsym is the number of demodulated HE-LTF symbols and must be 2. Nr is
%   the number of receive antennas.
%
%   CFG is a format configuration object of type wlanHETBConfig.

%   Copyright 2020-2024 The MathWorks, Inc.

%#codegen

% Validate input
narginchk(2,2);
validateattributes(rxSym,{'double'},{'3d','finite'},mfilename,'HE-LTF demodulated symbol(s)');
[Nst,Nsym,Nrx] = size(rxSym);
if Nst==0
    feedbackStatus = []; % Return empty for 0 samples
    return;
end

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
coder.internal.errorIf(~xor(any((Nst==[242 484 996 1992])&(cbw==[20 40 80 160])),Nst==12) || Nsym~=2 || Nrx==0,'wlan:wlanHETBNDPFeedbackStatus:InvalidInputSize');

% Validate the format configuration object and packet type
validateattributes(cfg,{'wlanHETBConfig'},{'scalar'},mfilename,'format configuration object');
coder.internal.errorIf(~cfg.FeedbackNDP,'wlan:wlanHETBNDPFeedbackStatus:InvalidPacketType');

if Nst==12
    % Extract OFDM information for active and complementary tone set
    ofdmInfo = wlanHEOFDMInfo('HE-LTF',cfg);
else
    % Extract OFDM information for the full band
    ofdmInfo = wlanHEOFDMInfo('HE-LTF',cfg.ChannelBandwidth,3.2);
end

% Remove the orthogonal sequence across subcarriers
rxHELTF = coder.nullcopy(complex(zeros(Nst,Nrx)));
Nfft = ofdmInfo.FFTLength;
P = wlan.internal.mappingMatrix(Nsym);
Puse = P(cfg.StartingSpaceTimeStream,1:Nsym).'; % Extract and conjugate the P matrix
for k=1:Nrx
    rx = squeeze(rxSym(:,(1:Nsym),k)); % Symbols on 1 receive antenna
    rxHELTF(:,k) = (rx*Puse)./Nsym;
end
ofdmGrid = complex(zeros(Nfft,Nrx));
ofdmGrid(ofdmInfo.ActiveFFTIndices,:) = rxHELTF;
subcarrierPower = coder.nullcopy(zeros(1,2));
% Estimate power in active and complementary subcarriers
for c=1:2
    kRU = wlan.internal.heTBNDPSubcarrierIndices(cbw,cfg.RUToneSetIndex,c==1);
    subcarrierIndex = kRU+Nfft/2+1;
    subcarrierPower(c) = real(mean(mean(ofdmGrid(subcarrierIndex,:).*conj(ofdmGrid(subcarrierIndex,:))),2));
end

% Estimate FeedbackStatus as defined in IEEE 802.11-17/0044r4
K = 3; % Detector scaling factor
if subcarrierPower(1)>K*subcarrierPower(2) % ( P1 > K∙P0 )
    feedbackStatus = 1;
elseif subcarrierPower(2)>K*subcarrierPower(1) % ( P0 > K∙P1 )
    feedbackStatus = 0;
else % not( P1 > K∙P0 ) & not( P0 > K∙P1 )
    feedbackStatus = -1; % Undefined state
end
end
