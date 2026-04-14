function information = macGetIEInformation(elementID, mgmtConfig)
%macGetIEInformation Constructs and returns the information field for the
%specified element ID.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   INFORMATION = macGetIEInformation(ELEMENTID, MGMTCONFIG) constructs and
%   returns the information field for the given element ID ELEMENTID using
%   the given management configuration object.
%
%   INFORMATION is the constructed information field of the IE, returned as
%   a character vector representing octets in hexadecimal format.
%
%   ELEMENTID specifies the element ID of the information element to be
%   added to the read-only property InformationElements of the given
%   management configuration object. Only 0 (SSID element ID) and 1
%   (supported rates ID) are accepted.
%
%   MGMTCONFIG Management frame-body configuration object of type 
%   <a href="matlab:help('wlanMACManagementConfig')">wlanMACManagementConfig</a>.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

switch(elementID)
  case 0 % SSID
    % Construct the information field for the SSID IE
    decOctets = uint8(char(mgmtConfig.SSID));
    information = reshape(dec2hex(decOctets, 2)', 1, []);
        
  otherwise % Supported Rates IE
    basicRatesCount = nnz(~strcmp(mgmtConfig.BasicRates, ''));
    additionalRatesCount = nnz(~strcmp(mgmtConfig.AdditionalRates, ''));
    basicRatesList = zeros(basicRatesCount, 1);
    additionalRatesList = zeros(additionalRatesCount, 1);
    
    idx = 1;
    for i = 1:numel(mgmtConfig.BasicRates)
      if ~isempty(mgmtConfig.BasicRates{i})
        % Append rate to basic rates list
        basicRatesList(idx) = getDataRateCode(mgmtConfig.BasicRates{i});
        idx = idx + 1;
      end
    end
    
    idx = 1;
    for i = 1:numel(mgmtConfig.AdditionalRates)
      if ~isempty(mgmtConfig.AdditionalRates{i})
        % Append rate to basic rates list
        additionalRatesList(idx) = getDataRateCode(mgmtConfig.AdditionalRates{i});
        idx = idx + 1;
      end
    end
    
    % Form the list of rates including basic and additional rates
    ratesList = [basicRatesList; additionalRatesList];
    
    % Remove duplicate rates from rates list
    uniqueRates = unique(ratesList);
    coder.internal.errorIf(((numel(uniqueRates) < 1) || (numel(uniqueRates) > 8)), 'wlan:wlanMACFrame:InvalidNumOfSupportedRates');
    
    nRates = numel(uniqueRates);
    for i = 1:nRates
      if (any(uniqueRates(i) == basicRatesList))
        % Set MSB bit for basic rates
        uniqueRates(i) = bitor(uint8(uniqueRates(i)), uint8(128));
      end
    end
    
    % Sort the rates
    uniqueRates = sortrows(uniqueRates);
    
    % Convert rates information to hexadecimal format
    information = reshape(dec2hex(uniqueRates, 2)', 1, []);
end
end

% Return code for the given data rate
function code = getDataRateCode(rate)
  % Refer Table-18.4 in Std IEEE 802.11-2016.
  switch(rate)
    case '1 Mbps'
      code = 2;
    case '2 Mbps'
      code = 4;
    case '5.5 Mbps'
      code = 11;
    case '6 Mbps'
      code = 12;
    case '9 Mbps'
      code = 18;
    case '11 Mbps'
      code = 22;
    case '12 Mbps'
      code = 24;
    case '18 Mbps'
      code = 36;
    case '24 Mbps'
      code = 48;
    case '36 Mbps'
      code = 72;
    case '48 Mbps'
      code = 96;
    otherwise % 54 Mbps
      code = 108;
  end
end