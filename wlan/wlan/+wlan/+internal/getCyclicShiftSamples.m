function csh = getCyclicShiftSamples(cbw,numTx,numCyclicShift,legacyCyclicShift)
%getCyclicShiftSamples Get cyclic shift in number of samples
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CSH is the legacy cyclic shift delay for each transmit antenna chain in
%   number of samples.
%
%   CBW is the channel bandwidth and must be 20, 40, 80 or 160.
%
%   NUMTX is the number of transmit antennas.
%
%   NUMCYCLICSHIFT is the total number of standard defined legacy cyclic
%   shifts for each transmit antenna chain.
%
%   LEGACYCYCLICSHIFT are the pre-HT, pre-VHT or pre-HE cyclic shifts for
%   each transmit antenna chain in nsec.
%
%   See also getCyclicShiftVal.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

if numTx<=numCyclicShift
    csh = wlan.internal.getCyclicShiftVal('OFDM',numTx,cbw);
else
    % Get the standard defined cyclic shift for all transmit antennas
    stdCyclicShift = wlan.internal.getCyclicShiftVal('OFDM',numCyclicShift,cbw);
    % Get cyclic shift for the remaining antennas (>4 or >8). The cyclic
    % shift values are in nsec (1e-9) and channel bandwidth is in MHz (1e6)
    % therefore multiply by 1e-3 to get cyclic shift in samples.
    userCyclicShift = legacyCyclicShift(1:numTx-numCyclicShift)*cbw*1e-3;
    csh = [stdCyclicShift; userCyclicShift'];
end

end