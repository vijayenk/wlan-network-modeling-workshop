function [bits,status,varargout] = wlanHESIGBCommonBitRecover(rx,noiseVarEst,varargin)
%wlanHESIGBCommonBitRecover Recover common field bits in HE-SIG-B field
%   [BITS,STATUS,CFGRX] = wlanHESIGBCommonBitRecover(RX,NOISEVAREST,CFGRX)
%   recovers the HE-SIG-B common field bits given the HE-SIG-B field from
%   an HE MU transmission, the noise variance estimate, and the HE
%   configuration object of type wlanHERecoveryConfig.
%   When you use this syntax and the function cannot interpret the
%   recovered HE-SIG-B common field bits due to an unexpected value, an
%   exception is issued, and the function does not return an output.
%
%   BITS is an int8 matrix containing the recovered common field bits for
%   each content channel of HE-SIG-B field. The size of the BITS output
%   depends on the channel bandwidth:
%
%   * For a channel bandwidth of 20 MHz the size of BITS is 18-by-1.
%   * For a channel bandwidth of 40 MHz the size of BITS is 18-by-2.
%   * For a channel bandwidth of 80 MHz the size of BITS is 27-by-2.
%   * For a channel bandwidth of 160 MHz the size of BITS is 43-by-2.
%
%   STATUS represents the result of content channel decoding, and is
%   returned as a character vector. The STATUS output is determined by the
%   combination of cyclic redundancy check (CRC) per content channel and
%   the number of HE-SIG-B symbols signaled in HE-SIG-A field:
%
%   Success                        - CRC passed for all content channels.
%   ContentChannel1CRCFail         - CRC failed for content channel-1 and
%                                    the number of HE-SIG-B symbols is less
%                                    than 16.
%   ContentChannel2CRCFail         - CRC failed for content channel-2 and
%                                    the number of HE-SIG-B symbols is less
%                                    than 16.
%   UnknownNumUsersContentChannel1 - CRC failed for content channel-1 and
%                                    the number of HE-SIG-B symbols is
%                                    equal to 16.
%   UnknownNumUsersContentChannel2 - CRC failed for content channel-2 and
%                                    the number of HE-SIG-B symbols is
%                                    equal to 16.
%   AllContentChannelCRCFail       - CRC failed for all content channels.
%
%   If the number of HE-SIG-B symbols signaled in HE-SIG-A field is less
%   than 16 and any content channel fails the CRC, then the length of
%   HE-SIG-B field can be determined from HE-SIG-A field. If the signaled
%   number of HE-SIG-B symbols is 16 and any content channel fails the CRC,
%   then the length of the HE-SIG-B field is undetermined.
%
%   CFGRX is an updated format configuration object of type wlanHERecoveryConfig
%   after HE-SIG-B common field decoding.
%
%   [BITS,STATUS] = wlanHESIGBCommonBitRecover(...), when you use this
%   syntax and the function cannot interpret the recovered HE-SIG-B common
%   field bits due to an unexpected value, no exception is issued.
%
%   RX is a vector containing the complex demodulated and equalized
%   HE-SIG-B common field symbols of size N-by-1, where N is the number of
%   active sub-carriers in HE-SIG-B field. For a channel bandwidth of 20
%   MHz, N is 52. For a channel bandwidth of 40 MHz, 80 MHz, or 160 MHz, N
%   is 104. For a bandwidth greater than 40 MHz, RX contains the combined
%   20-MHz subchannel repetitions.
%
%   NOISEVAREST is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   CFGRX is the format configuration object of type wlanHERecoveryConfig 
%   and specifies the parameters for the HE MU format.
%
%   [...] = wlanSIGBCommonFieldBitRecover(...,CSI,CFGRX) uses the channel
%   state information to enhance the demapping of OFDM subcarriers. The CSI
%   input is an M-by-1 column vector of real values, where M is the number
%   of data subcarriers in the HE-SIG-B field.

%   Copyright 2019-2025 The MathWorks, Inc.

%#codegen

narginchk(3,4);
nargoutchk(0,3);
updateConfig = nargout==3; % Validate the interpreted bit values

validateattributes(rx,{'single','double'},{'2d','finite'},mfilename,'rx');
numSubcarriers = size(rx,1);

if isa(varargin{1},'wlanHERecoveryConfig')
    % wlanHESIGBCommonBitRecover(RX,NOISEVAREST,CFGRX)
    nargoutchk(0,3);
    csi = ones(numSubcarriers,1);
    cfg = varargin{1};
elseif nargin>3 && isa(varargin{2},'wlanHERecoveryConfig')
    % wlanHESIGBCommonBitRecover(RX,NOISEVAREST,CSI,CFGRX)
    nargoutchk(0,3);
    csi = varargin{1};
    cfg = varargin{2};
else
    coder.internal.error('wlan:he:InvalidConfigType');
end

if numSubcarriers == 0
    % Return empty for 0 samples
    bits = zeros(0,1,'int8');
    status = 'AllContentChannelCRCFail';
    if updateConfig
        varargout{1} = cfg;
    end
    return;
end

% Validate CSI
if nargin>3
    validateattributes(csi,{'single','double'},{'real','3d','finite'},mfilename,'CSI');
    if any(size(csi) ~= [numSubcarriers 1])
        coder.internal.error('wlan:he:InvalidCSISize',numSubcarriers,1);
    end
end

% Only valid for HE MU packet
coder.internal.errorIf(~strcmp(cfg.PacketFormat,'HE-MU'),'wlan:he:InvalidPacketFormat');

% Validate channel bandwidth
chanBW = wlan.internal.validateParam('CHANBW',cfg.ChannelBandwidth,mfilename);

% Validate input size (rows)
switch chanBW
    case 'CBW20'
        expectedNumSubCarriers = 52;
    otherwise
        expectedNumSubCarriers = 104;
end
coder.internal.errorIf(numSubcarriers~=expectedNumSubCarriers,'wlan:he:InvalidRowLength',expectedNumSubCarriers);

% Validate noise variance
validateattributes(noiseVarEst,{'single','double'},{'real','scalar','nonnegative','finite'},mfilename,'noiseVarEst');

% Validate MCS, DCM and SIGBCompression properties
MCS = cfg.SIGBMCS;
DCM = cfg.SIGBDCM;
cfg.validateConfig('HESIGB');

% Get common block length in bits and RU allocation size
sigbMCSTable = wlan.internal.heSIGBRateTable(MCS,DCM);
chbw = wlan.internal.cbwStr2Num(chanBW);
commonInfo = wlan.internal.heSIGBCommonFieldInfo(chbw,sigbMCSTable.NDBPS);
coder.internal.errorIf(size(rx,2)<commonInfo.NumCommonFieldSymbols,'wlan:he:InvalidColumnLength',commonInfo.NumCommonFieldSymbols);

% Initialize outputs
failCRC = coder.nullcopy(false(1,commonInfo.NumContentChannels));
commonBits = coder.nullcopy(zeros(commonInfo.NumCommonFieldBits,commonInfo.NumContentChannels,'int8'));
ruAllocation = coder.nullcopy(zeros(commonInfo.NumRUAllocationSubfield*8,commonInfo.NumContentChannels));
center26ToneRU = zeros(1,commonInfo.NumContentChannels);

% Process each content channel independently
for icc = 1:commonInfo.NumContentChannels
    % Decode HE-SIG-B common field
    nsdIndex = 52*(icc-1)+(1:52); % Subcarrier indices for a content channel
    decoded = wlan.internal.heSIGBDecode(rx(nsdIndex,:),csi(nsdIndex,:),noiseVarEst,sigbMCSTable,MCS,DCM);

    % Extract common block field bits
    commonBits(:,icc) = decoded(1:commonInfo.NumCommonFieldBits);

    % Parse common block bits
    ruAllocation(:,icc) = commonBits(1:commonInfo.NumRUAllocationSubfield*8,icc);

    % Extract Center26ToneRU information for CBW80 and CBW160
    if any(strcmp(chanBW,{'CBW80','CBW160'}))
        center26ToneRU(:,icc) = commonBits(commonInfo.NumRUAllocationSubfield*8+1,icc);
    end

    % Extract CRC and determine the CRC state
    crc = commonBits(commonInfo.NumRUAllocationSubfield*8+commonInfo.Center26ToneBit+(1:commonInfo.NumCRCBits),icc);
    checksum = wlan.internal.crcGenerate(commonBits(1:commonInfo.NumRUAllocationSubfield*8+commonInfo.Center26ToneBit,icc),8);
    failCRC(icc) = any(checksum(1:4)~=crc);
end

bits = commonBits;

% If all content channel fails then do not process further
if sum(all(failCRC,1))==numel(failCRC) % For codegen
    status = 'AllContentChannelCRCFail';
    varargout{1} = cfg;
    return
end

if updateConfig
    cfg = wlan.internal.interpretHEMUSIGBCommonBits(commonBits,failCRC,cfg);
end

% HE-SIG-B common field
if all(failCRC==0)
    status = 'Success';
elseif failCRC(1) && cfg.NumSIGBSymbolsSignaled<16
    status = 'ContentChannel1CRCFail';
elseif failCRC(2) && cfg.NumSIGBSymbolsSignaled<16
    status = 'ContentChannel2CRCFail';
elseif failCRC(1) && cfg.NumSIGBSymbolsSignaled==16
    status = 'UnknownNumUsersContentChannel1';
elseif failCRC(2) && cfg.NumSIGBSymbolsSignaled==16
    status = 'UnknownNumUsersContentChannel2';
else
    status = 'AllContentChannelCRCFail';
end

if updateConfig
    varargout{1} = cfg;
end

end
