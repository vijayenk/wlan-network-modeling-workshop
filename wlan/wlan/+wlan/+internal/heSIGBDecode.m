function bits = heSIGBDecode(rx,csi,nVar,rateTable,mcs,varargin)
% heSIGBDecode Decode and demap HE-SIG-B and EHT-SIG field
%
%   BITS = heSIGBDecode(RX,CSI,NVAR,RATETABLE,MCS) returns the decoded
%   HE-SIG-B or EHT-SIG field for the given CSI, noise variance, HE-SIG-B
%   or EHT-SIG rate table, and EHT-SIG MCS.
%
%   BITS = heSIGBDecode(...,DCM) returns the decoded HE-SIG-B for the given
%   DCM.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

if mcs==15
    % MCS 15 (DCM) is only applicable to EHT.
    DCM = 1;
else
    DCM = 0;
end
if nargin>5 % HE
    DCM = varargin{:};
end
csiFlag = all(csi~=1); % Only apply CSI if its not the default

% Undo extra tone rotation if present. The extra tone rotation is
% applicable to all EHT-SIG MCS except MCS 15, see Eq 36-24/D5.0. For HE,
% the extra tone rotation is applicable to all HE-SIG-B MCS except MCS 0,
% with DCM. See Eq 27-21 of IEEE Std 802.11ax-2021.
if ~(any(mcs == [0 15]) && DCM)
    % Negate every second data symbol in the second half of each 20 MHz channel
    rx(end/2+1+1:2:end,:,:) = rx(end/2+1+1:2:end,:,:)*-1;
end

% Demap symbols
softBits = wlan.internal.heConstellationDemap(rx,nVar,rateTable.NBPSCS,DCM);

if csiFlag
    if DCM
        % If DCM used then we need to demap (combine) the CSI

        % For all DCM modes we combine (average) the upper and lower halves
        % of the CSI.
        % For NBPSCS = 4 Upper half bits are a permuted version of lower
        % half. Given we only have CSI per symbol then just combine the CSI
        % from upper and lower half on each symbol
        csiPerSegementCombined = (csi(1:end/2,:)+csi(end/2+1:end,:))/2;
    else
        csiPerSegementCombined = csi;
    end

    % Apply bit-wise CSI
    softBits = softBits .* reshape(repmat(csiPerSegementCombined.',rateTable.NBPSCS,1),rateTable.NBPSCS*rateTable.NSD,1);
end

% Deinterleave soft bits
deinterleaved = wlan.internal.heBCCDeinterleave(softBits(:),56,rateTable.NBPSCS,rateTable.NCBPS,DCM,rateTable.NCBPS);

% Set traceback depth
% Reference: IEEE Std 802.11-2012, Sections 18.3.5.6, 18.3.5.7, 20.3.11.6
% for polynomials and puncturing patterns.
trellis = poly2trellis(7, [133 171]);

% Validate rate and get BCC decoder parameters
[rateValue, puncPat, defaultTDepth] = wlan.internal.bccEncodeParameters(rateTable.Rate);
% Get default puncPat in vitdec for rate = 1/2
if rateValue == 1/2
    puncPat = ones(log2(trellis.numOutputSymbols), 1);
end

% Set traceback depth to deal with small number of symbols
tDepth = min(defaultTDepth,size(deinterleaved,1)/(sum(puncPat)/length(puncPat))/2);

% Decode content channel
bits = wlanBCCDecode(deinterleaved,rateTable.Rate,tDepth);

end