function est = wlanLLTFChannelEstimate(rxSym,cfgFormat,varargin)
% wlanLLTFChannelEstimate Channel estimation using the L-LTF
%   EST = wlanLLTFChannelEstimate(RXSYM,CFGFORMAT) returns the estimated
%   channel between the transmitter and all receive antennas using the
%   non-HT Long Training Field (L-LTF).
%
%   EST is a complex Nst-by-1-by-Nr array containing the estimated channel
%   at data and pilot subcarriers, where Nst is the number of occupied
%   subcarriers and Nr is the number of receive antennas. The singleton
%   dimension corresponds to the single transmitted stream in the L-LTF
%   which includes the combined cyclic shifts if multiple transmit antennas
%   are used.
%
%   RXSYM is a single or double complex Nst-by-Nsym-by-Nr array containing
%   demodulated L-LTF OFDM symbols. Nsym is the number of demodulated L-LTF
%   symbols and can be one or two. If two L-LTF symbols are provided the
%   channel estimate is averaged over the two symbols.
%
%   CFGFORMAT is a format configuration object of type wlanVHTConfig, 
%   wlanHTConfig, wlanNonHTConfig, wlanHESUConfig, wlanHEMUConfig, 
%   wlanHETBConfig, wlanHERecoveryConfig, wlanEHTMUConfig, wlanEHTTBConfig, 
%   or wlanEHTRecoveryConfig.
%
%   EST = wlanLLTFChannelEstimate(RXSYM,CHANBW) returns the estimated
%   channel for the provided channel bandwidth CHANBW. CHANBW is a
%   character vector or string describing the channel bandwidth and must be
%   'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.
%
%   EST = wlanLLTFChannelEstimate(...,SPAN) performs frequency smoothing by
%   using a moving average filter across adjacent subcarriers to reduce the
%   noise on the channel estimate. The span of the filter in subcarriers,
%   SPAN, must be odd. If adjacent subcarriers are highly correlated
%   frequency smoothing will result in significant noise reduction, however
%   in a highly frequency selective channel smoothing may degrade the
%   quality of the channel estimate. Frequency smoothing is only
%   recommended when estimating the L-LTF when a single transmit antenna is
%   used.
 
%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Validate number of arguments
narginchk(2,3);

% Validate the packet format configuration object is a valid type
validateattributes(cfgFormat,{'wlanVHTConfig','wlanHTConfig','wlanNonHTConfig','wlanHESUConfig','wlanHEMUConfig','wlanHETBConfig','wlanHERecoveryConfig',...
    'wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig','char','string'},{}, mfilename,'second argument');

if ischar(cfgFormat) || isstring(cfgFormat)
    % wlanLLTFChannelEstimate(RXSYM,CHANBW,...) syntax
    cbw = wlan.internal.validateParam('NONHTEHTCHANBW',cfgFormat,mfilename);
else
    % wlanLLTFChannelEstimate(RXSYM,CFGFORMAT,...) syntax
    % Only applicable for OFDM and DUP-OFDM modulations
    coder.internal.errorIf(isa(cfgFormat,'wlanNonHTConfig') && ~strcmp(cfgFormat.Modulation,'OFDM'),'wlan:wlanChannelEstimate:InvalidDSSS');

    % Channel bandwidth parameterized using object
    wlan.internal.mustBeDefined(cfgFormat.ChannelBandwidth,'ChannelBandwidth');
    cbw = cfgFormat.ChannelBandwidth;
end

% Validate symbol type
validateattributes(rxSym,{'single','double'},{'3d'},'wlanLLTFChannelEstimate','L-LTF OFDM symbol(s)');
[numSC,~,numRxAnts] = size(rxSym);

% Return an empty if empty symbols
if isempty(rxSym)
    est = zeros(numSC,1,numRxAnts,class(rxSym));
    return;
end

if nargin > 2
    span = varargin{1};
    enableFreqSmoothing = true;
else
    % Default no frequency smoothing
    enableFreqSmoothing = false;
end

% Perform LS channel estimation and time averaging as per Perahia, Eldad,
% and Robert Stacey. Next Generation Wireless LANs: 802.11 n and 802.11 ac.
% Cambridge university press, 2013, page 83, Eq 2.70.
if any(strcmp(cbw,{'CBW5','CBW10','CBW20'}))
    num20 = 1;
else
    num20 = wlan.internal.cbwStr2Num(cbw)/20;
end
lltf = lltfReference(num20); % Get reference subcarriers
% Verify number of subcarriers to estimate
coder.internal.errorIf(numSC~=numel(lltf),'wlan:wlanChannelEstimate:IncorrectNumSC',numel(lltf),numSC);
ls = rxSym./repmat(lltf,1,size(rxSym,2),numRxAnts); % Least-square estimate   
est = mean(ls,2); % Average over the symbols

% Perform frequency smoothing
if enableFreqSmoothing
    % Smooth each 20 MHz segment individually
    groupSize = size(est,1)/num20;
    for i = 1:num20
        idx = (1:groupSize)+(i-1)*groupSize;
        est(idx,:,:) = wlan.internal.frequencySmoothing(est(idx,:,:),span);
    end
end

end

function ref = lltfReference(num20MHz)
    % 20 MHz reference
    [lltfLower, lltfUpper] = wlan.internal.lltfSequence();

    % Replicate over number of 20 MHz segments ignoring the DC and reshape
    ref = reshape([lltfLower; lltfUpper]*ones(1,num20MHz),[],1);
end

