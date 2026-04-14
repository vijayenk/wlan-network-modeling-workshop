function [mpdu, mpduBits] = macGenerateMPDU(payload, macConfig, varargin)
%macGenerateMPDU Generate an MPDU
% 
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   MPDU = macGenerateMPDU(PAYLOAD,MACCONFIG) generates an MPDU
%   corresponding to the given MAC frame configuration MACCONFIG. In case
%   of data frames, PAYLOAD is used as frame payload.
%
%   MPDU is the output frame, returned as a uint8 typed decimal column
%   vector or binary-valued column vector.
%
%   PAYLOAD represents an MSDU or an A-MSDU, specified as a uint8 typed
%   decimal column vector.
%
%   MACCONFIG is the frame configuration object of type <a href="matlab:help('wlanMACFrameConfig')">wlanMACFrameConfig</a>.
%
%   MPDU = macGenerateMPDU(PAYLOAD,MACCONFIG,PHYCONFIG) generates a trigger
%   frame. For all other frames, PHYCONFIG is ignored.
%
%   [..., MPDUBITS] = macGenerateMPDU(...) outputs MPDU bits in addition to
%   the output arguments described above.
%
%   [...] = macGenerateMPDU(...,Name=Value) specifies additional name-value
%   arguments described below. When a name-value pair is not specified, its
%   default value is used.
%
%   'OutputFormat'  - Specify the format of output MPDU. To generate MPDU
%                     as uint8 typed decimal vector, specify this value as
%                     'octets'. To generate MPDU as uint8 typed
%                     binary-valued vector, specify this value as 'bits'.
%                     The default value is 'octets'.

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

narginchk(2, 5);

switch nargin
  case 2 % macGenerateMPDU(payload, macConfig)
    outputFormat = 'octets';
  case 3 % macGenerateMPDU(payload, macConfig, phyConfig)
    outputFormat = 'octets';
  case 4 % macGenerateMPDU(payload, macConfig, 'OutputFormat', format)
    outputFormat = validateNVPairs(varargin);
  case 5 % macGenerateMPDU(payload, macConfig, phyConfig, 'OutputFormat', format)
    outputFormat = validateNVPairs({varargin{2:end}});
end

% Handle MPDU frame generation
switch(macConfig.getType)
  case 'Management'
    mpduBits = generateManagementFrame(macConfig);
  case 'Control'
    if nargin == 3 || nargin == 5
      phyConfig = varargin{1};
    else
      phyConfig = wlanNonHTConfig;
    end
    mpduBits = generateControlFrame(macConfig, phyConfig);
  otherwise % Data
    mpduBits = generateDataFrame(payload, macConfig);
end

if strcmp(outputFormat, 'octets')
  mpdu = uint8(wnet.internal.bits2octets(mpduBits, false));
else
  mpdu = uint8(mpduBits);
end
end

% Prepare and return control frame
function frame = generateControlFrame(cfg, phyConfig)
  % Frame control field (2 octets)
  frameControl = prepareFrameControl(cfg);

  % Duration field (2 octets)
  duration = wnet.internal.int2octets(cfg.Duration, 2, false)';

  % Address-1 (receiver address) (6 octets)
  receiverAddress = hex2DecOctetVector(cfg.Address1, 6, true);

  switch (cfg.getSubtype)
    case {'CTS', 'ACK'}
      % Construct the octets of the frame in decimal format
      frame = [frameControl, duration, receiverAddress];

    case {'Block Ack'}
      % Address-2 (transmitter address) (6 octets)
      transmitterAddress = hex2DecOctetVector(cfg.Address2, 6, true);
      
      % BA Ack-Policy: No Ack is only used by HT delayed Block Ack which
      % became obsolete. Refer Table 9-23 in IEEE Std 802.11-2016.
      ackPolicy = 0;
      
      % BA Type
      blockAckType = [0 1 0 0]; % Only compressed variant is supported
      
      % TID Info
      tidInfo = de2biOptimized(cfg.TID, 4);
      
      % Put the sub-fields together to form BA Control field
      baControl = bi2deOptimized([ackPolicy, blockAckType, zeros(1, 3); zeros(1, 4), tidInfo])';
      
      bitmapSize = numel(cfg.BlockAckBitmap)/2;
      % Fragment Number field is used for indicating the bitmap size. Refer
      % table 9-28a of IEEE Std 802.11ax-2021
      switch bitmapSize
          case 8
              fragmentNumber = 0;
          case 32
              fragmentNumber = 4;
          case 64
              fragmentNumber = 8;
          otherwise % 128
              fragmentNumber = 10;
      end

      % BA Bitmap
      bitmap = hex2DecOctetVector(cfg.BlockAckBitmap, bitmapSize, false);
      
      % BA Starting Sequence Control
      startingSequenceControl = prepareSequenceControl(cfg.SequenceNumber, fragmentNumber);
      
      % Put the sub-fields together to form BA Information field
      baInformation = [startingSequenceControl, bitmap];
      
      % Construct the octets of the frame in decimal format
      frame = [frameControl, duration, receiverAddress, transmitterAddress, baControl, baInformation];

    case 'Trigger'
      % Address-2 (transmitter address) (6 octets)
      transmitterAddress = hex2DecOctetVector(cfg.Address2, 6, true);

      % Common Info (8 or more octets)
      commonInfo = prepareCommonInfo(cfg);

      % Frame with header and common info field
      frame = [frameControl, duration, receiverAddress, transmitterAddress, commonInfo];

      perUserInfo = repmat({uint8([])}, 72, 1);
      % Number of user-info fields
      numUserInfo = cfg.TriggerConfig.NumUserInfo;
      aidValues = zeros(numUserInfo, 1);

      userInfoListStart = 1;
      % Prepare special user-info fields
      if cfg.TriggerConfig.SpecialUserInfoPresent
          specialUserInfo = prepareSpecialUserInfo(cfg.TriggerConfig.UserInfo{1});
          userInfoListStart = 2;
          aidValues(1) = cfg.TriggerConfig.UserInfo{1}.AID12;
          perUserInfo{1} = specialUserInfo;
      end

      % Prepare user-info fields
      for idx = userInfoListStart:numUserInfo
        userInfoCfg = cfg.TriggerConfig.UserInfo{idx};
        aidValues(idx) = userInfoCfg.AID12;
        perUserInfo{idx} = prepareUserInfo(cfg, userInfoCfg);
      end
      aid0Present = (aidValues == 0);
      aid2045Present = (aidValues == 2045);
      aid2046Present = (aidValues == 2046);
      staAIDs = ~(aid0Present | aid2045Present | aid2046Present);

      dimColumn = 2;
      % Append all the user-info fields to the frame in the order mentioned
      % in the section 26.5.2.2.4 of IEEE Std 802.11ax-2021
      for idx = 1:numUserInfo
        % Append the user-info fields with AID values [1 to 2007]
        if staAIDs(idx)
          frame = cat(dimColumn, frame, perUserInfo{idx});
        end
      end
      % Append the user-info fields with AID values 0
      aid0Indices = find(aid0Present);
      for idx = 1:numel(aid0Indices)
        frame = cat(dimColumn, frame, perUserInfo{aid0Indices(idx)});
      end
      % Append the user-info fields with AID values 2045
      aid2045Indices = find(aid2045Present);
      for idx = 1:numel(aid2045Indices)
        frame = cat(dimColumn, frame, perUserInfo{aid2045Indices(idx)});
      end
      % Append the user-info fields with AID values 2046
      aid2046Indices = find(aid2046Present);
      for idx = 1:numel(aid2046Indices)
        frame = cat(dimColumn, frame, perUserInfo{aid2046Indices(idx)});
      end

      % Padding (variable)
      if cfg.NumPadBytesICF == -1
          numPadBits = 0;
          if isa(phyConfig, 'wlanNonHTConfig') % checking PHY config for codegen
              phyConfig.PSDULength = length(frame); % Assuming trigger frame accepts only Non-HT configuration
              mPAD = (cfg.MinTriggerProcessTime/4);
              % Get rate table corresponding to the PHY configuration
              rateTable = wlan.internal.getRateTable(phyConfig);
              NDBPS = rateTable.NDBPS(1);
              % Refer section 26.5.2.2.3 of IEEE Std 802.11ax-2021
              numPadBits = NDBPS*mPAD;
              if any(aid2045Present) && (numPadBits < 4*NDBPS)
                  numPadBits = 4*NDBPS;
              end
          end
          numPadOctets = ceil(numPadBits/8);
      else
          numPadOctets = cfg.NumPadBytesICF;
      end

      if numPadOctets > 0
        % Padding field, if present, is at least 2 octets in length
        numPadOctets = max(2, numPadOctets);

        % In the userInfo, first 12bits indicates AID12. Here AID12 is
        % hardcoded to speacial value 4095, which indicates start of
        % padding field. In this case, only AID12 is present in the user
        % info field, set to 4095. The size of userInfo must be at least 2
        % bytes (16 bits). So the first 12 bits contain the AID12 value,
        % and the remaining 4 bits are all padded with 1's. Therefore, all
        % 16 bits are set to 1. The decimal representation of 16
        % consecutive 1's is [255 255].
        % Refer section 9.3.1.22.1 of IEEE Std 802.11ax-2021
        userInfo = uint8([255 255]);

        frame = cat(dimColumn, frame, userInfo);
        % Actual padding
        numPadOctets = numPadOctets - 2; % Actual padding starts from the user info field with AID12 = 4095, so remove 2 octets
        if numPadOctets > 0
            frame = cat(dimColumn, frame, 255*ones(1, numPadOctets));
        end
      end

    otherwise % RTS
      % Address-2 (transmitter address) (6 octets)
      transmitterAddress = hex2DecOctetVector(cfg.Address2, 6, true);

      % Construct the octets of the frame in decimal format
      frame = [frameControl, duration, receiverAddress, transmitterAddress];  
  end

  % Append FCS to the frame
  frame = appendFCS(frame);
end

% Prepare and return data frame
function frame = generateDataFrame(payload, macConfig)
  % Prepare a basic data frame with all the mandatory fields
  basicMACHeader = prepareBasicMACHeader(macConfig);
  
  address4 = uint8([]);
  % Address4 in the QoS Data or QoS Null frame
  if any(strcmp(macConfig.FrameType, {'QoS Data', 'QoS Null'})) && macConfig.ToDS && macConfig.FromDS
      address4 = hex2DecOctetVector(macConfig.Address4, 6, true);
  end
  
  % Add QoS Control field for QoS frames
  qosControl = uint8([]);
  if any(strcmp(macConfig.FrameType, {'QoS Data', 'QoS Null'}))
    % QoS Control
    qosControl = prepareQoSControl(macConfig);
  end

  % Add HT Control field for HT/VHT QoS frames
  htControl = uint8([]);
  if macConfig.HTControlPresent && any(strcmp(macConfig.FrameType, {'QoS Data', 'QoS Null'}))
    % HTControl (4 octets)
    htControl = hex2DecOctetVector(macConfig.HTControl, 4, false);
  end

  % Add mesh control field for mesh data frames 
  if macConfig.HasMeshControl && ~macConfig.MSDUAggregation
    % Mesh flags field consists of address extension mode and 6 reserved
    % bits
    addressExtMode = int2bit(macConfig.AddressExtensionMode, 2, false)';
    meshFlags = uint8(bi2deOptimized([addressExtMode zeros(1, 6)]));
    meshSequenceNumber = wnet.internal.int2octets(macConfig.MeshSequenceNumber, 4, false)';
    % Prepare Mesh Address Extension subfield based on address extension mode
    address4MeshControl = uint8([]);
    address5MeshControl = uint8([]);
    address6MeshControl = uint8([]);
    if ~(macConfig.ToDS && macConfig.FromDS) && (macConfig.AddressExtensionMode == 1)
      address4MeshControl = hex2DecOctetVector(macConfig.Address4, 6, true);
    elseif macConfig.AddressExtensionMode == 2
      address5MeshControl = hex2DecOctetVector(macConfig.Address5, 6, true);
      address6MeshControl = hex2DecOctetVector(macConfig.Address6, 6, true);
    end
    meshControl = [meshFlags macConfig.MeshTTL meshSequenceNumber address4MeshControl address5MeshControl address6MeshControl]';
  else
    meshControl = uint8([]);
  end

  % Construct the frame octets in decimal format
  frameHeader = [basicMACHeader, address4, qosControl, htControl]';
  frame = [frameHeader; meshControl; payload];

  % Append FCS
  frame = appendFCS(frame);
end

% Prepare and return management frame
function frame = generateManagementFrame(cfg)
  % Prepare management frame header
  basicMACHeader = prepareBasicMACHeader(cfg);

  % Prepare management frame body
  frameBody = prepareManagementFrameBody(cfg);

  % Construct the frame octets in decimal
  frameBytes = [basicMACHeader, frameBody];

  % Append FCS
  frame = appendFCS(frameBytes);
end

% Prepare and return common info field
function commonInfo = prepareCommonInfo(cfg)
  isMURTS = strcmp(cfg.TriggerConfig.TriggerType, 'MU-RTS');

  % Trigger-type (4-bits)
  type = getTriggerTypeCode(cfg.TriggerConfig.TriggerType);

  % Uplink length (12-bits)
  ulLength = getULLength(cfg.TriggerConfig);

  % MoreTF (1-bit)
  moreTF = double(cfg.TriggerConfig.MoreTF);

  % CSRequired (1-bit)
  csRequired = double(cfg.TriggerConfig.CSRequired);

  % Channel bandwidth (2-bits)
  bandwidth = getBandwidthCode(cfg.TriggerConfig.ChannelBandwidth);

  if isMURTS
      % Triggered TXOP Sharing Mode (2-bits);
      txsSharingMode = getTXSSharingMode(0);

      % Prepare common info field octets in decimal format
      commonInfo = [type ulLength moreTF csRequired bandwidth txsSharingMode zeros(1, 32)];

      if strcmp(cfg.TriggerConfig.CommonInfoVariant, 'HE')
          bits54To62 = ones(1, 9);
      else
          % HE/EHT P160 (1-bit)
          p160 = cfg.TriggerConfig.HEorEHTP160;
          % Special User Info Field Flag (1-bit)
          specialUserInfo = ~cfg.TriggerConfig.SpecialUserInfoPresent;
          % EHT Reserved (7-bits);
          ehtReserved = ones(1, 7);
          bits54To62 = [p160 specialUserInfo ehtReserved];
      end

      % Reserved (1-bit)
      reserved = 0;
      commonInfo = [commonInfo bits54To62 reserved];
      commonInfo = uint8(wnet.internal.bits2octets(commonInfo, false));
  else
      % LTF Type and Guard Interval (2-bits)
      LTFTypeAndGI = getLTFAndGICode(cfg.TriggerConfig);

      % MU-MIMO LTF Mode (1-bit)
      muMIMOLTFMode = ~cfg.TriggerConfig.SingleStreamPilots;

      % Number of HE-LTF symbols and Midamble Periodicity (3-bits)
      numHELTFSymbols = getNumHELTFSymbols(cfg.TriggerConfig);

      % UL STBC encoding (1-bit)
      stbc = double(cfg.TriggerConfig.STBC);

      % LDPC Extra Symbol Segment (1-bit)
      ldpcExtraSymbol = double(cfg.TriggerConfig.LDPCExtraSymbol);

      % AP Transmit power (6-bits)
      apTransmitPower = de2biOptimized((cfg.TriggerConfig.APTransmitPower + 20), 6);

      % Pre FEC Padding Factor (1-bit)
      preFECPaddingFactor = getPreFECPaddingFactorCode(cfg.TriggerConfig.PreFECPaddingFactor);

      % PE Disambiguity (1-bit)
      peDisambiguity = double(cfg.TriggerConfig.PEDisambiguity);

      % Spatial reuse (16-bits)
      spatialReuseCode = getSpatialReuseCode(cfg.TriggerConfig);

      % Doppler (1-bit)
      doppler = double(cfg.TriggerConfig.HighDoppler);

      % Reserved UL HE-SIG-A2 field (9-bits)
      heSIGA2Reserved = cfg.TriggerConfig.HESIGAReservedBits';

      % Reserved (1-bit)
      reserved = 0;

      % Prepare common info field octets in decimal format
      commonInfo = [type ulLength moreTF csRequired bandwidth LTFTypeAndGI muMIMOLTFMode...
          numHELTFSymbols stbc ldpcExtraSymbol apTransmitPower preFECPaddingFactor...
          peDisambiguity spatialReuseCode doppler heSIGA2Reserved reserved];
      commonInfo = uint8(wnet.internal.bits2octets(commonInfo, false));
  end
end

function specialUserInfoDec = prepareSpecialUserInfo(specialUserCfg)

% Refer section 9.3.1.22.3 in IEEE P802.11be/D5.0, for encoding of special
% user info bits
% AID12 (12-bits)
aid = de2biOptimized(specialUserCfg.AID12, 12);

% PHY Version Identifier (3-bits)
phyVersion = de2biOptimized(0, 3); % Default - 0

% UL Bandwidth Extension (2-bits)
ulBWExtension = getUplinkBandwidthExtension(specialUserCfg.ULBandwidthExtension);

% EHT Spatial Reuse 1 (4-bits)
ehtSpatialReuse1 = de2biOptimized(15, 4);

% EHT Spatial Reuse 2 (4-bits)
ehtSpatialReuse2 = de2biOptimized(15, 4);

% U-SIG Disregard and Validate (12-bits)
disregardInUSIG1 = ones(1, 6);
validateInUSIG2 = 1;
disregardInUSIG2 = [ones(1, 4) 0];
usigDisregardAndValidate = [disregardInUSIG1 validateInUSIG2 disregardInUSIG2];

% Reserved (3-bits)
reserved = zeros(1, 3);

specialUserInfo = [aid phyVersion ulBWExtension ehtSpatialReuse1 ehtSpatialReuse2 usigDisregardAndValidate reserved];
specialUserInfoDec = uint8(wnet.internal.bits2octets(specialUserInfo, false));
end

% Return channel bandwidth code
function code = getUplinkBandwidthExtension(value)
  switch(value)
    case 0
      code = [0 0];
    case 1
      code = [1 0];
    case 2
      code = [0 1];
    otherwise % 3
      code = [1 1];
  end
end

% Prepare and return user-info field
function userInfoDec = prepareUserInfo(cfg, userInfoCfg)
  isMURTS = strcmp(cfg.TriggerConfig.TriggerType, 'MU-RTS');

  % AID12 (12 bits)
  aid = de2biOptimized(userInfoCfg.AID12, 12);

  % Special User info field configurations
  is320MHz = false;
  if cfg.TriggerConfig.SpecialUserInfoPresent
      specialUserInfoCfg = cfg.TriggerConfig.UserInfo{1};
      uplinkBandwidthExtension = specialUserInfoCfg.ULBandwidthExtension;
      is320MHz = any(uplinkBandwidthExtension == [2 3]);
  end

  % RU Allocation (8-bits)
  b0 = 0;
  if (strcmp(cfg.TriggerConfig.ChannelBandwidth, 'CBW80+80 or CBW160') && ...
          (isMURTS || strcmp(userInfoCfg.RUAllocationRegion, 'secondary 80MHz') || (userInfoCfg.RUSize == 1992))) || ...
          (cfg.TriggerConfig.SpecialUserInfoPresent && is320MHz)
      b0 = 1;
  end

  if cfg.TriggerConfig.SpecialUserInfoPresent && is320MHz && isMURTS
      ruAllocation = [b0 de2biOptimized(69,7)]; % For 320 MHz MU-RTS (ICF) frame only
  else
      ruAllocation = [b0 de2biOptimized(getRUAllocationCode(userInfoCfg),7)];
  end

  % Init fields
  fecCode = 0;
  mcs = zeros(1, 4);
  dcm = 0;
  ssAllocationOrRARU = zeros(1, 6);
  targetRSSI = zeros(1, 7);
  if strcmp(userInfoCfg.UserInfoVariant, 'HE')
      bit39 = 0; % Reserved
  else
      bit39 = userInfoCfg.PS160;
  end

  if isMURTS
      triggerDependentUserInfoPresent = false;
  else % MU-BAR, Basic
      triggerDependentUserInfoPresent = true;
  end

  % AID12 = 2046: User-info field identifies an unallocated RU
  if userInfoCfg.AID12 == 2046
    % Except AID12 and RU Allocation fields, all other fields are reserved
    if triggerDependentUserInfoPresent
      triggerDependentUserInfo = prepareTriggerDependentUserInfo(cfg, userInfoCfg);
      userInfo = [aid, ruAllocation, fecCode, mcs, dcm, ssAllocationOrRARU, targetRSSI, bit39, triggerDependentUserInfo];
    else
      userInfo = [aid, ruAllocation, fecCode, mcs, dcm, ssAllocationOrRARU, targetRSSI, bit39];
    end
    userInfoDec = uint8(wnet.internal.bits2octets(userInfo, false));
    return;
  end

  if ~isMURTS
    % UL FEC Coding (1-bit)
    if strcmp(userInfoCfg.ChannelCoding, 'BCC')
      fecCode = 0;
    else % LDPC
      fecCode = 1;
    end

    % UL MCS (4-bits)
    mcs = de2biOptimized(userInfoCfg.MCS, 4);

    % UL DCM (1-bit)
    if ~cfg.TriggerConfig.STBC
      dcm = double(userInfoCfg.DCM);
    end

    % SS Allocation/RA-RU Information (6-bits)
    if any(userInfoCfg.AID12 == [0, 2045])
      % RA-RU Information
      numRARU = de2biOptimized(userInfoCfg.NumRARU - 1, 5);
      moreRARU = 0;
      if cfg.TriggerConfig.MoreTF
          % Refer section 9.3.1.22.1 of IEEE Std 802.11ax-2021
          moreRARU = double(userInfoCfg.MoreRARU);
      end
      ssAllocationOrRARU = [numRARU moreRARU];

    else % [1 - 2007]
      % SS Allocation
      ssAllocationOrRARU = [de2biOptimized(userInfoCfg.StartingSpatialStream - 1, 3), ...
          de2biOptimized(userInfoCfg.NumSpatialStreams - 1, 3)];
    end

    % UL Target RSSI (7-bits)
    if userInfoCfg.UseMaxTransmitPower
        targetRSSI = de2biOptimized(127, 7);
    else
        targetRSSI = de2biOptimized(userInfoCfg.TargetRSSI+110, 7);
    end
  end

  if triggerDependentUserInfoPresent
    % Trigger Dependent user-info
    triggerDependentUserInfo = prepareTriggerDependentUserInfo(cfg, userInfoCfg);
    % User-info
    userInfo = [aid, ruAllocation, fecCode, mcs, dcm, ssAllocationOrRARU, targetRSSI, bit39, triggerDependentUserInfo];

  else
    % User-info
    userInfo = [aid, ruAllocation, fecCode, mcs, dcm, ssAllocationOrRARU, targetRSSI, bit39];    
  end
  userInfoDec = uint8(wnet.internal.bits2octets(userInfo, false));
end

% Prepare and return trigger dependent user-info field
function triggerDependentUserInfo = prepareTriggerDependentUserInfo(cfg, userInfoCfg)
  switch(cfg.TriggerConfig.TriggerType)
    case 'MU-BAR'
      if userInfoCfg.AID12 == 2046
          % Trigger dependent user-info field is reserved if AID12 is 2046
          baControl = zeros(1, 16); % BA control
          baInformation = zeros(1, 16); % BA information
          triggerDependentUserInfo = [baControl baInformation];
          return;
      end

      % BA control (2-octets)
      ackPolicy = 0; % Only normal ack (0) is supported
      type = de2biOptimized(2, 4); % Only compressed (2) variant is supported
      reserved = zeros(1, 7);
      TID = de2biOptimized(userInfoCfg.TID, 4);

      % BA Information (2-octets)
      fragmentNumber = zeros(1, 4);
      startingSequenceNumber = de2biOptimized(userInfoCfg.StartingSequenceNum, 12);

      % Put the fields together to create trigger dependent user-info
      triggerDependentUserInfo = [ackPolicy, type, reserved, TID, fragmentNumber, startingSequenceNumber];

    otherwise % 'Basic'  
      if userInfoCfg.AID12 == 2046
          % Trigger dependent user-info field is reserved if AID12 is 2046
          triggerDependentUserInfo = zeros(1, 8);
          return;
      end

      mpduMUSpacingFactor = de2biOptimized(userInfoCfg.MPDUMUSpacingFactor, 2);
      tidAggregationLimit = de2biOptimized(userInfoCfg.TIDAggregationLimit, 3);
      reserved = 0;
      preferredAC = de2biOptimized(userInfoCfg.PreferredAC, 2);

      % Put the fields together to create trigger dependent user-info
      triggerDependentUserInfo = [mpduMUSpacingFactor, tidAggregationLimit, reserved, preferredAC];
  end
end

% Prepare and return frame control field
function frameControl = prepareFrameControl(cfg)
  % Protocol Version (2-bits)
  protocolVersion = [0 0];

  % Type (2-bits)
  type = getTypeCode(cfg.getType);

  % Subtype (4-bits)
  subtype = getSubtypeCode(cfg.getSubtype);

  % MoreFrag (1-bit)
  moreFragments = 0;

  % Power Management (1-bit)
  powerManagement = double(cfg.PowerManagement);

  % More Data (1-bit)
  moreData = double(cfg.MoreData);

  % Protected Frame (1-bit)
  protectedFrame = 0;

  % Order (1-bit)
  order = 0;

  if strcmp(cfg.getType, 'Control')
    % 'toDS', 'fromDS' and 'retry' flags are reserved bits in control
    % frames.

    % ToDS (1-bit)
    toDS = 0;

    % FromDS (1-bit)
    fromDS = 0;

    % Retransmission (1-bit)
    retry = 0;

  else
    % ToDS (1-bit)
    toDS = double(cfg.ToDS);

    % FromDS (1-bit)
    fromDS = double(cfg.FromDS);

    % Retransmission (1-bit)
    retry = double(cfg.Retransmission);
  end

  if any(strcmp(cfg.FrameType, {'QoS Data', 'QoS Null'}))
    % +HTC (1-bit)
    order = double(cfg.HTControlPresent);
  end

  % Prepare frame control field octets in decimal format
  frameControl = uint8(bi2deOptimized([protocolVersion, type, subtype; ...
    toDS, fromDS, moreFragments, retry, powerManagement, moreData, protectedFrame, order])');
end

% Prepare and return sequence control field
function sequenceControlOctets = prepareSequenceControl(sequenceNumber, fragmentNumber)
  % Sequence control is a 16-bit field in which MSB 12-bits represent
  % sequence number and LSB 4-bits represent fragment number.
  sequenceNumber = bitshift(sequenceNumber, 4);
  sequenceControl = sequenceNumber + fragmentNumber;

  sequenceControlOctets = wnet.internal.int2octets(sequenceControl, 2, false)';
end

% Prepare and return QoS control field
function qosControl = prepareQoSControl(cfg)
  tid = de2biOptimized(cfg.TID, 4);
  eosp = double(cfg.EOSP);
  ackPolicy = getAckPolicyCode(cfg.AckPolicy);
  amsduPresent = double(cfg.getAMSDUPresent);

  if cfg.IsMeshFrame
    meshControlPresent = double(cfg.HasMeshControl);
    if ~cfg.PowerManagement || strcmp(cfg.SleepMode, 'Light')
      % Mesh power save level subfield is reserved when PowerManagement is
      % set to false.
      % Refer: 9.2.4.5.11 of IEEE Std 802.11-2016
      meshPowerSaveLevel = 0;
    else
      meshPowerSaveLevel = 1;
    end

    bits = bitget(hex2dec(cfg.Address1(1:2)), 1:8);
    isGroupAddress = bits(1); % Group bit
    if isGroupAddress
        % RSPI subfield is reserved in group addressed frames.
        % Refer: 9.2.4.5.12 of IEEE Std 802.11-2016
        rspi = 0;
    else
        rspi = double(cfg.ReceiverServicePeriodInitiated);
    end
    reserved = zeros(1, 5);

    qosControl = [uint8(bi2deOptimized([tid, eosp, ackPolicy, amsduPresent])), ...
      uint8(bi2deOptimized([meshControlPresent, meshPowerSaveLevel, rspi, reserved]))];
  else
    reserved = 0;

    qosControl = [uint8(bi2deOptimized([tid, eosp, ackPolicy, amsduPresent])), uint8(reserved)];
  end
end

% Prepare and return basic MAC header
function basicMACHeader = prepareBasicMACHeader(cfg)
  % Following header fields are mandatory in all data and management frames
  frameControl = prepareFrameControl(cfg);
  duration = wnet.internal.int2octets(cfg.Duration, 2, false)';
  receiverAddress = hex2DecOctetVector(cfg.Address1, 6, true);
  transmitterAddress = hex2DecOctetVector(cfg.Address2, 6, true);
  bssid = hex2DecOctetVector(cfg.Address3, 6, true);
  sequenceControl = prepareSequenceControl(cfg.SequenceNumber, 0);

  basicMACHeader = [frameControl, duration, receiverAddress, transmitterAddress, bssid, sequenceControl];
end

% Return frame type code
function code = getTypeCode(type)
  switch(type)
    case 'Management'
      code = [0 0];
    case 'Control'
      code = [1 0];
    otherwise % Data
      code = [0 1];
  end
end

% Return frame subtype code
function code = getSubtypeCode(type)
switch(type)
  case 'Beacon'
    code = [0 0 0 1];
  case 'QoS Data'
    code = [0 0 0 1];
  case 'QoS Null'
    code = [0 0 1 1];
  case 'Data'
    code = [0 0 0 0];
  case 'Null'
    code = [0 0 1 0];
  case 'RTS'
    code = [1 1 0 1];
  case 'CTS'
    code = [0 0 1 1];
  case 'ACK'
    code = [1 0 1 1];
  case 'Trigger'
    code = [0 1 0 0];
  case 'CF-End'
    code = [0 1 1 1];
  otherwise % Block Ack
    code = [1 0 0 1];
end
end

% Return ack-policy code
function code = getAckPolicyCode(ackPolicy)
  switch(ackPolicy)
    case 'Normal Ack/Implicit Block Ack Request'
      code = [0 0];
    case 'No Ack'
      code = [1 0];
    case 'No explicit acknowledgment/PSMP Ack/HTP Ack'
      code = [0 1];
    otherwise % Block Ack
      code = [1 1];
  end
end

% Return trigger-type code
function code = getTriggerTypeCode(type)
  switch(type)
    case 'Basic'
      code = [0 0 0 0];
    case 'MU-BAR'
      code = [0 1 0 0];
    otherwise % 'MU-RTS'
      code = [1 1 0 0];
  end
end

% Return channel bandwidth code
function code = getBandwidthCode(type)
  switch(type)
    case 'CBW20'
      code = [0 0];
    case 'CBW40'
      code = [1 0];
    case 'CBW80'
      code = [0 1];
    otherwise % 'CBW80+80 or CBW160'
      code = [1 1];
  end
end

% Return pre FEC padding factor code
function code = getPreFECPaddingFactorCode(type)
  switch(type)
    case 1 
      code = [1 0];
    case 2
      code = [0 1];
    case 3
      code = [1 1];
    otherwise % 4
      code = [0 0];
  end
end

% Return length subfield of common info field
function code = getULLength(cfgTrigger)
  switch(cfgTrigger.TriggerType)
    case 'MU-RTS'
      code = zeros(1, 12);
    otherwise
      code = de2biOptimized(cfgTrigger.LSIGLength, 12);  
  end
end

% Return Triggered TXOP Sharing Mode
function code = getTXSSharingMode(txsSharingMode)
    switch txsSharingMode
        case 0
            code = [0 0];
        case 1
            code = [1 0];
        otherwise % 2
            code = [0 1];
    end
end

% Return HE-LTF type and GI code
function code = getLTFAndGICode(cfgTrigger)
  if strcmp(cfgTrigger.CommonInfoVariant, 'HE')
      switch cfgTrigger.HELTFTypeAndGuardInterval
        case '1x HE-LTF + 1.6 us GI'
            code = [0 0];
        case '2x HE-LTF + 1.6 us GI'
            code = [1 0];
        otherwise % '4x HE-LTF + 3.2 us GI'
            code = [0 1];
      end
  else % EHT
      % '4× HE/EHT-LTF + 3.2 μs GI'
      code = [0 1];
  end
end

% Return number of HE LTF Symbols and Midamble periodicity
function code = getNumHELTFSymbols(cfgTrigger)
  if cfgTrigger.HighDoppler == 0
    switch(cfgTrigger.NumHELTFSymbols)
      case 1
        code = [0 0 0];
      case 2
        code = [1 0 0];
      case 4
        code = [0 1 0];
      case 6
        code = [1 1 0];
      otherwise % 8
        code = [0 0 1];
    end
  else
    if cfgTrigger.MidamblePeriodicity == 10
      switch(cfgTrigger.NumHELTFSymbols)
        case 1
          code = [0 0 0];
        case 2
          code = [1 0 0];
        otherwise % 4
          code = [0 1 0];
      end
    else % MidamblePeriodicity == 20
      switch(cfgTrigger.NumHELTFSymbols)
        case 1
          code = [0 0 1];
        case 2
          code = [1 0 1];
        otherwise % 4
          code = [0 1 1];
       end
    end
  end
end

% Return spatial reuse code
function code = getSpatialReuseCode(cfgTrigger)
  code1 = de2biOptimized(cfgTrigger.SpatialReuse1, 4);
  code2 = de2biOptimized(cfgTrigger.SpatialReuse2, 4);
  code3 = de2biOptimized(cfgTrigger.SpatialReuse3, 4);
  code4 = de2biOptimized(cfgTrigger.SpatialReuse4, 4);
  code = [code4 code3 code2 code1];
end

% Return RU allocation code
function code = getRUAllocationCode(cfgUserInfo)
  switch(cfgUserInfo.RUSize)
    case 26
        code = cfgUserInfo.RUIndex - 1;
      case 52
          code = cfgUserInfo.RUIndex + 36;
      case 106
          code = cfgUserInfo.RUIndex + 52;
      case 242
          code = cfgUserInfo.RUIndex + 60;
      case 484
          code = cfgUserInfo.RUIndex + 64;
      case 996
          code = 67;
      otherwise % 1992 (2x996)
          code = 68;
  end
end

% Convert hexadecimal value to uint8 typed vector in given endianness
function octetVector = hex2DecOctetVector(value, numOctets, isBigEndian)
  % Input value is hexadecimal char vector or a string
  hexOctets = reshape(char(value), 2, [])';
  octetVector = uint8(hex2dec(hexOctets)');
  if ~isBigEndian
    octetVector(1:end) = octetVector(end:-1:1);
  end
  octetVector = uint8(octetVector);
end

% Prepare and return management frame-body as a uint8 typed vector
function frameBody = prepareManagementFrameBody(cfg)
  frameBody = uint8([]);

  switch (cfg.FrameType)
    case 'Beacon'
      mgmtCfg = cfg.ManagementConfig;

      % Timestamp (8 octets)
      timestampMSB = wnet.internal.int2octets(bitshift(mgmtCfg.Timestamp, -32), 4, false)';
      timestampLSB = wnet.internal.int2octets(bitand(uint64(mgmtCfg.Timestamp), uint64(intmax('uint32'))), 4, false)';
      % Beacon interval (2 octets)
      beaconInterval = wnet.internal.int2octets(mgmtCfg.BeaconInterval, 2, false)';
      % Capability information (2 octets)
      capability = uint8(bi2deOptimized([double(mgmtCfg.ESSCapability), ...
                      double(mgmtCfg.IBSSCapability), ...
                      0, ... % CF-Pollable
                      0, ... % CF-Poll Request
                      double(mgmtCfg.Privacy), ...
                      double(mgmtCfg.ShortPreamble), ...
                      0, ... % Reserved bit
                      0; ... % Reserved bit
                      double(mgmtCfg.SpectrumManagement), ...
                      double(mgmtCfg.QoSSupport), ...
                      double(mgmtCfg.ShortSlotTimeUsed), ...
                      double(mgmtCfg.APSDSupport), ...
                      double(mgmtCfg.RadioMeasurement), ...
                      0, ... % Reserved bit
                      double(mgmtCfg.DelayedBlockAckSupport), ...
                      double(mgmtCfg.ImmediateBlockAckSupport)]) ...
                      )';

      % Information Elements
      informationElements = getIEs(cfg);

      % Frame Body
      frameBody = [timestampLSB, timestampMSB, beaconInterval, capability, informationElements];
  end
end

% Prepare and return information elements for management frame-body
function informationElements = getIEs(cfg)
  mgmtCfg = cfg.ManagementConfig;
  % Maximum number of Element-IDs are 255. With the new 8-bit extension ID,
  % which is present only for Element-ID 255, maximum number of IEs
  % increased to 511. Refer section 9.4.2.1 in IEEE Std 802.11-2016.
  maxNumberOfIEs = 511;
  ieList = cell(maxNumberOfIEs, 1);
  totalLength = 0;
  nElements = 1;

  % Specify the data type of the cell array elements
  for i = 1:maxNumberOfIEs
    ieList{i} = uint8([]);
  end

  switch(cfg.FrameType)
    case 'Beacon'
      % Element ID constants
      ssidElementID = 0;
      supportedRatesElementID = 1;
      
      % Number of information elements added till now using addIE function
      elementsCount = mgmtCfg.IEIdx;
      
      % Get IDs of the information elements
      idList = zeros(elementsCount, 2);

      if elementsCount == 0  
          ssidInformation = wlan.internal.macGetIEInformation(ssidElementID, mgmtCfg);
          ratesInformation = wlan.internal.macGetIEInformation(supportedRatesElementID, mgmtCfg);
          mgmtCfg = mgmtCfg.addIE(ssidElementID, ssidInformation);
          mgmtCfg = mgmtCfg.addIE(supportedRatesElementID, ratesInformation);
      else
          for i = 1 : elementsCount
            id = mgmtCfg.InformationElements{i, 1};
            % For codegen: When InformationElements is empty, codegen is
            % unable to skip this loop. To enable codegen in determining
            % the size, indexing is done explicitly.
            idList(i, :) = [id(1) id(2)];
          end

          % IE: SSID (mandatory). Add SSID IE to the list only if
          % 'InformationElements' does not already contain SSID IE.
          if ~any(idList(:, 1) == ssidElementID)
            ssidInformation = wlan.internal.macGetIEInformation(ssidElementID, mgmtCfg);
            mgmtCfg = mgmtCfg.addIE(ssidElementID, ssidInformation);
          end

          % IE: Supported Rates (mandatory). Add only if
          % 'InformationElements' does not already contain Supported Rates
          % IE.
          if ~any(idList(:, 1) == supportedRatesElementID)
            ratesInformation = wlan.internal.macGetIEInformation(supportedRatesElementID, mgmtCfg);
            mgmtCfg = mgmtCfg.addIE(supportedRatesElementID, ratesInformation);
          end
      end

      % Get updated element IDs list
      idList = zeros(mgmtCfg.IEIdx, 3);
      for i = 1 : mgmtCfg.IEIdx
        % Assign a sequence number to each element. After sorting all the
        % IEs based on element IDs and element ID extensions, use this
        % sequence number to retrieve the corresponding information.
        idList(i, :) = [mgmtCfg.InformationElements{i, 1} i];
      end

      % Sort the Element IDs
      idList = sortrows(idList, [1, 2]);

      for i = 1:mgmtCfg.IEIdx
        % Get Element ID (1-octet)
        elementID = uint8(idList(i, 1));
        % Get optional extension ID (1-octet)
        elementIDExtension = uint8(idList(i, 2));
        
        length = 0;
        % Check for duplicate IEs
        if elementID == 255
          if ((i + 1) <= mgmtCfg.IEIdx) 
            nextElementID = idList(i+1, 1);
            if ((nextElementID == 255) && (idList(i, 2) == idList(i+1, 2)))
              continue;
            end
          end
          length = length + 1;
        else
          if (((i + 1) <= mgmtCfg.IEIdx) && (idList(i, 1) == idList(i+1, 1)))
            continue;
          end
        end

        % Get information of the IE
        information = mgmtCfg.InformationElements{idList(i, 3), 2};
        % Length of the IE
        length = length + uint8(numel(information));
        % Construct the IE
        if elementID == 255
          informationElement = [elementID, length, elementIDExtension, information];
        else
          informationElement = [elementID, length, information];
        end
        ieList{nElements} = informationElement;
        totalLength = totalLength + numel(informationElement);
        nElements = nElements + 1;
      end
      % Maximum MMPDU size is 2304 octets. This length contains MAC header
      % (24 octets), FCS (4 octets), Fields (12 octets) and IEs (Variable).
      coder.internal.errorIf(totalLength > 2264, 'wlan:wlanMACFrame:BeaconSizeExceeded');
  end

  % Group all the information elements together
  informationElements = zeros(1, totalLength);
  pos = 1;
  for i = 1:nElements
    informationElements(pos : pos+numel(ieList{i})-1) = ieList{i};
    pos = pos + numel(ieList{i});
  end
end

% Append FCS to the given frame.
function codedframe = appendFCS(frame)
  persistent crcCfg
  if isempty(crcCfg)
    crcCfg = crcConfig(Polynomial=[32 26 23 22 16 12 11 10 8 7 5 4 2 1 0], InitialConditions=1, DirectMethod=true, FinalXOR=1);
  end

  % 1 octet = 8 bits
  octetLength = 8;

  % Convert octets to bits to add FCS
  frameBits = int2bit(frame, octetLength, false);
  frameBitsColVector = reshape(frameBits, numel(frameBits), 1);

  % Append FCS to the frame bits
  codedframe = crcGenerate(double(frameBitsColVector), crcCfg);
end

% Validate input NV pairs
function outputFormat = validateNVPairs(nvArgs)

% Default values
defaultParams = struct('OutputFormat', 'octets');
expectedFormatValues = {'bits', 'octets'};

if numel(nvArgs) == 0
  useParams = defaultParams;
else
  % Extract each P-V pair
  if isempty(coder.target) % Simulation path
    p = inputParser;

    % Get values for the P-V pair or set defaults for the optional arguments
    addParameter(p, 'OutputFormat', defaultParams.OutputFormat);
    % Parse inputs
    parse(p, nvArgs{:});

    useParams = p.Results;

  else % Codegen path
    pvPairs = struct('OutputFormat', uint32(0));

    % Select parsing options
    popts = struct('PartialMatching', true);

    % Parse inputs
    pStruct = coder.internal.parseParameterInputs(pvPairs, popts, nvArgs{:});

    % Get values for the P-V pair or set defaults for the optional arguments
    useParams = struct;
    useParams.OutputFormat = coder.internal.getParameterValue(pStruct.OutputFormat, defaultParams.OutputFormat, nvArgs{:});
  end
end

outputFormat = wnet.internal.matchString(useParams.OutputFormat, expectedFormatValues, 'macGenerateMPDU');
end

function dec = bi2deOptimized(bin)
    dec = comm.internal.utilities.bi2deRightMSB(double(bin), 2);
end

function bin = de2biOptimized(dec, n)
    bin = comm.internal.utilities.de2biBase2RightMSB(double(dec), n);
end
