function s = defaultChannelStructure()
%defaultChannelStructure returns a default channel structure.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   S = defaultChannelStructure() returns a structure with the fields
%
%   PathGains   - Complex path gains at each snapshot in time.
%                 Ncs-by-Np-by-Nt-by-Nr.
%   PathDelays	- Delay in seconds corresponding to each path. 1-by-Np.
%   SampleTimes - Simulation time in seconds corresponding to each path
%                 gains snapshot. Ncs-by-1.
%   PathFilters - Filter coefficients for each path. Nf-by-Np
%
%   Ncs - number of channel snapshots, Np - number of paths, Nt - number of
%   transmit antennas, Nr - number of receive antennas, Nf - number of
%   coefficients.

%   Copyright 2022-2025 The MathWorks, Inc.

    s = struct('PathGains',[],'PathDelays',[],'SampleTimes',[],'PathFilters',[]);
end
