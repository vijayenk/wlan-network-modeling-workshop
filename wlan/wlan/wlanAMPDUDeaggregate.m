function [mpduList, delimiterCRCFails, status] = wlanAMPDUDeaggregate(ampdu, phyConfig, varargin)
%wlanAMPDUDeaggregate A-MPDU deaggregation
%   [MPDULIST, DELIMITERCRCFAILS, STATUS] = wlanAMPDUDeaggregate(AMPDU,
%   PHYFORMAT) deaggregates and extracts the MPDUs from the given A-MPDU of
%   specified physical layer format, PHYFORMAT.
%
%   MPDULIST is the list of MPDUs, returned as a cell array containing one
%   or more character arrays, one for each MPDU. Each row in a character
%   array is the hexadecimal representation of an octet. If no MPDU
%   delimiter is found in the given A-MPDU, MPDULIST is returned as an
%   empty cell array.
%
%   DELIMITERCRCFAILS indicates the delimiter CRC failures for all the
%   subframes found in the A-MPDU. It is returned as a logical row vector
%   where each element corresponds to an A-MPDU subframe. A value of 1 in
%   this vector indicates that the delimiter CRC failed for the subframe
%   and the corresponding index in the MPDULIST contains an MPDU which may
%   or may not be valid. The value 0 indicates delimiter CRC passed for the
%   subframe and the corresponding index in the MPDULIST contains a valid
%   MPDU.
%
%   STATUS is the result of A-MPDU deaggregation, specified as an
%   enumeration value of type wlanMACDecodeStatus. Any value of status
%   other than 'Success' (0) indicates that the A-MPDU deaggregation has
%   stopped because the input A-MPDU is either corrupted or malformed.
%
%   AMPDU represents the aggregated MAC protocol data unit, specified as
%   one of the following types:
%     - A binary vector representing A-MPDU bits.
%     - A character vector representing octets in hexadecimal format.
%     - A string scalar representing octets in hexadecimal format.
%     - A numeric vector, where each element is in the range of [0 - 255]
%       inclusive, representing octets in decimal format.
%     - An n-by-2 character array, where each row represents an octet in
%       hexadecimal format.
%
%   PHYFORMAT is a character vector or string and must be one of the
%   following: 'HT', 'VHT', 'HE-SU', 'HE-EXT-SU', 'HE-TB', 'HE-MU', 'EHT-SU'.
%
%   [...] = wlanAMPDUDeaggregate(AMPDU, PHYCONFIG) deaggregates and
%   extracts the MPDUs from the given A-MPDU.
%
%   PHYCONFIG is a format configuration object of type wlanHTConfig, 
%   wlanVHTConfig, wlanHERecoveryConfig, wlanHESUConfig, wlanHETBConfig, 
%   wlanHEMUConfig, or wlanEHTMUConfig. When PHYCONFIG is an object of 
%   type wlanEHTMUConfig, the object must specify the configuration for a
%   single user transmission.
%
%   [...] = wlanAMPDUDeaggregate(..., Name, Value) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
%
%   'DataFormat'            Format of AMPDU input, specified as 'bits' or
%                           'octets'. The default value is 'bits'. If you
%                           specify this value as 'octets', specify the
%                           AMPDU input as a numeric vector of octets in
%                           decimal format, or as a character array or
%                           string scalar of octets in hexadecimal format.
%                           If you specify this value as 'bits', specify
%                           the AMPDU input as a binary-valued vector.
%
%   'SuppressWarnings'      Suppress warning messages, specified as true or
%                           false. The default value is false. To suppress
%                           warning messages, specify this input as true.
%

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

narginchk(2, 10);
% Initialization
subframeCount = 0;
failedIdx = cell(1, 0);
mpduList = cell(1, 0);
delimiterCRCFails = false(1, 0);
nvPair = varargin;

[status, phyFormat, ampdu, outputDecOctets] = validateInputs(ampdu, phyConfig, nvPair{:});
if status ~= wlanMACDecodeStatus.Success
    return;
end

i = 1;
ampduLength = numel(ampdu);

while (i + 3) <= ampduLength
    % Search for delimiter: Each delimiter has 4th octet as the signature
    % 78 (0x4E). Refer Table 9-422 of IEEE Std 802.11-2016.
    if ampdu(i + 3) == 78
        delimiterWithCRC = reshape(int2bit(ampdu(i : i+2), 8, false), [], 1);
        
        % Validate delimiter CRC
        [delimiter, err] = checkDelimiterCRC(delimiterWithCRC);
        
        i = i + 4;
        % If this delimiter CRC fails, continue searching for another
        % delimiter.
        if err
            % Try to decode the best possible MPDU even if the delimiter
            % CRC failed:
            %   If the delimiter CRC has failed and no other delimiter is
            %   found for at least 14 octets, retrieve the data until
            %   another delimiter is encountered and consider it as the
            %   MPDU payload.
            failedMPDULength = 0;
            j = i;
            while (j + 3) <= ampduLength
                % Stop when another delimiter is found.
                if (ampdu(j + 3) == 78)
                    break;
                end
                
                % Move on to the next 4 octets
                j = j + 4;
                
                % Calculate the length remaining until the next delimiter
                failedMPDULength = failedMPDULength + 4;
            end
            
            if (j + 3) >= ampduLength
                failedMPDULength = failedMPDULength + rem(ampduLength, 4);
            end
            
            if strcmp(phyFormat, 'HT-Mixed')
                maxMPDULength = 4095;
            else % wlanVHTConfig or wlanHESUConfig or wlanEHTMUConfig
                maxMPDULength = 11454;
            end
            
            if failedMPDULength > maxMPDULength
                failedMPDULength = maxMPDULength;
            end
            
            % Retrieve and store the remaining data until the next
            % delimiter as an MPDU, provided that the data is at least 14
            % octets.
            if (failedMPDULength >= 14) && ((i + failedMPDULength - 1) <= ampduLength)
                subframeCount = subframeCount + 1;
                failedIdx{end + 1} = subframeCount;
                if outputDecOctets
                    mpduList{end+1} = ampdu(i : i+failedMPDULength-1);
                else
                    mpduList{end+1} = dec2hex(ampdu(i : i+failedMPDULength-1), 2);
                end
                i = i + failedMPDULength;
            end
            
            % Continue search for another delimiter
            continue;
            
        else % Delimiter CRC passed
            % Extract the MPDU length from the delimiter
            if strcmp(phyFormat, 'HT-Mixed')
                mpduLength = bi2deOptimized(delimiter(5:end));
            else % VHT or HE-SU or HE-EXT-SU or EHT-SU
                mpduLength = bi2deOptimized([delimiter(5:end) delimiter(3:4)]);
            end
            
            % Stop processing a VHT/HE/EHT-SU format A-MPDU if an EOF zero
            % delimiter is received
            if (delimiter(1) == 1) && (mpduLength == 0) && ...
                    (strcmp(phyFormat,'VHT') || strcmp(phyFormat,'HE-SU') || strcmp(phyFormat,'EHT-SU'))
                % EOF detected
                break;
            end
            
            % If zero delimiters are encountered, continue searching for a
            % non-zero delimiter.
            if (mpduLength == 0)
                continue;
            end
        end
        
        % Count the number of subframes in the A-MPDU
        subframeCount = subframeCount + 1;
        
        % Extract the MPDU bits based on the retrieved MPDU length
        if (i + mpduLength - 1) <= ampduLength
            if outputDecOctets
                mpduList{end + 1} = ampdu(i : i+mpduLength-1);
            else
                mpduList{end + 1} = dec2hex(ampdu(i : i+mpduLength-1), 2);
            end
        else
            if outputDecOctets
                mpduList{end + 1} = ampdu(i : end);
            else
                mpduList{end + 1} = dec2hex(ampdu(i : end), 2);
            end
            status = wlanMACDecodeStatus.InvalidDelimiterLength;
            break;
        end
        i = i + mpduLength;
        
        % VHT single MPDU
        if (delimiter(1) == 1) && isscalar(mpduList) && strcmp(phyFormat, 'VHT')
            break;
        end
        
        % Skip subframe padding
        pad = abs(mod(mpduLength, -4));
        if pad
            i = i + pad;
        end
        
    else
        % Move on to find a valid delimiter
        i = i + 4;
    end
end

if subframeCount == 0
    % If no delimiter is found
    status = wlanMACDecodeStatus.NoMPDUFound;
else
    % Construct a bitmap denoting delimiter CRC failures
    delimiterCRCFails = false(1, subframeCount);

    % Indicate the failed delimiter CRCs in the vector
    for i = 1:numel(failedIdx)
        delimiterCRCFails(failedIdx{i}) = 1;
    end

    % If all the delimiter CRCs failed
    if all(delimiterCRCFails)
        status = wlanMACDecodeStatus.CorruptedAMPDU;
    end
end
end

% Checks delimiter CRC
function [delimiter, err] = checkDelimiterCRC(delimiterWithCRC)
    persistent crcCfg

    % 8-bit CRC Detector
    if isempty(crcCfg)
        crcCfg = crcConfig(Polynomial=[8 2 1 0], InitialConditions=1, DirectMethod=true, FinalXOR=1);
    end

    [delimiterColVector, err] = crcDetect(double(delimiterWithCRC), crcCfg);
    delimiter = reshape(delimiterColVector, 1, []);
end

% Validates inputs
function [status, phyFormat, decOctets, outputDecOctets] = validateInputs(ampdu, phyConfig, options)

    arguments
        ampdu
        phyConfig
        options.DisableValidation = false;
        options.DataFormat = 'bits';
        options.SuppressWarnings (1,1) {mustBeNumericOrLogical, mustBeReal, mustBeNonNan} = false;
        options.OutputDecimalOctets (1,1) logical = false;
    end

    % Initialize
    status = wlanMACDecodeStatus.Success;
    ampduLength = numel(ampdu);

    % Set outputs
    disableValidation = options.DisableValidation;
    suppressWarns = options.SuppressWarnings;
    outputDecOctets = options.OutputDecimalOctets;

    % Validate data format separately since it uses custom error message
    if disableValidation
        dataFormat = options.DataFormat;
    else
        expectedFormatValues = {'bits', 'octets'};
        dataFormat = validatestring(options.DataFormat, expectedFormatValues, mfilename);
        if isempty(ampdu) || (isstring(ampdu) && isscalar(ampdu) && (strlength(ampdu) == 0))
            coder.internal.error('wlan:shared:ExpectedNonEmptyValue');
        end
    end

    % Validate PHY config and convert to PHY format
    [phyFormat, ~] = wlan.internal.phyConfigTophyFormat(phyConfig, disableValidation);

    if strcmpi(dataFormat, 'bits')
        % Validate A-MPDU given in the form of bits
        if ~disableValidation
            validateattributes(ampdu, {'logical', 'numeric'}, {'binary', 'vector'}, '', 'A-MPDU');
        end
        if (rem(ampduLength, 8) ~= 0)
            coder.internal.error('wlan:shared:InvalidDataSize');
        end
        decOctets = wnet.internal.bits2octets(ampdu, false)';
    else
        % A-MPDU format must be in either hexadecimal or decimal octets
        if isnumeric(ampdu)
            validateattributes(ampdu, {'numeric'}, {'vector', 'integer', 'nonnegative', '<=', 255}, mfilename, 'A-MPDU');
            decOctets = reshape(ampdu, 1, []);

        else % char or string
            if ischar(ampdu)
                if isvector(ampdu)
                    % Convert row vector to column of octets.
                    hexOctets = reshape(ampdu, 2, [])';
                else
                    validateattributes(ampdu, {'char'}, {'2d', 'ncols', 2}, mfilename, 'A-MPDU', 1);
                    hexOctets = ampdu;
                end

            elseif isstring(ampdu) % string
                validateattributes(ampdu, {'string'}, {'scalar'}, mfilename, 'A-MPDU')

                % Convert octets to char type
                hexOctets = reshape(char(ampdu), 2, [])';
            else
                coder.internal.error('wlan:shared:UnexpectedFrameInputType', 'A-MPDU');
            end

            % Validate hex-digits
            wnet.internal.validateHexOctets(hexOctets, 'A-MPDU');

            % Converting hexadecimal format octets to integer format
            decOctets = hex2dec(hexOctets)';
        end
    end

    % Validate minimum length for an A-MPDU. Minimum length consists of a
    % delimiter (4 octets) and the smallest frame that can be put in the
    % A-MPDU, Ack (14 octets).
    if (numel(decOctets) < 18)
        status = wlanMACDecodeStatus.NotEnoughData;
        if ~suppressWarns
            coder.internal.warning('wlan:wlanAMPDUDeaggregate:NotEnoughDataToParseAMPDU');
        end
    end
end

function dec = bi2deOptimized(bin)
    dec = comm.internal.utilities.bi2deRightMSB(double(bin), 2);
end
