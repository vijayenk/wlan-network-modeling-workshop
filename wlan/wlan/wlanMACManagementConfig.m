classdef wlanMACManagementConfig < comm.internal.ConfigBase
%wlanMACManagementConfig Create a MAC management frame-body configuration
%object
%   CONFIG = wlanMACManagementConfig creates a WLAN MAC management
%   frame-body configuration object. This object contains the parameters
%   for configuring the fields and information elements in a management
%   frame-body.
%
%   CONFIG = wlanMACManagementConfig(Name, Value) creates a WLAN MAC
%   management frame-body configuration object, CONFIG, with the specified
%   property Name set to the specified Value. You can specify additional
%   name-value pair arguments in any order as (Name1, Value1, ..., NameN,
%   ValueN).
%   
%   wlanMACManagementConfig methods:
%
%   addIE       - Adds the information element (IE) to the configuration
%   displayIEs  - Displays the list of configured information elements
%
%   wlanMACManagementConfig properties:
%
%   FrameType                 - Type of management frame
%   Timestamp                 - TSF (Timing Synchronization Function) timer
%                               value
%   BeaconInterval            - Beacon interval in time units (TUs, 1 TU =
%                               1024us)
%   ESSCapability             - ESS capability
%   IBSSCapability            - IBSS capability
%   Privacy                   - Privacy required for all data frames
%   ShortPreamble             - Support short preamble
%   SpectrumManagement        - Spectrum management required
%   QoSSupport                - Support QoS
%   APSDSupport               - Support Automatic Power Save Delivery (APSD)
%   ShortSlotTimeUsed         - Short slot time is in use
%   RadioMeasurement          - Enable radio measurement
%   DelayedBlockAckSupport    - Support delayed Block-Ack
%   ImmediateBlockAckSupport  - Support immediate Block-Ack
%   SSID                      - Service Set Identifier
%   BasicRates                - Basic rates included in supported rates IE
%   AdditionalRates           - Additional (not Basic) rates included in
%                               supported rates IE
%   InformationElements       - Information elements added using addIE() method

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

properties
    %FrameType Type of management frame
    %   Currently FrameType only supports 'Beacon'.
    FrameType = 'Beacon';
    
    %Timestamp TSF (Timing Synchronization Function) timer value
    %   Specify the beacon timestamp as an integer in the range of 0 to
    %   2^64-1. The default value is 0.
    Timestamp = 0;
    
    %BeaconInterval Beacon interval in time units (TUs, 1 TU = 1024us)
    %   Specify the beacon interval as an integer in the range of [0 -
    %   65535]. The default value is 100.
    BeaconInterval = 100;
    
    %ESSCapability ESS capability
    %   Set to true if the device is capable of forming an ESS. The default
    %   value is true. At any time, only one of ESSCapability or
    %   IBSSCapability must be set to true.
    ESSCapability (1, 1) logical = true;
    
    %IBSSCapability IBSS capability
    %   Set to true if the device is capable of forming an IBSS. The
    %   default value is false. At any time, only one of ESSCapability or
    %   IBSSCapability must be set to true.
    IBSSCapability (1, 1) logical = false;
    
    %Privacy Privacy required for all data frames
    %   Set to true to enable the privacy flag in the Capability
    %   information field. This flag indicates that privacy is required for
    %   all data frames. The default value is false.
    Privacy (1, 1) logical = false;
    
    %ShortPreamble Support short preamble
    %   Set to true to indicate the support for short preamble in the
    %   Capability information field. The default value is false.
    ShortPreamble (1, 1) logical = false;
    
    %SpectrumManagement Spectrum management required
    %   Set to true to enable the spectrum management flag in the
    %   Capability information field. This flag indicates that spectrum
    %   management is required for a device operation. The default value is
    %   false.
    SpectrumManagement (1, 1) logical = false;
    
    %QoSSupport Support QoS
    %   Set to true to indicate the support for QoS capabilities in the
    %   Capability information field. The default value is true.
    QoSSupport (1, 1) logical = true;
    
    %ShortSlotTimeUsed Short slot time is in use
    %   Set to true to enable short slot time flag in the Capability
    %   information field. This flag indicates that the short slot time is
    %   being used. The default value is false.
    ShortSlotTimeUsed (1, 1) logical = false;
    
    %APSDSupport Support Automatic Power Save Delivery (APSD)
    %   Set to true to indicate the support for automatic power save
    %   delivery (APSD) feature in the Capability information field. The
    %   default value is false.
    APSDSupport (1, 1) logical = false;
    
    %RadioMeasurement Enable radio measurement
    %   Set to true to enable the radio measurement flag in the Capability
    %   information field. This flag indicates that the radio measurement
    %   is active. The default value is false.
    RadioMeasurement (1, 1) logical = false;
    
    %DelayedBlockAckSupport Support delayed Block-Ack
    %   Set to true to indicate the support for delayed Block-Ack in the
    %   Capability information field. The default value is false.
    DelayedBlockAckSupport (1, 1) logical = false;
    
    %ImmediateBlockAckSupport Support immediate Block-Ack
    %   Set to true to indicate the support for immediate Block-Ack in
    %   the Capability information field. The default value is false.
    ImmediateBlockAckSupport (1, 1) logical = false;
    
    %SSID Service Set Identifier
    %   Specify SSID as a string scalar or character vector with a maximum
    %   length of 32 characters. The default value is 'default SSID'.
    SSID = 'default SSID';
    
    %BasicRates Basic rates included in supported rates IE
    %   Specify BasicRates as a cell array or string vector containing one
    %   or more of these values: '1 Mbps' | '2 Mbps' | '5.5 Mbps' | '6
    %   Mbps' | '9 Mbps' | '11 Mbps' | '12 Mbps' | '18 Mbps' | '24 Mbps' |
    %   '36 Mbps' | '48 Mbps' | '54 Mbps'. The number of unique rates
    %   specified in 'BasicRates' and 'AdditionalRates' together must be
    %   between 1 and 8, inclusive. The default value is {'6 Mbps', '12
    %   Mbps', '24 Mbps'}.
    BasicRates;
    
    %AdditionalRates Additional (not Basic) rates included in supported rates IE
    %   Specify AdditionalRates as a cell array or string vector containing
    %   one or more of these values: '1 Mbps' | '2 Mbps' | '5.5 Mbps' | '6
    %   Mbps' | '9 Mbps' | '11 Mbps' | '12 Mbps' | '18 Mbps' | '24 Mbps' |
    %   '36 Mbps' | '48 Mbps' | '54 Mbps'. The number of unique rates
    %   specified in 'BasicRates' and 'AdditionalRates' together must be
    %   between 1 and 8, inclusive. The default value is an empty cell
    %   array.
    AdditionalRates = {};
end
  
properties(SetAccess = private, GetAccess = public)
    %InformationElements Information elements added using addIE() method
    %   This property is a cell array where each row represents an
    %   information element. Each information element holds two values -
    %   elementID and information. These information elements (IEs) are
    %   carried in a management frame-body in addition to any IEs included
    %   as configuration properties. This property is read-only and shows
    %   the list of IEs added through the addIE() method. If this list has
    %   an IE that is already included as a configuration property, the
    %   value in this list will be used.
    InformationElements;
end

properties(SetAccess = private, Hidden)
    % Current index in the InformationElements property
    IEIdx = 0;
end
  
properties(Hidden, Constant)
    FrameType_Values = {'Beacon'};
    BasicRates_Values = {'1 Mbps', '2 Mbps', '5.5 Mbps', '6 Mbps', ...
      '9 Mbps', '11 Mbps', '12 Mbps', '18 Mbps', '24 Mbps', '36 Mbps', ...
      '48 Mbps', '54 Mbps'};
    AdditionalRates_Values = {'1 Mbps', '2 Mbps', '5.5 Mbps', '6 Mbps', ...
      '9 Mbps', '11 Mbps', '12 Mbps', '18 Mbps', '24 Mbps', '36 Mbps', ...
      '48 Mbps', '54 Mbps'};
end

methods
  function obj = wlanMACManagementConfig(varargin)
    % For codegen: Non-empty cell arrays are not being recognized as fully
    % defined when initialized in the properties section.
    obj@comm.internal.ConfigBase( ...
      'FrameType', 'Beacon', ...
      'SSID', 'default SSID', ...
      'BasicRates', {'6 Mbps', '12 Mbps', '24 Mbps'},  ...
      varargin{:});
    obj.InformationElements = repmat({zeros(0, 2), zeros(0, 1)}, 511, 1);
  end
  
  function obj = set.FrameType(obj, value)
    value = validatestring(value, obj.FrameType_Values, 'wlanMACManagementConfig', 'FrameType');
    obj.FrameType = '';
    obj.FrameType = value;
  end
  
  function obj = set.Timestamp(obj, value)
    validateattributes(value, {'numeric'}, {'nonnegative', 'scalar', 'integer', '<=', intmax('uint64')}, 'wlanMACManagementConfig', 'Timestamp');        
    obj.Timestamp = value;
  end
  
  function obj = set.BeaconInterval(obj, value)
    validateattributes(value, {'numeric'}, {'scalar', 'integer', 'nonnegative', '<=', 65535}, 'wlanMACManagementConfig', 'BeaconInterval');
    obj.BeaconInterval = double(value);
  end
  
  function obj = set.SSID(obj, value)
    validateattributes(value, {'char', 'string'}, {}, 'wlanMACManagementConfig', 'SSID');
    if ischar(value)
      if ~isempty(value)
        validateattributes(value, {'char'}, {'row'}, 'wlanMACManagementConfig', 'SSID');
      end
    else % string
      validateattributes(value, {'string'}, {'scalar'}, 'wlanMACManagementConfig', 'SSID');
    end
    value = char(value);
    % For codegen
    if isempty(value)
      value = blanks(0);
    end
    coder.internal.errorIf((numel(value) > 32), 'wlan:wlanMACFrame:InvalidSSIDLength');
    obj.SSID = value;
  end
  
  function obj = set.BasicRates(obj, value)
    validateattributes(value, {'cell', 'string', 'char'}, {}, 'wlanMACManagementConfig', 'BasicRates');
    
    if iscell(value) || (isstring(value) && (numel(value) > 1))  
      dataRateList = cell(1, numel(value));
    
      % Cell array or string vector
      value = convertStringsToChars(value);
      coder.internal.errorIf((iscell(value)) && numel(value) && isstring(value{1}), 'wlan:wlanMACFrame:StringInCellNotAccepted');
      for i = 1:numel(dataRateList)
        dataRateList{i} = validatestring(value{i}, obj.BasicRates_Values, 'wlanMACManagementConfig', 'BasicRates');
      end
    else  
      dataRateList = cell(1, 1);
      % Single string value
      dataRateList{1} = validatestring(value, obj.BasicRates_Values, 'wlanMACManagementConfig', 'BasicRates');
    end
    
    obj.BasicRates = dataRateList;
  end
  
  function obj = set.AdditionalRates(obj, value)
    validateattributes(value, {'cell', 'string', 'char'}, {}, 'wlanMACManagementConfig', 'AdditionalRates');
    
    if iscell(value) || (isstring(value) && (numel(value) > 1))
      dataRateList = cell(1, numel(value));
      
      % Cell array or string vector
      value = convertStringsToChars(value);
      coder.internal.errorIf((iscell(value)) && numel(value) && isstring(value{1}), 'wlan:wlanMACFrame:StringInCellNotAccepted');
      for i = 1:numel(dataRateList)
        dataRateList{i} = validatestring(value{i}, obj.AdditionalRates_Values, 'wlanMACManagementConfig', 'AdditionalRates');
      end
    else  
      dataRateList = cell(1, 1);
      % Single string value
      dataRateList{1} = validatestring(value, obj.AdditionalRates_Values, 'wlanMACManagementConfig', 'AdditionalRates');
    end
    
    obj.AdditionalRates = dataRateList;
  end
end

methods
  function obj = addIE(obj, id, information)
    %addIE Updates the object with the given information element (IE).
    %   OBJ = addIE(OBJ, ELEMENTID, INFORMATION) updates and returns the
    %   wlanMACManagementConfig object OBJ after adding the given (ELEMENT
    %   ID, INFORMATION) value pair to the InformationElements property.
    %   Specify the ELEMENTID as either a scalar number in the range of [0
    %   - 254] or a vector in the form of [255, x] where 'x' represents the
    %   element ID extension, specified in the range of [0 - 255]. Specify
    %   the INFORMATION as a string or a character vector representing
    %   octets in hexadecimal format.
    
    % Validate element-ID input
    validateattributes(id, {'numeric'}, {'nonnegative', 'vector'}, 'wlanMACManagementConfig', '');
    coder.internal.errorIf(((numel(id) > 2) || any(id > 255) || ((numel(id) == 2) && (id(1) ~= 255)) || ...
      (isscalar(id) && (id(1) == 255))), 'wlan:wlanMACFrame:InvalidElementID');
    if numel(id) == 2
      elementID = id(1);
      elementIDExtension = id(2);
    else
      elementID = id;
      elementIDExtension = 0;
    end
    
    % Validate information format
    validateattributes(information, {'char', 'string'}, {}, 'wlanMACManagementConfig', 'information');
    if isa(information, 'char')
      validateattributes(information, {'char'}, {'row'}, 'wlanMACManagementConfig', 'information');
    else % string
      validateattributes(information, {'string'}, {'scalar'}, 'wlanMACManagementConfig', 'information');
    end
    
    information = upper(char(information));
    
    % Information length in IE is limited to 255
    coder.internal.errorIf((numel(information)/2 > 255), 'wlan:wlanMACFrame:IEMaxLength');
    
    % Validate hex-digits
    wnet.internal.validateHexOctets(information, 'information');
    
    % Converting hexa-decimal format information to vector of decimal octets
    hexaOctets = reshape(information, 2, [])';
    informationBytes = hex2dec(hexaOctets)';

    obj.IEIdx = obj.IEIdx + 1;
    obj.InformationElements{obj.IEIdx, 1} = [elementID elementIDExtension];
    obj.InformationElements{obj.IEIdx, 2} = informationBytes;
  end
  
  function displayIEs(obj)
    %displayIEs Displays the list of information elements (IEs)
    %   Displays the list of information elements. Each row represents an
    %   IE. Each row consists of element ID, element extension ID (if
    %   present) and information. The element ID and element extension ID
    %   are numbers between 0 and 255. The information is represented in
    %   hexadecimal format with the prefix 0x. For example, information
    %   '0b' is represented as 0x0b.

      coder.extrinsic('wlan.internal.displayMessage');

      ssidElementID = 0;
      supportedRatesElementID = 1;
    
    if (obj.IEIdx == 0)
      ssidInformation = wlan.internal.macGetIEInformation(ssidElementID, obj);
      ratesInformation = wlan.internal.macGetIEInformation(supportedRatesElementID, obj);
      obj = obj.addIE(ssidElementID, ssidInformation);
      obj = obj.addIE(supportedRatesElementID, ratesInformation);
    else
      % Get the ID list from the InformationElements property
      idList = zeros(obj.IEIdx, 2);
      for i = 1 : obj.IEIdx
        id = obj.InformationElements{i, 1};
        % For codegen: When InformationElements is empty, codegen is
        % unable to handle skip this loop. To enable codegen in
        % determining the size, indexing is done explicitly.
        idList(i, :) = [id(1) id(2)];
      end
      
      % Add SSID IE if not present in the InformationElements property
      if ~any(idList(:, 1) == ssidElementID)
        information = wlan.internal.macGetIEInformation(ssidElementID, obj);
        obj = obj.addIE(ssidElementID, information);
      end
      
      % Add Supported Rates IE if not present in the InformationElements
      % property
      if ~any(idList(:, 1) == supportedRatesElementID)
        information = wlan.internal.macGetIEInformation(supportedRatesElementID, obj);
        obj = obj.addIE(supportedRatesElementID, information);
      end
    end
    
    % Get updated element IDs list
    idList = zeros(obj.IEIdx, 3);
    for i = 1:obj.IEIdx
      % Assign a sequence number to each element. After sorting all the
      % IEs based on element IDs and element ID extensions, use this
      % sequence number to retrieve the corresponding information.
      idList(i, :) = [obj.InformationElements{i, 1} i];
    end

    % Sort the Element IDs
    idList = sortrows(idList, [1, 2]);

    % Display
    for i = 1 : obj.IEIdx
      % Get Element ID (1-octet)
      elementID = uint8(idList(i, 1));
      elementIDExtension = uint8(idList(i, 2));
      
      % Check for duplicate IEs
      if elementID == 255
        if ((i + 1) <= obj.IEIdx)
          nextElementID = idList(i+1, 1);
          if ((nextElementID == 255) && (idList(i, 2) == idList(i+1, 2)))
            continue;
          end
        end
      else
        if (((i + 1) <= obj.IEIdx) && (idList(i, 1) == idList(i+1, 1)))
          continue;
        end
      end
      
      % Display the Element ID, Element ID Extension (optional) and
      % Information.
      if elementID == 255
        wlan.internal.displayMessage('wlan:wlanMACFrame:DispIE', elementID, elementIDExtension, reshape(dec2hex(obj.InformationElements{idList(i, 3), 2}, 2)', 1, []));
      else
        wlan.internal.displayMessage('wlan:wlanMACFrame:DispIEWithoutExtension', elementID, reshape(dec2hex(obj.InformationElements{idList(i, 3), 2}, 2)', 1, []));
      end
    end
  end
end
end
