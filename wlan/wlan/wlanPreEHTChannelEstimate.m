function est = wlanPreEHTChannelEstimate(demodSym,chEstLLTF,cbw,varargin)
%wlanPreEHTChannelEstimate Pre-EHT channel estimate
%   EST = wlanPreEHTChannelEstimate(DEMODSYM,CHESTLLTF,CBW) returns the full
%   channel estimate at the L-SIG field.
%
%   EST is a complex Nst-by-1-by-Nr array containing the estimated channel
%   at data and pilot subcarriers, where Nst is the number of occupied
%   subcarriers and Nr is the number of receive antennas. EST includes the
%   channel estimates for the extra four subcarriers per 20 MHz subchannel
%   present in the L-SIG field.
%
%   DEMODSYM is the demodulated L-SIG and RL-SIG field symbols of size
%   Nst-by-Nsym-by-Nr. Nsym is the number of OFDM symbols in L-SIG and
%   RL-SIG fields.
%
%   CHESTLLTF is a complex Nst-by-1-by-Nr array containing the estimated
%   channel at data and pilot subcarriers using the L-LTF field.
%
%   CBW is a string scalar or character vector specifying the channel
%   bandwidth. CBW must be one of 'CBW20', 'CBW40', 'CBW80', 'CBW160',
%   or 'CBW320'.
%
%   EST = wlanPreEHTChannelEstimate(...,SPAN) performs frequency smoothing
%   by using a moving average filter across adjacent subcarriers to reduce
%   the noise on the channel estimate. The span of the filter in
%   subcarriers, SPAN, must be odd. If adjacent subcarriers are highly
%   correlated, frequency smoothing will result in significant noise
%   reduction. However, in a highly frequency-selective channel, smoothing
%   may degrade the quality of the channel estimate.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    narginchk(3,4)

    est = wlan.internal.preFieldChannelEstimate(demodSym,chEstLLTF,cbw,mfilename,varargin{:});

end

