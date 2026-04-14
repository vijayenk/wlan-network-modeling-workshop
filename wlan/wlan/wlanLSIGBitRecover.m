function [bits,failCheck,info] = wlanLSIGBitRecover(rx,noiseVarEst,varargin)
%wlanLSIGBitRecover Recover information bits in L-SIG field
% 
%   [BITS,FAILCHECK,INFO] = wlanLSIGBitRecover(RX,NOISEVAREST) recovers the
%   information bits given the L-SIG field, and the noise variance
%   estimate.
%
%   BITS is an int8 column vector of length 24 containing the recovered
%   information bits in L-SIG field.
% 
%   FAILCHECK is a logical scalar which is true if BITS fails the parity
%   check. 
%
%   INFO is a structure with the following fields:
%       MCS    - Indicate the MCS value as defined in IEEE Std 802.11-2016,
%                Table 17-6.
%       LENGTH - Indicate the number of octets in the PSDU that the MAC is
%                currently requesting the PHY to transmit
%
%   RX is single or double complex demodulated L-SIG symbols of size
%   N-by-1, where N is the number of active sub-carriers in L-SIG field. N
%   is 48 for Non-HT, HT or VHT format and is 52 for HE format.
%
%   NOISEVAREST is the noise variance estimate. It is a real nonnegative
%   scalar.
%   
%   BITS = wlanLSIGBitRecover(...,CSI) uses the channel state information
%   to enhance the demapping of OFDM subcarriers. CSI is a N-by-1 column
%   vector of real values.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

narginchk(2,3);

validateattributes(rx,{'double','single'},{'column','finite'},mfilename,'rx');
numSubcarriers = size(rx,1);

info = struct;
info.MCS = 0;
info.Length = 0;
    
if numSubcarriers==0
    % Return empty for 0 samples
    bits = zeros(0,1,'int8'); 
    failCheck = false(0,1);
    return;
end

% Validate input length
coder.internal.errorIf(~any(numSubcarriers==[48 52]),'wlan:wlanLSIGBitRecover:InvalidRowLength');
validateattributes(noiseVarEst,{'double','single'},{'real','scalar','nonnegative','finite'},'noiseVarEst','noise variance estimate');

% Get CSI input
if nargin>2
    dataCSI = varargin{1};
    coder.internal.errorIf(size(dataCSI,1)~=numSubcarriers,'wlan:wlanLSIGBitRecover:InvalidCSIRowLength');
    validateattributes(dataCSI,{'double','single'},{'real','column','finite'},mfilename,'csi');
else
    dataCSI = ones(numSubcarriers,1); % No CSI
end 

% Extract CSI information for information carrying data subcarriers. The 4
% extra subcarriers in HE, L-SIG field are removed.
if size(rx,1)==52
    rxDataSC = rx(3:end-2,:); % For codegen
    dataCSISC = dataCSI(3:end-2,:);
else
    rxDataSC = rx;
    dataCSISC = dataCSI;
end

numBPSCS = 1;
demapped = wlanConstellationDemap(rxDataSC,noiseVarEst,numBPSCS);

% Apply CSI to each OFDM symbol
demapped = demapped.*dataCSISC;

% Deinterleave
deinterleaved = wlanBCCDeinterleave(demapped(:),'Non-HT',48);

% Decode
bits = wlanBCCDecode(deinterleaved,1/2,24);

% Parity check & rate check (the 4th bit must be 1)
failCheck = (mod(sum(bits(1:17)),2) ~= bits(18)) || (bits(4) ~= 1);

% Interpret L-SIG information bits
[info.MCS,info.Length] = wlan.internal.interpretLSIG(bits);

end

