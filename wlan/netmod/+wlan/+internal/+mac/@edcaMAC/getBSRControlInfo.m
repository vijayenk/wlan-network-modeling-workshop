function aControlInfo = getBSRControlInfo(obj)
%getBSRControlInfo Return structure containing BSR Control Info
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   getBSRControlInfo(OBJ) returns a struture containing BSR Control Info.

% Copyright 2025 The MathWorks, Inc.

% Reference: Section 9.2.4.6a.4 in IEEE Std 802.11ax-2021.
aControlInfo = obj.BSRControlInfoTemplate;
% As MU is supported only in non-MLD, packets are present in per-link
% queues.
queueObj = obj.LinkEDCAQueues;

totalQueueLengths = sum(queueObj.TxQueueLengths) + ... % Transmission queue length per AC
    sum(queueObj.RetryBufferLengths); % Retry buffer length per AC
dataPresentPerAC = totalQueueLengths ~= 0;
aControlInfo.ACIBitmap = dataPresentPerAC;
if ~any(dataPresentPerAC)
    % If there is no data in any AC, indicate in the ACI Bitmap that the queue
    % size all subfield contains the buffer status of all ACs and its value
    % will be 0.
    aControlInfo.ACIBitmap = ones(1, 4);
end

% Consider the AC with highest data in bytes as the AC that deserves high
% priority. This is specific to implementation as per standard.
txQueuesMSDULengths = totalMSDULengthsInTxQueuesPerAC(queueObj);
retryBufferMSDULengths = totalMSDULengthsInRetryBufferPerAC(queueObj);
queueSizeInBytesPerAC = txQueuesMSDULengths + retryBufferMSDULengths;
aciHigh = find(queueSizeInBytesPerAC == max(queueSizeInBytesPerAC), 1, 'last');
aControlInfo.ACIHigh = aciHigh-1;

queueSizeHigh = queueSizeInBytesPerAC(aciHigh);
queueSizeAll = sum(queueSizeInBytesPerAC);
maxQueueSizeField = max(queueSizeHigh, queueSizeAll);

% Choose the scaling factor (SF) for queue size subfields from the possible
% values of 16, 256, 2048 and 32768 based on the maximum queue size that
% can be reported by each scaling factor. The size of queue size subfields
% is 1 octet. Maximum value represented by 1 octet is 255. But 255 is used
% to report unknown/unspecified queue size. Hence, use 254 to get the
% maximum queue size reported by each SF.
if maxQueueSizeField <= 254*16
    sf = 16;
    sfEncode = 0; % Encoding for SF = 16 is 0
elseif maxQueueSizeField <= 254*256
    sf = 256;
    sfEncode = 1; % Encoding for SF = 256 is 1
elseif maxQueueSizeField <= 254*2048
    sf = 2048;
    sfEncode = 2; % Encoding for SF = 2048 is 2
else
    sf = 32768;
    sfEncode = 3; % Encoding for SF = 32768 is 2
end

% Queue Size High and Queue Size All must be rounded up to nearest multiple
% of SF octets.
if queueSizeHigh > 254*32768
    % Set queue size high to 254, if it is greater than 254 * SF. Reference:
    % Section 9.2.4.6a.4 of IEEE Std 802.11ax-2021.
    queueSizeHigh = 254;
else
    queueSizeHigh = ceil(queueSizeHigh/sf);
end

if queueSizeAll > 254*32768
    % Set queue size all to 254, if it is greater than 254 * SF. Reference:
    % Section 9.2.4.6a.4 of IEEE Std 802.11ax-2021.
    queueSizeAll = 254;
else
    queueSizeAll = ceil(queueSizeAll/sf);
end

aControlInfo.ScalingFactor = sfEncode;
aControlInfo.QueueSizeHigh = queueSizeHigh;
aControlInfo.QueueSizeAll = queueSizeAll;
end