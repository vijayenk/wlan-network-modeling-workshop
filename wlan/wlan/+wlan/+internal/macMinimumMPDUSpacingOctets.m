function numOctets = macMinimumMPDUSpacingOctets(mmss, phyConfig, subframeLength)
%macMinimumMPDUSpacingOctets Required padding before the start of next
%A-MPDU subframe
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   NUMOCTETS = macMinimumMPDUSpacingOctets(MMSS,PHYCONFIG,SUBFRAMELENGTH)
%   returns the number of additional octets required as padding, to
%   maintain minimum start-spacing with the next MPDU in an A-MPDU.
%
%   NUMOCTETS represents the number of additional octets (padding) required
%   before the start of the next A-MPDU subframe.
%
%   MMSS represents the minimum MPDU start spacing, specified as a number
%   in the range of [0 - 7]. It is an enumeration where each number
%   represents a specific time value in microseconds. Refer Table 9-229 in
%   Std IEEE 802.11-2016.
%
%   PHYCONFIG is an object of type <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>, or 
%   <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>.
%
%   SUBFRAMELENGTH is the length of the A-MPDU subframe, specified as the
%   number of octets (includes delimiter length).

%   Copyright 2018-2023 The MathWorks, Inc.

%#codegen

% Minimum spacing time between the start of adjacent MPDUs in an A-MPDU (in
% microseconds). Refer Table-9.163 in Std IEEE 802.11-2016.
timeList = [0, 1/4, 1/2, 1, 2, 4, 8, 16];

rate = getDataRateFromMCS(phyConfig);

time = timeList(mmss + 1);

numOctets = 0;
% Calculate minimum MPDU start spacing between consecutive MPDUs
reqNumOfOctets = ceil(time*(rate/8));
if reqNumOfOctets > subframeLength
  numOctets = reqNumOfOctets - subframeLength;
  % Minimum spacing will be filled with zero delimiters. So, required
  % spacing must be rounded off to a multiple of 4 octets. Refer Section:
  % 10.13.3 in Std IEEE 802.11-2016.
  numOctets = numOctets + abs(mod(numOctets, -4));
end
end

% Return data rate as a double type value
function dataRate = getDataRateFromMCS(phyConfig)
  if isa(phyConfig, 'wlanHESUConfig')
    % (Symbol + Guard-interval) duration
    if phyConfig.GuardInterval == 0.8
      symbolDuration = 13.6;
    elseif phyConfig.GuardInterval == 1.6
      symbolDuration = 14.4;
    else % phyConfig.GuardInterval == 3.2
      symbolDuration = 16;
    end
    
    % Get HE SU coding parameters
    [~, userCodingParams] = wlan.internal.heCodingParameters(phyConfig);
    
    % Calculate data rate using NDBPS and symbol duration
    dataRate = round((userCodingParams.NDBPS/symbolDuration)*10);

  elseif isa(phyConfig, 'wlanEHTMUConfig')
    % (Symbol + Guard-interval) duration
    if phyConfig.GuardInterval == 0.8
      symbolDuration = 13.6;
    elseif phyConfig.GuardInterval == 1.6
      symbolDuration = 14.4;
    else % phyConfig.GuardInterval == 3.2
      symbolDuration = 16;
    end
    
    % Get EHT coding parameters
    [~, userCodingParams] = wlan.internal.ehtCodingParameters(phyConfig);
    
    userIndexSU = 1; % Assume single user
    % Calculate data rate using NDBPS and symbol duration
    dataRate = round((userCodingParams(userIndexSU).NDBPS/symbolDuration)*10);

  elseif isa(phyConfig, 'wlanNonHTConfig')
      dataRate = 0; % wlanNonHTConfig is not expected here. This path is added for codegen.

  else % HT or VHT
    % Symbol duration with long guard interval (4 microseconds)
    longGISymbolDuration = 4;
    
    % Symbol duration with short guard interval (3.6 microseconds)
    shortGISymbolDuration = 3.6;
    
    % Get rate table corresponding to the PHY configuration
    rateTable = wlan.internal.getRateTable(phyConfig);
    
    % Get NDBPS form the rate table returned from the PHY configuration. PHY
    % configuration returns NDBPS as an array representing the NDBPS of each
    % user in case of multi user.
    ndbps = rateTable.NDBPS(1);
    
    if strcmp(phyConfig.GuardInterval, 'Long')
      % Calculate data rate using NDBPS and symbol duration
      dataRate = round((ndbps/longGISymbolDuration)*10);
    else % Short GI
      % Calculate data rate using NDBPS and symbol duration
      dataRate = round((ndbps/shortGISymbolDuration)*10);
    end
  end
  dataRate = dataRate/10;
end
