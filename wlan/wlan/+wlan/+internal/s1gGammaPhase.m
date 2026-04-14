function gamma = s1gGammaPhase(x)
%s1gGammaPhase S1G gamma rotation per subchannel
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   GAMMA = s1gGammaPhase(CHANBW) returns the gamma phase per subchannel.
%   CHANBW is the channel bandwidth and must be 'CBW1', 'CBW2', 'CBW4',
%   'CBW8', or 'CBW16'.
%
%   GAMMA = s1gGammaPhase(NUMSUBCHANNELS) returns the gamma phase per
%   subchannel given the number of subchannels. NUMSUBCHANNELS is 1, 2, 4,
%   or 8.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

% S1G; different gamma for every 32/64 subcarrier group, IEEE
% P802.11ah/D5.0 Section 24.3.7
switch x
    case {'CBW1','CBW2',1}
        gamma = 1;  % Eqn 24-5/24-6
    case {'CBW4',2}
        gamma = [1 1i];  % Eqn 24-7                
    case {'CBW8',4}
        gamma = [1 -1 -1 -1]; % Eqn 24-8
    otherwise % 'CBW16', or 8
        gamma = [1 -1 -1 -1 1 -1 -1 -1]; % Eqn 24-9
end

end