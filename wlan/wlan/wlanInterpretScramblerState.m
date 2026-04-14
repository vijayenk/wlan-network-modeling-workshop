function [chanBW,dynBW] = wlanInterpretScramblerState(scramInit,centerFreqIndex1,serviceFieldBits)
%wlanInterpretScramblerState Recover bandwidth signaling
%
%   [CHANBW,DYNBW] = wlanInterpretScramblerState(SCRAMINIT) recovers
%   bandwidth signaling from initial scrambler state.
%
%   CHANBW is the recovered signaled channel bandwidth and is one of
%   'CBW20', 'CBW40', 'CBW80', 'CBW160', 'CBW80+80', 'CBW320', or
%   'Unknown'.
%
%   DYNBW is true if the recovered bandwidth operation is dynamic and false
%   if it is static.
%
%   SCRAMINIT is the recovered initial state of the scrambler. It is an
%   integer between 1 and 127 inclusive, or a corresponding 7-by-1 column
%   vector of bits of type int8 or double. The mapping of the
%   initialization bits on scrambler schematic X1 to X7 is specified in
%   IEEE(R) standard 802.11-2016, Section 17.3.5.5. For more information,
%   see wlanScramble documentation.
%
%   [...] = wlanInterpretScramblerState(SCRAMINIT,CENTERFREQINDEX1)
%   specifies CENTERFREQINDEX1, a scalar  between 0 and 200, inclusive.
%   This input corresponds to dot11CurrentChannelCenterFrequencyIndex1,
%   specified in Table 17-9 of IEEE 802.11-2016. The default value is 0.

%   [...] = wlanInterpretScramblerState(...,CENTERFREQINDEX1,SERVICEFIELDBITS)
%   recovers bandwidth signaling for the specified CENTERFREQINDEX1 and
%   SERVICEFIELDBITS.

%   Copyright 2020-2024 The MathWorks, Inc.

%#codegen

arguments
    scramInit {mustBeNonempty}
    centerFreqIndex1 (1,1) {mustBeNumeric,mustBeNonempty,mustBeInRange(centerFreqIndex1,0,200)} = 0;
    serviceFieldBits (16,1) {wlan.internal.validateBits(serviceFieldBits,'serviceFieldBits')} = zeros(16,1,'int8');
end

if all(scramInit==0)
    chanBW = 'Unknown';
    dynBW = false;
else
    % Pass zeros through scrambler with recovered initial state to recover
    % initial scrambler sequence in IEEE 802.11-2016 Section 17.3.5.5.
    scramSeqInit = wlanScramble(zeros(7,1,'int8'),scramInit);

    % IEEE 802.11-2016 Table 17-8
    CbwInNonHtTemp = bit2int(scramSeqInit([6 7]),2,false); % [b5 b6]
    if (CbwInNonHtTemp~=0 && serviceFieldBits(8)) || (CbwInNonHtTemp~=3 && centerFreqIndex1>0)
        % Invalid combination:
        % - If the interpreted channel bandwidth is not 320 MHz and the 8th SERVICE field bit is set to true.
        % - The centerFreqIndex1 is greater then 0 for all interpreted channel bandwidths except 160 MHz.
        % See Table 17-6, 17-9, and 17-10 of IEEE P802.11be/D5.0.
        chanBW = 'Unknown';
    else
        switch CbwInNonHtTemp
            case 0
                if serviceFieldBits(8)==0
                    chanBW = 'CBW20';
                else
                    chanBW = 'CBW320'; % IEEE P802.11be/D5.0, Table 17-9.
                end
            case 1
                chanBW = 'CBW40';
            case 2
                chanBW = 'CBW80';
            otherwise % 3
                if centerFreqIndex1==0 % dot11CurrentChannelCenterFrequencyIndex1
                    chanBW = 'CBW160';
                else
                    chanBW = 'CBW80+80';
                end
        end
    end
    % IEEE 802.11-2016 Table 17-10
    dynBW = scramSeqInit(5)==1; % b4
end
end
