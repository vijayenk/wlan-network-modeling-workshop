function amsdu = macGenerateAMSDU(msduList, macConfig)
%macGenerateAMSDU Generate an A-MSDU with given MSDUs
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   AMSDU = macGenerateAMSDU(MSDULIST,MACCONFIG) generates an A-MSDU with
%   the MSDUs given in the MSDULIST.
%
%   AMSDU is the aggregation of given MSDUs, returned as a uint8 typed
%   column vector.
%
%   MSDULIST is a list of MSDUs, specified as a cell array of structures.
%   Each structure has the following fields:
%       DestinationAddress   - 12-element character vector or string scalar,
%                              representing a six-octet hexadecimal number
%       SourceAddress        - 12-element character vector or string scalar,
%                              representing a six-octet hexadecimal number
%       MSDU                 - Column vector of octets in decimal format
%       MeshTTL              - Integer scalar, representing the number of
%                              remaining hops to forward the MSDU.
%                              Applicable only when Mesh Control field is
%                              expected to be present in A-MSDU subframe
%                              header
%       MeshSequenceNumber   - Integer scalar, representing sequence number
%                              assigned by mesh source station. Applicable
%                              only when Mesh Control field is expected to
%                              be present in A-MSDU subframe header
%       AddressExtensionMode - Integer scalar, representing number of
%                              address fields in Mesh Control field.
%                              Applicable only when Mesh Control field is
%                              expected to be present in A-MSDU subframe
%                              header
%       Address4             - 12-element character vector or string scalar,
%                              representing a six-octet hexadecimal number.
%                              Applicable only when AddressExtensionMode is
%                              set to 1.
%       Address5             - 12-element character vector or string scalar,
%                              representing a six-octet hexadecimal number.
%                              Applicable only when AddressExtensionMode is
%                              set to 2.
%       Address6             - 12-element character vector or string scalar,
%                              representing a six-octet hexadecimal number.
%                              Applicable only when AddressExtensionMode is
%                              set to 2.
%
%   MACCONFIG is an object of type wlanMACFrameConfig.

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

% A-MSDU subframe header length
subframeHdrLength = 14;
% Mesh Control field has a fixed length of 6 octets and variable length of
% 0, 6 or 12 octets.
meshControlOverhead = 6 + macConfig.AddressExtensionMode*6;
if macConfig.HasMeshControl
  subframeHdrLength = subframeHdrLength + meshControlOverhead;
end

% Get number of subframes to be prepared
numMSDUs = numel(msduList);

amsduLength = 0;
for i = 1:numMSDUs
  msduLen = numel(msduList{i}.MSDU);
  amsduLength = amsduLength + subframeHdrLength + msduLen;
  if (i ~= numMSDUs) % If not last MSDU, align to 4-bytes with padding
    amsduLength = amsduLength + wnet.internal.padLength(amsduLength, 4);
  end
end

% Validate length of A-MSDU
validateFrameLength(amsduLength, macConfig.FrameFormat);

amsdu = zeros(amsduLength, 1, 'uint8');
pos = 1;

for i = 1:numMSDUs
  msduInfo = msduList{i};

  % Prepare A-MSDU subframe header
  destinationAddress = hex2DecOctetVector(msduInfo.DestinationAddress, 6);
  sourceAddress = hex2DecOctetVector(msduInfo.SourceAddress, 6);
  length = wnet.internal.int2octets(numel(msduInfo.MSDU), 2, true);
  % Add mesh control field for mesh data frames
  if macConfig.HasMeshControl
    % Mesh flags field consists of address extension mode and 6 reserved bits
    addressExtMode = int2bit(msduInfo.AddressExtensionMode, 2, false)';
    meshFlags = uint8(bi2deOptimized([addressExtMode zeros(1, 6)]));
    meshSN = wnet.internal.int2octets(msduInfo.MeshSequenceNumber, 4, false);
    % Prepare Mesh Address Extension subfield based on address extension mode
    address4 = uint8([]);
    address5 = uint8([]);
    address6 = uint8([]);
    if msduInfo.AddressExtensionMode == 1
      address4 = hex2DecOctetVector(msduInfo.Address4, 6);
    elseif msduInfo.AddressExtensionMode == 2
      address5 = hex2DecOctetVector(msduInfo.Address5, 6);
      address6 = hex2DecOctetVector(msduInfo.Address6, 6);
    end
    meshControl = [meshFlags; msduInfo.MeshTTL; meshSN; address4; address5; address6];
  else
    meshControl = uint8([]);
  end
  
  if i ~= numMSDUs
    % Create an A-MSDU subframe with byte padding
    frame = [destinationAddress; sourceAddress; length; meshControl; msduInfo.MSDU];
    padLen = wnet.internal.padLength(size(frame,1),4);
    amsduSubframe = [frame; zeros(padLen,1,'uint8')];
  else
    % Create an A-MSDU subframe
    amsduSubframe = [destinationAddress; sourceAddress; length; meshControl; msduInfo.MSDU];
  end
  
  amsdu(pos : pos+numel(amsduSubframe)-1) = amsduSubframe;
  pos = pos + numel(amsduSubframe);
end
end

% Convert hexadecimal value to uint8 typed vector in given endianness
function octetVector = hex2DecOctetVector(value, numOctets)
  % Input value is hexadecimal char vector or a string
  hexOctets = reshape(char(value), 2, [])';
  octetVector = uint8(hex2dec(hexOctets));
end

% Validate frame-length limits
function validateFrameLength(amsduLength, frameFormat)
  % Refer Table:9-19 in Std IEEE 802.11-2016
  maxNonHTAMSDULength = 4065;
  maxHTAMSDULength = 7935;

  % Non-HT format A-MSDU length validation
  coder.internal.errorIf((strcmp(frameFormat, 'Non-HT') && (amsduLength > maxNonHTAMSDULength)), 'wlan:wlanMACFrame:NonHTAMSDUSizeExceeded');

  % HT format A-MSDU length validation
  coder.internal.errorIf((strcmp(frameFormat, 'HT-Mixed') && (amsduLength > maxHTAMSDULength)), 'wlan:wlanMACFrame:HTAMSDUSizeExceeded');
end

function dec = bi2deOptimized(bin)
    dec = comm.internal.utilities.bi2deRightMSB(double(bin), 2);
end
