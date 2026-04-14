function indices = wlanFieldIndices(cfgFormat,varargin)
% wlanFieldIndices Generate field indices for WLAN packet
%   INDICES = wlanFieldIndices(CFGFORMAT) returns the start and end
%   time-domain sample indices for all fields in a packet relative to the
%   first sample in a packet.
%
%   INDICES is a structure array of field names for the specified
%   configuration and contains the start and end indices of all fields in a
%   packet.
%
%   CFGFORMAT is a format configuration object of type wlanVHTConfig,
%   wlanHTConfig, wlanNonHTConfig, wlanS1GConfig, wlanDMGConfig,
%   wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig, wlanHERecoveryConfig,
%   wlanWURConfig, wlanEHTMUConfig, wlanEHTTBConfig, or wlanEHTRecoveryConfig.
%
%   INDICES = wlanFieldIndices(CFGFORMAT,FIELDNAME) returns the start and
%   end time-domain sample indices for the specified FIELDNAME in a packet.
%   INDICES is a row vector of length two containing the start and end
%   sample indices of the specified field.
%
%   FIELDNAME is a character vector or string specifying the field of
%   interest and depends on the type of CFGFORMAT:
%
%     For wlanHTConfig FIELDNAME must be one of 'L-STF', 'L-LTF', 'L-SIG',
%     'VHT-SIG-A', 'VHT-STF', 'VHT-LTF', 'VHT-SIG-B', or 'VHT-Data'.
%
%     For wlanVHTConfig FIELDNAME must be one of 'L-STF', 'L-LTF', 'L-SIG',
%     'HT-SIG', 'HT-STF', 'HT-LTF', or 'HT-Data'.
%
%     For wlanNonHTConfig FIELDNAME must be one of 'L-STF', 'L-LTF',
%     'L-SIG', or 'NonHT-Data'.
%
%     For wlanS1GConfig, the fields of interest, depend on the S1G
%     configuration and preamble type. FIELDNAME 'S1G-STF', 'S1G-LTF1', and
%     'S1G-DATA' are common for all S1G configurations. For a 1MHz, or >=
%     2MHz short preamble configuration, additional valid fields of
%     interest are 'S1G-SIG', or 'S1G-LTF2N'. For >= 2MHz long preamble
%     configuration, additional valid fields of interest are 'S1G-SIG-A',
%     'S1G-DSTF', 'S1G-DLTF', or 'S1G-SIG-B'.
%
%     For wlanDMGConfig, the fields of interest 'DMG-STF', 'DMG-CE',
%     'DMG-Header', and 'DMG-Data' are common for all DMG PHY formats.
%     FIELDNAME 'DMG-AGC', 'DMG-AGCSubfields', 'DMG-TRN', 'DMG-TRNCE', and
%     'DMG-TRNSubfields' are valid for all DMG PHY formats when
%     'TrainingLength' property of wlanDMGConfig is greater than zero. The
%     function returns field indices for 'DMG-AGCSubfields' and
%     'DMG-TRNSubfields' in a matrix of size R-by-2, where R is the number
%     of subfields. Each row of the matrix contains the start and end
%     indices of each subfield.
%
%     For wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig, or wlanHERecoveryConfig,
%     the field of interest must be 'L-STF', 'L-LTF', 'L-SIG', 'RL-SIG',
%     'HE-SIG-A', 'HE-SIG-B', 'HE-STF', 'HE-LTF', 'HE-Data', or 'HE-PE'. When
%     the 'HighDoppler' property of wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig or
%     wlanHERecoveryConfig is true, the function returns the field indices for 'HE-LTF'
%     in a matrix of size R-by-2, where R is the number of HE-LTF fields in
%     both preamble and data portions. The function returns the field
%     indices for 'HE-Data' in a matrix of size R-by-2, where R is the
%     number of blocks of data field separated by midamble periods. Each
%     row of the matrix contains the start and end indices of each block of
%     the data field.
%
%     For wlanWURConfig FIELDNAME must be one of 'L-STF', 'L-LTF',
%     'L-SIG', 'BPSK-Mark1', 'BPSK-Mark2', 'WUR-Sync', or 'WUR-Data'. The
%     field indices for 'WUR-Sync' and 'WUR-Data' are returned in a matrix
%     of size R-by-2, where R is the number of active subchannels.
%
%     For wlanEHTMUConfig, wlanEHTTBConfig, or wlanEHTRecoveryConfig the
%     field of interest must be 'L-STF', 'L-LTF', 'L-SIG', 'RL-SIG',
%     'U-SIG', 'EHT-SIG', 'EHT-STF', 'EHT-LTF', 'EHT-Data', or 'EHT-PE'.
%     The function returns the field indices as a matrix of size R-by-2,
%     where R is the number of subfields. Each row of the matrix contains
%     the start and end indices of each subfield.
%
%   INDICES = wlanFieldIndices(...,'OversamplingFactor',OSF) returns the
%   start and end time-domain sample indices of a single field or all
%   fields in a packet oversampled by a factor of OSF. OSF must be >= 1,
%   and the resultant indices must be integer. The default is 1.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Validate input is a class object
    validateattributes(cfgFormat, {'wlanHESUConfig','wlanHEMUConfig','wlanHETBConfig','wlanS1GConfig','wlanVHTConfig','wlanHTConfig','wlanNonHTConfig','wlanDMGConfig','wlanHERecoveryConfig','wlanWURConfig','wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig'}, {'scalar'}, mfilename, 'format configuration object');

    % DSSS modulation in non-HT format is not supported
    coder.internal.errorIf(isa(cfgFormat, 'wlanNonHTConfig') &&  strcmp(cfgFormat.Modulation, 'DSSS'), 'wlan:wlanFieldIndices:InvalidModulation');

    narginchk(1,4)
    if any(nargin == [1 3])
        % wlanFieldIndices(CFG) or
        % wlanFieldIndices(CFG,'OversamplingFactor',OSF)
        osf = wlan.internal.parseOSF(varargin{:});
        if isa(cfgFormat,'wlanHESUConfig') || isa(cfgFormat,'wlanHEMUConfig') || isa(cfgFormat,'wlanHETBConfig')
            indices = getHEIndices(cfgFormat,osf);
        elseif isa(cfgFormat,'wlanEHTMUConfig') || isa(cfgFormat,'wlanEHTTBConfig')
            indices = getEHTIndices(cfgFormat,osf);
        elseif isa(cfgFormat,'wlanHERecoveryConfig')
            wlan.internal.validateParam('CHANBW',cfgFormat.ChannelBandwidth,mfilename);
            indices = getHEIndices(cfgFormat,osf);
        elseif isa(cfgFormat,'wlanEHTRecoveryConfig')
            wlan.internal.validateParam('EHTCHANBW',cfgFormat.ChannelBandwidth,mfilename);
            indices = getEHTIndices(cfgFormat,osf);
        elseif isa(cfgFormat, 'wlanS1GConfig')
            if ~strcmp(packetFormat(cfgFormat),'S1G-Long')
                [numLTF, symLength, N2] = getS1GParams(cfgFormat,osf);
                indSTF = getIndices(cfgFormat,'S1G-STF',osf,N2);
                indLTF1 = getIndices(cfgFormat,'S1G-LTF1',osf,N2);
                indSIG = getIndices(cfgFormat,'S1G-SIG',osf,N2);
                if numLTF == 1
                    indLTF2N = zeros(0,2,'uint32'); % No LTF2N field
                else
                    indLTF2N = getIndices(cfgFormat,'S1G-LTF2N',osf,N2,numLTF);
                end
                if  any(cfgFormat.APEPLength == 0)
                    indS1GData = zeros(0,2,'uint32');
                else
                    indS1GData = getIndices(cfgFormat,'S1G-Data',osf,N2,numLTF,symLength);
                end
                % Fields which are not present in S1G short or S1G 1MHz
                indSIGA = zeros(0,2,'uint32');
                indDSTF = zeros(0,2,'uint32');
                indDLTF = zeros(0,2,'uint32');
                indSIGB = zeros(0,2,'uint32');
            else
                [numLTF, symLength, N2] = getS1GParams(cfgFormat,osf);
                indSTF = getIndices(cfgFormat,'S1G-STF',osf,N2);
                indLTF1 = getIndices(cfgFormat,'S1G-LTF1',osf,N2);
                indSIGA = getIndices(cfgFormat,'S1G-SIG-A',osf,N2);
                indDSTF = getIndices(cfgFormat,'S1G-DSTF',osf,N2);
                indDLTF = getIndices(cfgFormat,'S1G-DLTF',osf,N2,numLTF);
                indSIGB = getIndices(cfgFormat,'S1G-SIG-B',osf,N2,numLTF);
                if  any(cfgFormat.APEPLength == 0)
                    indS1GData = zeros(0,2,'uint32');
                else
                    indS1GData = getIndices(cfgFormat,'S1G-Data',osf,N2,numLTF,symLength);
                end
                % Fields which are not present in S1G long
                indSIG = zeros(0,2,'uint32');
                indLTF2N = zeros(0,2,'uint32');
            end
            % Create common structure for all S1G modes
            indices = struct(...
                'S1GSTF',  indSTF, ...
                'S1GLTF1', indLTF1, ...
                'S1GSIG',  indSIG, ...
                'S1GSIGA', indSIGA, ...
                'S1GLTF2N',indLTF2N, ...
                'S1GDSTF', indDSTF, ...
                'S1GDLTF', indDLTF, ...
                'S1GSIGB', indSIGB, ...
                'S1GData', indS1GData);

        elseif isa(cfgFormat, 'wlanVHTConfig')
            [numVHTLTF, symLength, N20] = getVHTParams(cfgFormat,osf);
            indLSTF    = getIndices(cfgFormat,'L-STF',osf,N20);
            indLLTF    = getIndices(cfgFormat,'L-LTF',osf,N20);
            indLSIG    = getIndices(cfgFormat,'L-SIG',osf,N20);
            indVHTSIGA = getIndices(cfgFormat,'VHT-SIG-A',osf,N20);
            indVHTSTF  = getIndices(cfgFormat,'VHT-STF',osf,N20);
            indVHTLTF  = getIndices(cfgFormat,'VHT-LTF',osf,N20,numVHTLTF);
            indVHTSIGB = getIndices(cfgFormat,'VHT-SIG-B',osf,N20,numVHTLTF);
            if  isscalar(cfgFormat.APEPLength) && (cfgFormat.APEPLength == 0)
                indVHTData = zeros(0,2,'uint32');
            else
                indVHTData = getIndices(cfgFormat,'VHT-Data',osf,N20,numVHTLTF,symLength);
            end
            indices = struct(...
                'LSTF',   indLSTF, ...
                'LLTF',   indLLTF, ...
                'LSIG',   indLSIG, ...
                'VHTSIGA',indVHTSIGA, ...
                'VHTSTF', indVHTSTF, ...
                'VHTLTF', indVHTLTF, ...
                'VHTSIGB',indVHTSIGB, ...
                'VHTData',indVHTData);

        elseif isa(cfgFormat,'wlanHTConfig')
            [numHTLTF, symLength, N20] = getHTParams(cfgFormat,osf);
            indLSTF   = getIndices(cfgFormat,'L-STF',osf,N20);
            indLLTF   = getIndices(cfgFormat,'L-LTF',osf,N20);
            indLSIG   = getIndices(cfgFormat,'L-SIG',osf,N20);
            indHTSIG  = getIndices(cfgFormat,'HT-SIG',osf,N20);
            indHTSTF  = getIndices(cfgFormat,'HT-STF',osf,N20);
            indHTLTF  = getIndices(cfgFormat,'HT-LTF',osf,N20,numHTLTF);
            if (cfgFormat.PSDULength ==0)
                indHTData = zeros(0,2,'uint32');
            else
                indHTData = getIndices(cfgFormat,'HT-Data',osf,N20,numHTLTF,symLength);
            end
            indices = struct(...
                'LSTF',  indLSTF, ...
                'LLTF',  indLLTF, ...
                'LSIG',  indLSIG, ...
                'HTSIG', indHTSIG,...
                'HTSTF', indHTSTF,...
                'HTLTF', indHTLTF,...
                'HTData',indHTData);

        elseif isa(cfgFormat,'wlanNonHTConfig')
            [~,N20] = wlan.internal.cbw2nfft(cfgFormat.ChannelBandwidth);
            indLSTF  = getIndices(cfgFormat,'L-STF',osf,N20);
            indLLTF  = getIndices(cfgFormat,'L-LTF',osf,N20);
            indLSIG  = getIndices(cfgFormat,'L-SIG',osf,N20);
            indNonHTData = getIndices(cfgFormat,'NonHT-Data',osf,N20);

            indices = struct(...
                'LSTF',     indLSTF, ...
                'LLTF',     indLLTF, ...
                'LSIG',     indLSIG, ...
                'NonHTData',indNonHTData);

        elseif isa(cfgFormat,'wlanWURConfig')
            [~,N20] = wlan.internal.cbw2nfft(cfgFormat.ChannelBandwidth);
            indLSTF = getWURIndices(cfgFormat,'L-STF',osf,N20);
            indLLTF = getWURIndices(cfgFormat,'L-LTF',osf,N20);
            indLSIG = getWURIndices(cfgFormat,'L-SIG',osf,N20);
            indBPSKMark1 = getWURIndices(cfgFormat,'BPSK-Mark1',osf,N20);
            indBPSKMark2 = getWURIndices(cfgFormat,'BPSK-Mark2',osf,N20);
            indWURSync = getWURIndices(cfgFormat,'WUR-Sync',osf,N20);
            indWURData = getWURIndices(cfgFormat,'WUR-Data',osf,N20);

            indices = struct(...
                'LSTF',         indLSTF, ...
                'LLTF',         indLLTF, ...
                'LSIG',         indLSIG, ...
                'BPSKMark1',    indBPSKMark1, ...
                'BPSKMark2',    indBPSKMark2, ...
                'WURSync',     indWURSync, ...
                'WURData',     indWURData);

        else
            indSTF = getDMGIndices(cfgFormat,'DMG-STF',osf);
            indCEF = getDMGIndices(cfgFormat,'DMG-CE',osf);
            indHeader = getDMGIndices(cfgFormat,'DMG-Header',osf);
            indData = getDMGIndices(cfgFormat,'DMG-Data',osf);
            indAGC = getDMGIndices(cfgFormat,'DMG-AGC',osf);
            indAGCsf = getDMGIndices(cfgFormat,'DMG-AGCSubfields',osf);
            indTRN = getDMGIndices(cfgFormat,'DMG-TRN',osf);
            indTRNSF = getDMGIndices(cfgFormat,'DMG-TRNSubfields',osf);
            indTRNCE = getDMGIndices(cfgFormat,'DMG-TRNCE',osf);
            indices = struct(...
                'DMGSTF',         indSTF, ...
                'DMGCE',          indCEF, ...
                'DMGHeader',      indHeader, ...
                'DMGData',        indData, ...
                'DMGAGC',         indAGC, ...
                'DMGAGCSubfields',indAGCsf, ...
                'DMGTRN',         indTRN, ...
                'DMGTRNCE',       indTRNCE,...
                'DMGTRNSubfields',indTRNSF);
        end

    else
        % wlanFieldIndices(CFG,FIELDTYPE) or wlanFieldIndices(CFG,FIELDTYPE,NVPAIRS)
        fieldType = varargin{1};
        osf = wlan.internal.parseOSF(varargin{2:end});

        if isa(cfgFormat,'wlanHESUConfig') || isa(cfgFormat,'wlanHEMUConfig') || isa(cfgFormat,'wlanHETBConfig')
            coder.internal.errorIf(~(ischar(fieldType) || (isstring(fieldType) && isscalar(fieldType))) || ...
                                   ~any(strcmpi(fieldType,{'L-STF','L-LTF','L-SIG','RL-SIG','HE-SIG-A','HE-SIG-B','HE-STF','HE-LTF','HE-Data','HE-PE'})), ...
                                   'wlan:wlanFieldIndices:InvalidFieldTypeHE');
            indices = getHEIndices(cfgFormat, osf, fieldType);
        elseif isa(cfgFormat,'wlanEHTMUConfig') || isa(cfgFormat,'wlanEHTTBConfig')
            coder.internal.errorIf(~(ischar(fieldType) || (isstring(fieldType) && isscalar(fieldType))) || ...
                                   ~any(strcmpi(fieldType,{'L-STF','L-LTF','L-SIG','RL-SIG','U-SIG','EHT-SIG','EHT-STF','EHT-LTF','EHT-Data','EHT-PE'})), ...
                                   'wlan:wlanFieldIndices:InvalidFieldTypeEHT');
            indices = getEHTIndices(cfgFormat, osf, fieldType);
        elseif isa(cfgFormat,'wlanHERecoveryConfig')
            % Check if there are uninitialized properties in the recovery
            % object which are common in both HE-SU and HE-MU format
            wlan.internal.validateParam('CHANBW', cfgFormat.ChannelBandwidth, mfilename);
            indices = getHEIndices(cfgFormat, osf, fieldType);
        elseif isa(cfgFormat,'wlanEHTRecoveryConfig')
            % Check if there are uninitialized properties in the recovery object
            wlan.internal.validateParam('EHTCHANBW', cfgFormat.ChannelBandwidth, mfilename);
            indices = getEHTIndices(cfgFormat, osf, fieldType);
        elseif isa(cfgFormat, 'wlanS1GConfig')
            coder.internal.errorIf(~(ischar(fieldType) || (isstring(fieldType) && isscalar(fieldType))) || ...
                                   ~any(strcmpi(fieldType,{'S1G-STF','S1G-LTF1','S1G-SIG','S1G-SIG-A','S1G-LTF2N','S1G-DSTF','S1G-DLTF','S1G-SIG-B','S1G-Data'})), ...
                                   'wlan:wlanFieldIndices:InvalidFieldTypeS1G');
            if strcmpi(fieldType, 'S1G-Data') && any(cfgFormat.APEPLength == 0)
                indices = zeros(0,2,'uint32'); % NDP
            else
                [numLTF, symLength, N2] = getS1GParams(cfgFormat, osf);
                if strcmpi(fieldType, 'S1G-LTF2N') && (numLTF == 1)
                    indices = zeros(0,2,'uint32'); % No LTF2N field
                else
                    indices = getIndices(cfgFormat, fieldType, osf, N2, numLTF, symLength);
                end
            end
        elseif isa(cfgFormat, 'wlanVHTConfig')
            coder.internal.errorIf(~(ischar(fieldType) || (isstring(fieldType) && isscalar(fieldType))) || ...
                                   ~any(strcmpi(fieldType,{'L-STF','L-LTF','L-SIG','VHT-SIG-A','VHT-STF','VHT-LTF','VHT-SIG-B','VHT-Data'})), ...
                                   'wlan:wlanFieldIndices:InvalidFieldTypeVHT');
            if strcmpi(fieldType, 'VHT-Data') && isscalar(cfgFormat.APEPLength) && (cfgFormat.APEPLength == 0)
                indices = zeros(0,2,'uint32'); % NDP
            else
                [numVHTLTF, symLength, N20] = getVHTParams(cfgFormat, osf);
                indices = getIndices(cfgFormat, fieldType, osf, N20, numVHTLTF, symLength);
            end
        elseif isa(cfgFormat,'wlanHTConfig')
            coder.internal.errorIf(~(ischar(fieldType) || (isstring(fieldType) && isscalar(fieldType))) || ...
                                   ~any(strcmpi(fieldType,{'L-STF','L-LTF','L-SIG','HT-SIG','HT-STF','HT-LTF','HT-Data'})),'wlan:wlanFieldIndices:InvalidFieldTypeHT');
            if strcmpi(fieldType, 'HT-Data') && (cfgFormat.PSDULength == 0)
                indices = zeros(0,2,'uint32'); % NDP
            else
                [numHTLTF, symLength, N20] = getHTParams(cfgFormat, osf);
                indices = getIndices(cfgFormat, fieldType, osf ,N20, numHTLTF, symLength);
            end
        elseif isa(cfgFormat,'wlanDMGConfig')
            coder.internal.errorIf(~(ischar(fieldType) || (isstring(fieldType) && isscalar(fieldType))) || ...
                                   ~any(strcmpi(fieldType,{'DMG-STF','DMG-CE','DMG-Header','DMG-Data','DMG-AGC','DMG-TRN','DMG-AGCSubfields','DMG-TRNSubfields','DMG-TRNCE'})), ...
                                   'wlan:wlanFieldIndices:InvalidFieldTypeDMG');
            indices = getDMGIndices(cfgFormat, fieldType, osf);
        elseif isa(cfgFormat,'wlanWURConfig')
            coder.internal.errorIf(~(ischar(fieldType) || (isstring(fieldType) && isscalar(fieldType))) || ...
                                   ~any(strcmpi(fieldType,{'L-STF','L-LTF','L-SIG','BPSK-Mark1','BPSK-Mark2','WUR-Sync','WUR-Data'})),'wlan:wlanFieldIndices:InvalidFieldTypeWUR');
            [~,N20] = wlan.internal.cbw2nfft(cfgFormat.ChannelBandwidth);
            indices = getWURIndices(cfgFormat, fieldType, osf, N20);
        else % wlanNonHTConfig
            coder.internal.errorIf(~(ischar(fieldType) || (isstring(fieldType) && isscalar(fieldType))) || ...
                                   ~any(strcmpi(fieldType,{'L-STF','L-LTF','L-SIG','NonHT-Data'})),'wlan:wlanFieldIndices:InvalidFieldTypeNonHT');
            [~,N20] = wlan.internal.cbw2nfft(cfgFormat.ChannelBandwidth);
            indices = getIndices(cfgFormat, fieldType, osf, N20);
        end

    end
end

function out = getIndices(format, fieldType, N20, osf, varargin)

    N20 = N20*osf;

    % Start and end sample indices are relative to the field length in samples
    % for 20MHz bandwidth ('VHT','HT', and 'nonHT') and 2MHz bandwidth ('S1G')
    if strcmpi(fieldType, 'S1G-STF')
        indStart = 1;                 % Start of S1G-STF field
        indEnd = 160*N20;             % End of S1G-STF field
    elseif strcmpi(fieldType, 'L-STF')
        indStart = 1;                 % Start of L-STF field
        indEnd = 160*N20;             % End of L-STF field
    elseif strcmpi(fieldType, 'S1G-LTF1')
        indStart = 160*N20+1;         % Start of S1G-LTF1 field
        indEnd = 320*N20;             % End of S1G-LTF1 field
    elseif strcmpi(fieldType, 'L-LTF')
        indStart = 160*N20+1;         % Start of L-LTF field
        indEnd = 320*N20;             % End of L-LTF field
    elseif strcmpi(fieldType, 'S1G-SIG')
        if isa(format,'wlanS1GConfig') && ~strcmp(packetFormat(format),'S1G-Long')
            indStart = 320*N20+1;         % Start of S1G-SIG field
            if strcmp(format.ChannelBandwidth, 'CBW1') % End of S1G-SIG field
                indEnd = indStart+240*N20-1;
            else
                indEnd = indStart+160*N20-1;
            end
        else
            indStart = 0;
            indEnd = 0;
        end
    elseif strcmpi(fieldType, 'S1G-SIG-A')
        if isa(format,'wlanS1GConfig') && strcmp(packetFormat(format),'S1G-Long')
            indStart = 320*N20+1;         % Start of S1G-SIG-A field
            indEnd = indStart+160*N20-1;  % End of S1G-SIG-A field
        else
            indStart = 0;
            indEnd = 0;
        end
    elseif strcmpi(fieldType, 'L-SIG')
        indStart = 320*N20+1;         % Start of L-SIG field
        indEnd = indStart+80*N20-1;   % End of L-SIG field
    elseif strcmpi(fieldType, 'VHT-SIG-A')
        indStart = 400*N20+1;         % Start of VHT-SIG-A field
        indEnd = indStart+160*N20-1;  % End of VHT-SIG-A field
    elseif strcmpi(fieldType, 'HT-SIG')
        indStart = 400*N20+1;         % Start of HT-SIG field
        indEnd = indStart+160*N20-1;  % End of HT-SIG field
    elseif strcmpi(fieldType, 'S1G-DSTF')
        if isa(format,'wlanS1GConfig') && strcmp(packetFormat(format),'S1G-Long')
            indStart = 480*N20+1;         % Start of S1G-DSTF field
            indEnd = indStart+80*N20-1;   % End of S1G-DSTF field
        else
            indStart = 0;
            indEnd = 0;
        end
    elseif strcmpi(fieldType, 'VHT-STF')
        indStart = 560*N20+1;         % Start of VHT-STF field
        indEnd = indStart+80*N20-1;   % End of VHT-STF field
    elseif strcmpi(fieldType, 'HT-STF')
        indStart = 560*N20+1;         % Start of HT-STF field
        indEnd = indStart+80*N20-1;   % End of HT-STF field
    elseif strcmpi(fieldType, 'S1G-LTF2N')
        if isa(format,'wlanS1GConfig') && ~strcmp(packetFormat(format),'S1G-Long')
            numLTF = varargin{1};
            if strcmp(format.ChannelBandwidth, 'CBW1')
                indStart = 560*N20+1;
                indEnd = indStart+(numLTF-1)*40*N20-1;
            else
                indStart = 480*N20+1;
                indEnd = indStart+(numLTF-1)*80*N20-1;
            end
        else
            indStart = 0;
            indEnd = 0;
        end
    elseif strcmpi(fieldType, 'S1G-DLTF')
        if isa(format,'wlanS1GConfig') && strcmp(packetFormat(format),'S1G-Long')
            numLTF = varargin{1};
            indStart = 560*N20+1;                 % Start of S1G-DLTF field
            indEnd = indStart+numLTF*80*N20-1;    % End of S1G-DLTF field
        else
            indStart = 0;
            indEnd = 0;
        end
    elseif strcmpi(fieldType, 'VHT-LTF')
        numVHTLTF = varargin{1};
        indStart = 640*N20+1;                 % Start of VHT-LTF field
        indEnd = indStart+numVHTLTF*80*N20-1; % End of VHT-LTF field
    elseif strcmpi(fieldType, 'HT-LTF')
        numHTLTF = varargin{1};
        validateConfig(format, 'EssSTS');
        indStart = 640*N20+1;                 % Start of HT-LTF field
        indEnd = indStart+numHTLTF*80*N20-1;  % End of HT-LTF field
    elseif strcmpi(fieldType, 'S1G-SIG-B')
        if isa(format,'wlanS1GConfig') && strcmp(packetFormat(format),'S1G-Long')
            numLTF = varargin{1};
            indStart = (560+numLTF*80)*N20+1; % Start of S1G-SIG-B field
            indEnd = indStart+80*N20-1;       % End of S1G-SIG-B field
        else
            indStart = 0;
            indEnd = 0;
        end
    elseif strcmpi(fieldType, 'VHT-SIG-B')
        numVHTLTF = varargin{1};
        indStart = (640+numVHTLTF*80)*N20+1;  % Start of VHT-SIG-B field
        indEnd = indStart+80*N20-1;           % End of VHT-SIG-B field
    elseif strcmpi(fieldType, 'S1G-Data')
        S = validateConfig(format, 'MCS');
        numLTF = varargin{1};
        symLength = varargin{2};
        if isa(format,'wlanS1GConfig') && strcmp(packetFormat(format),'S1G-1M') % Start of S1G-Data field
            indStart = (560+(numLTF-1)*40)*N20+1;
        elseif isa(format,'wlanS1GConfig') && strcmp(packetFormat(format),'S1G-Short')
            indStart = (480+(numLTF-1)*80)*N20+1;
        else % S1G-Long
            indStart = (640+numLTF*80)*N20+1;
        end
        if numel(symLength)>1                 % End of S1G-Data field
            indEnd = indStart+symLength(1)+(S.NumDataSymbols-1)*symLength(2)-1;
        else
            indEnd = indStart+S.NumDataSymbols*symLength-1;
        end
    elseif strcmpi(fieldType, 'VHT-Data')
        S = validateConfig(format, 'MCS');
        numVHTLTF = varargin{1};
        symLength = varargin{2};
        indStart = (720+numVHTLTF*80)*N20+1;            % Start of VHT-Data field
        indEnd = indStart+S.NumDataSymbols*symLength-1; % End of VHT-Data field
    elseif strcmpi(fieldType, 'HT-Data')
        numHTLTF = varargin{1};
        symLength = varargin{2};
        validateConfig(format, 'EssSTS');
        validateConfig(format, 'MCSSTSTx');
        S = validateConfig(format, 'MCS');
        indStart = (640+numHTLTF*80)*N20+1;             % Start of HT-Data field
        indEnd = indStart+S.NumDataSymbols*symLength-1; % End of HT-Data field
    else % strcmpi(fieldType, 'NonHT-Data')
        symLength = 80*N20;
        S = validateConfig(format, 'Full');
        indStart = 400*N20+1; % Start of NonHT-Data field
                              % End of NonHT-Data field
        indEnd = indStart+S.NumDataSymbols*symLength-1;
    end

    % For S1G fields not defined in the evaluated S1G mode
    if all(indStart == 0) && all(indEnd == 0)
        out = zeros(0,2,'uint32');
    else
        catInd = [indStart indEnd];
        validateIndices(catInd, osf, fieldType);
        out = uint32(catInd);
    end

end

function out = getDMGIndices(varargin)
    tmpOut = getDMGIndicesRaw(varargin{:});

    % If the end index is less than the start then return empty indices to
    % indicate field not present
    if ~isempty(tmpOut) && tmpOut(end)<tmpOut(1)
        out = zeros(0,2,'uint32');
    else
        out = tmpOut;
    end
end

function ind = getHEIndices(cfg,osf,varargin)

    preHESIGBIndices = false; % Do not return indices for pre-HE-SIGB
    if isa(cfg,'wlanHERecoveryConfig')
        % There are two conditions:
        % 1) Pre-HE Field indices. We return this when we know nothing about
        % the waveform except the channel bandwidth and that it is one of
        % the HE formats
        % 2) all HE field indices. We know all the data required
        if strcmp(cfg.PacketFormat,'Unknown') || cfg.LSIGLength==-1 || ...
                cfg.LDPCExtraSymbol==-1 || cfg.PreFECPaddingFactor==-1 || ...
                cfg.PEDisambiguity==-1 || cfg.GuardInterval==-1 || ...
                cfg.HELTFType==-1 || cfg.NumHELTFSymbols==-1
            preHESIGBIndices = true;
            trc = wlan.internal.heTimingRelatedConstants(3.2,4,4); % Use defaults
        else
            trc = wlan.internal.heTimingRelatedConstants(cfg.GuardInterval,cfg.HELTFType,cfg.PreFECPaddingFactor);
        end
        pktFormat = cfg.PacketFormat;
    else
        trc = wlan.internal.heTimingRelatedConstants(cfg.GuardInterval,cfg.HELTFType,4); % Use default preFEC padding factor
        pktFormat = packetFormat(cfg);
    end

    isaHETBConfig = isa(cfg,'wlanHETBConfig');
    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
    sf = cbw*osf*1e-3; % Scaling factor to convert bandwidth and time in ns to samples

    % L-STF
    nFieldSamples = trc.TLSTF*sf;
    indLSTF = [1 nFieldSamples];
    validateIndices(indLSTF,osf,'L-STF');
    numCumSamples = nFieldSamples;

    if nargin>2 && strcmp(varargin{1},'L-STF')
        ind = uint32(indLSTF);
        return;
    end

    % L-LTF
    nFieldSamples = trc.TLLTF*sf;
    indLLTF = [numCumSamples+1 numCumSamples+nFieldSamples];
    validateIndices(indLLTF,osf,'L-LTF');
    numCumSamples = numCumSamples+nFieldSamples;
    nFieldSamples = trc.TLSIG*sf;

    if nargin>2 && strcmp(varargin{1},'L-LTF')
        ind = uint32(indLLTF);
        return;
    end

    % L-SIG
    indLSIG = [numCumSamples+1 numCumSamples+nFieldSamples];
    validateIndices(indLSIG,osf,'L-SIG');
    numCumSamples = numCumSamples+nFieldSamples;
    if nargin>2 && strcmp(varargin{1},'L-SIG')
        ind = uint32(indLSIG);
        return;
    end

    nFieldSamples = trc.TRLSIG*sf;
    indRLSIG = [numCumSamples+1 numCumSamples+nFieldSamples];
    validateIndices(indRLSIG,osf,'RL-SIG');
    numCumSamples = numCumSamples+nFieldSamples;
    if nargin>2 && strcmp(varargin{1},'RL-SIG')
        ind = uint32(indRLSIG);
        return;
    end

    % HE-SIG-A
    if strcmp(pktFormat,'HE-EXT-SU') || ...
            (strcmp(pktFormat,'Unknown') && cbw==20) % If unknown return longest
        nFieldSamples = trc.THESIGAR*sf;
    else
        nFieldSamples = trc.THESIGA*sf;
    end
    indHESIGA = [numCumSamples+1 numCumSamples+nFieldSamples];
    validateIndices(indHESIGA,osf,'HE-SIG-A');
    numCumSamples = numCumSamples+nFieldSamples;

    if nargin>2 && strcmp(varargin{1},'HE-SIG-A')
        ind = uint32(indHESIGA);
        return;
    end

    % HE-SIG-B
    if isa(cfg,'wlanHEMUConfig')
        validateConfig(cfg,'HESIGB'); % Validate HE-SIG-B DCM, MCS and number of symbols
        sigbInfo = wlan.internal.heSIGBCodingInfo(cfg);
        nFieldSamples = trc.THESIGB*sigbInfo.NumSymbols*sf;
        indHESIGB = [numCumSamples+1 numCumSamples+nFieldSamples];
    elseif isa(cfg,'wlanHERecoveryConfig')
        if preHESIGBIndices || ~strcmp(pktFormat,'HE-MU')
            nFieldSamples = 0;
            indHESIGB = zeros(0,2);
        else
            s = getSIGBLength(cfg);
            % Calculate the number of HE-SIG-B symbols
            if s.NumSIGBSymbols==-1
                % The HE-SIG-B field length is unknown when the decoded
                % NumSIGBSymbolsSignaled is equal to 16 and the
                % number of users per content is unknown
                preHESIGBIndices = true;
                indHESIGB = zeros(0,2);
                nFieldSamples = 0;
            else
                nFieldSamples = trc.THESIGB*s.NumSIGBSymbols*sf;
                indHESIGB = [numCumSamples+1 numCumSamples+nFieldSamples];
            end
        end
    else
        % Trigger or SU
        nFieldSamples = 0;
        indHESIGB = zeros(0,2);
    end
    numCumSamples = numCumSamples+nFieldSamples;
    validateIndices(indHESIGB,osf,'HE-SIG-B');
    if nargin>2 && strcmp(varargin{1},'HE-SIG-B')
        ind = uint32(indHESIGB);
        return;
    end

    % HE-STF
    % SU or MU
    if isa(cfg,'wlanHERecoveryConfig') && preHESIGBIndices
        indHESTF = zeros(0,2);
    elseif isaHETBConfig
        nFieldSamples = trc.THESTFT*sf;
        indHESTF = [numCumSamples+1 numCumSamples+nFieldSamples];
        numCumSamples = numCumSamples+nFieldSamples;
    else
        nFieldSamples = trc.THESTFNT*sf;
        indHESTF = [numCumSamples+1 numCumSamples+nFieldSamples];
        numCumSamples = numCumSamples+nFieldSamples;
    end
    validateIndices(indHESTF,osf,'HE-STF');
    if nargin>2 && strcmp(varargin{1},'HE-STF')
        ind = uint32(indHESTF);
        return;
    end

    % HE-LTF
    if isa(cfg,'wlanHERecoveryConfig')
        numLTFSym = 0; % For codegen
        if ~preHESIGBIndices
            numLTFSym = cfg.NumHELTFSymbols;
            validateConfig(cfg,'HELTFGI');
        end
    elseif isaHETBConfig
        validateConfig(cfg,'HELTFGI'); % Validate GuardInterval and HELTFType type
        numLTFSym = cfg.NumHELTFSymbols;
    else
        validateConfig(cfg,'HELTFGI'); % Validate GuardInterval and HELTFType type
        allocInfo = ruInfo(cfg);
        numLTFSym = wlan.internal.numVHTLTFSymbols(max(allocInfo.NumSpaceTimeStreamsPerRU));
    end
    if isa(cfg,'wlanHERecoveryConfig') && preHESIGBIndices
        indHELTFPre = zeros(0,2);
    else
        nFieldSamples = trc.THELTFSYM*numLTFSym*sf;
        indHELTFPre = [numCumSamples+1 numCumSamples+nFieldSamples];
        numCumSamples = numCumSamples+nFieldSamples;
    end

    validateIndices(indHELTFPre,osf,'HE-LTF');
    if nargin>2 && strcmp(varargin{1},'HE-LTF') && ~cfg.HighDoppler
        ind = uint32(indHELTFPre);
        return;
    end

    % HE-Data and Midamble
    if isa(cfg,'wlanHESUConfig') && (cfg.APEPLength == 0) || (isa(cfg,'wlanHERecoveryConfig') && preHESIGBIndices)
        indHEData = zeros(0,2); % NDP
        indHELTF = indHELTFPre;
    else
        % Validate parameters for data field location and length
        s = validateConfig(cfg,'DataLocationLength');
        Nsym = s.NumDataSymbols; % Number of data symbols
                                 % Obtain timing related constants for PE field
        if isa(cfg,'wlanHERecoveryConfig')
            trc.TPE = s.TPE*1e3; % Convert TPE into ns
        end
        if Nsym==0 % Nsym==0 due to LSIGLength in wlanHERecoveryConfig
            indHEData = zeros(0,2); % NDP
            indHELTF = indHELTFPre;
        else
            THEDATA = Nsym*trc.TSYM;
            nFieldSamples = round(THEDATA*sf);
            Mma = cfg.MidamblePeriodicity;
            if isaHETBConfig
                [trc,~,Nma] = wlan.internal.heTBTimingRelatedConstants(cfg);
            else
                Nma = wlan.internal.numMidamblePeriods(cfg,Nsym); % Midamble period
            end
            if Nma>0
                symLen = nFieldSamples/Nsym; % Single data symbol length in samples
                HELTFSymLength = trc.THELTFSYM*numLTFSym*sf; % Single HELTF symbol length in samples

                lastDataSyms = Nsym-Nma*Mma; % Number of data symbols after last midamble
                                             % Data indices
                indHEDataStart = numCumSamples+(0:Mma*symLen+HELTFSymLength:(Mma*symLen+HELTFSymLength)*Nma).'+1;
                indHEDataEnd = numCumSamples+(0:Mma*symLen+HELTFSymLength:(Mma*symLen+HELTFSymLength)*Nma).'+[Mma*symLen*ones(1,Nma) lastDataSyms*symLen].';
                indHEData = [indHEDataStart indHEDataEnd];

                % Midamble indices
                indHEMidambleStart = numCumSamples+(Mma*symLen:Mma*symLen+HELTFSymLength:(Mma*symLen+HELTFSymLength)*Nma).'+1;
                indHEMidambleEnd = numCumSamples+(Mma*symLen:Mma*symLen+HELTFSymLength:(Mma*symLen+HELTFSymLength)*Nma).'+HELTFSymLength;
                indMidamble = [indHEMidambleStart indHEMidambleEnd];

                % Append preamble HELTF with midamble HELTF
                indHELTF = [indHELTFPre; indMidamble];
            else
                indHELTF = indHELTFPre;
                indHEData = [numCumSamples+1 numCumSamples+nFieldSamples];
            end
            numCumSamples = numCumSamples+nFieldSamples;
        end
    end

    % HE-PE
    % Recalculate timing related constants to get TPE
    if ~isa(cfg,'wlanHERecoveryConfig') && ~isaHETBConfig
        commonCodingParams = wlan.internal.heCodingParameters(cfg);
        npp = wlan.internal.heNominalPacketPadding(cfg);
        trc = wlan.internal.heTimingRelatedConstants(cfg.GuardInterval,cfg.HELTFType,commonCodingParams.PreFECPaddingFactor,npp,commonCodingParams.NSYM);
    end
    nFieldSamples = trc.TPE*sf;

    if trc.TPE~=0 && ~(isa(cfg,'wlanHERecoveryConfig') && preHESIGBIndices)
        indHEPE = [numCumSamples+1 numCumSamples+nFieldSamples];
    else
        indHEPE = zeros(0,2);
    end

    validateIndices(indHELTF,osf,'HE-LTF');
    if nargin>2 && strcmp(varargin{1},'HE-LTF')
        ind = uint32(indHELTF);
        return;
    end

    validateIndices(indHEData,osf,'HE-Data');
    if nargin>2 && strcmp(varargin{1},'HE-Data')
        ind = uint32(indHEData);
        return;
    end

    validateIndices(indHEPE,osf,'HE-PE');
    if nargin>2 % Return indices of HE-PE field
        ind = uint32(indHEPE);
        return;
    end

    % Return indices for all fields
    indField = struct;
    indField.LSTF = uint32(indLSTF);
    indField.LLTF = uint32(indLLTF);
    indField.LSIG = uint32(indLSIG);
    indField.RLSIG = uint32(indRLSIG);
    indField.HESIGA = uint32(indHESIGA);
    indField.HESIGB = uint32(indHESIGB);
    indField.HESTF = uint32(indHESTF);
    indField.HELTF = uint32(indHELTF);
    indField.HEData = uint32(indHEData);
    indField.HEPE = uint32(indHEPE);
    ind = indField;

end

function ind = getEHTIndices(cfg,osf,varargin)
%getEHTIndices Get field indices of EHT MU packet

    isEHTTB = isa(cfg,'wlanEHTTBConfig');
    preEHTSIGIndices = false; % Do not return indices for pre-EHTSIG fields
    isEHTRec = isa(cfg,'wlanEHTRecoveryConfig');
    if isEHTRec
        % There are two conditions:
        % 1) Pre-EHT Field indices. We return this when we know nothing about
        % the waveform except the channel bandwidth
        % 2) all EHT field indices. We know all the data required
        isNDP = cfg.PPDUType==wlan.type.EHTPPDUType.ndp;
        if isNDP
            % NumEHTSIGSymbolsSignaled is known after U-SIG. GuardInterval, EHTLTFType, and NumEHTLTFSymbols are known after EHT-SIG recovery
            if cfg.NumEHTSIGSymbolsSignaled==-1 || cfg.GuardInterval==-1 || cfg.EHTLTFType==-1 || cfg.NumEHTLTFSymbols==-1
                preEHTSIGIndices = true;
                trc = wlan.internal.ehtTimingRelatedConstants(cfg.ChannelBandwidth,3.2,4,4,0); % Use defaults for NDP (NumDataSymbols==0)
            else
                trc = wlan.internal.ehtTimingRelatedConstants(cfg.ChannelBandwidth,cfg.GuardInterval,cfg.EHTLTFType,4); % Use default preFEC padding factor as there is no EHT-Data field in NDP
            end
        elseif cfg.PreFECPaddingFactor==-1 || cfg.NumEHTLTFSymbols==-1 || cfg.LSIGLength==-1 || cfg.PEDisambiguity==-1 || cfg.LDPCExtraSymbol==-1 ...
                || cfg.GuardInterval==-1 || cfg.EHTLTFType==-1 || cfg.NumEHTSIGSymbolsSignaled==-1 || cfg.PPDUType==wlan.type.EHTPPDUType.unknown
            preEHTSIGIndices = true;
            trc = wlan.internal.ehtTimingRelatedConstants(cfg.ChannelBandwidth,3.2,4,4); % Use defaults
        else
            trc = wlan.internal.ehtTimingRelatedConstants(cfg.ChannelBandwidth,cfg.GuardInterval,cfg.EHTLTFType,cfg.PreFECPaddingFactor); % Use default preFEC padding factor
        end
    else
        trc = wlan.internal.ehtTimingRelatedConstants(cfg.ChannelBandwidth,cfg.GuardInterval,cfg.EHTLTFType,4); % Use default preFEC padding factor
    end
    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
    sf = cbw*osf*1e-3; % Scaling factor to convert bandwidth and time in ns to samples

    % L-STF
    nFieldSamples = trc.TLSTF*sf;
    indLSTF = [1 nFieldSamples];
    numCumSamples = nFieldSamples;
    validateIndices(indLSTF,osf,'L-STF');
    if nargin>2 && strcmpi(varargin{1},'L-STF')
        ind = uint32(indLSTF);
        return;
    end

    % L-LTF
    nFieldSamples = trc.TLLTF*sf;
    indLLTF = [numCumSamples+1 numCumSamples+nFieldSamples];
    numCumSamples = numCumSamples+nFieldSamples;
    validateIndices(indLLTF,osf,'L-LTF');
    if nargin>2 && strcmpi(varargin{1},'L-LTF')
        ind = uint32(indLLTF);
        return;
    end

    % L-SIG
    nFieldSamples = trc.TLSIG*sf;
    indLSIG = [numCumSamples+1 numCumSamples+nFieldSamples];
    numCumSamples = numCumSamples+nFieldSamples;
    validateIndices(indLSIG,osf,'L-SIG');
    if nargin>2 && strcmpi(varargin{1},'L-SIG')
        ind = uint32(indLSIG);
        return;
    end

    % RL-SIG
    nFieldSamples = trc.TRLSIG*sf;
    indRLSIG = [numCumSamples+1 numCumSamples+nFieldSamples];
    numCumSamples = numCumSamples+nFieldSamples;
    validateIndices(indRLSIG,osf,'RL-SIG');
    if nargin>2 && strcmpi(varargin{1},'RL-SIG')
        ind = uint32(indRLSIG);
        return;
    end

    % U-SIG
    nFieldSamples = trc.TUSIG*sf;
    indUSIG = [numCumSamples+1 numCumSamples+nFieldSamples];
    numCumSamples = numCumSamples+nFieldSamples;
    validateIndices(indUSIG,osf,'U-SIG');
    if nargin>2 && strcmpi(varargin{1},'U-SIG')
        ind = uint32(indUSIG);
        return;
    end

    % EHT-SIG
    if isEHTTB
        nFieldSamples = 0;
        indEHTSIG = zeros(0,2);
    elseif isEHTRec
        if preEHTSIGIndices && cfg.NumEHTSIGSymbolsSignaled==-1
            indEHTSIG = zeros(0,2);
            nFieldSamples = 0;
        else
            nFieldSamples = trc.TEHTSIG*(cfg.NumEHTSIGSymbolsSignaled)*sf;
            indEHTSIG = [numCumSamples+1 numCumSamples+nFieldSamples];
        end
    else
        sigInfo = wlan.internal.ehtSIGCodingInfo(cfg);
        numEHTSIGSymbols = sigInfo.NumSIGSymbols;
        validateConfig(cfg,'NumEHTSIGSymbols'); % Validate the number of EHT-SIG symbols
        nFieldSamples = trc.TEHTSIG*numEHTSIGSymbols*sf;
        indEHTSIG = [numCumSamples+1 numCumSamples+nFieldSamples];
    end
    numCumSamples = numCumSamples+nFieldSamples;
    validateIndices(indEHTSIG,osf,'EHT-SIG');
    if nargin>2 && strcmpi(varargin{1},'EHT-SIG')
        ind = uint32(indEHTSIG);
        return;
    end

    % EHT-STF
    if isEHTTB
        nFieldSamples = trc.TEHTSTFT*sf;
        indEHTSTF = [numCumSamples+1 numCumSamples+nFieldSamples];
    elseif isEHTRec && preEHTSIGIndices && cfg.NumEHTSIGSymbolsSignaled==-1
        % EHT-STF field indices are empty if NumEHTSIGSymbolsSignaled is unknown
        indEHTSTF = zeros(0,2);
    else
        nFieldSamples = trc.TEHTSTFNT*sf;
        indEHTSTF = [numCumSamples+1 numCumSamples+nFieldSamples];
    end

    numCumSamples = numCumSamples+nFieldSamples;
    validateIndices(indEHTSTF,osf,'EHT-STF');
    if nargin>2 && strcmpi(varargin{1},'EHT-STF')
        ind = uint32(indEHTSTF);
        return;
    end

    % EHT-LTF
    if isEHTRec
        numLTFSym = 0; % For codegen
        if ~preEHTSIGIndices
            validateConfig(cfg,'EHTLTFGI'); % Validate GuardInterval and EHTLTFType type
            numLTFSym = cfg.NumEHTLTFSymbols;
        end
    else
        validateConfig(cfg,'EHTLTFGI'); % Validate GuardInterval and EHTLTFType type
        validateConfig(cfg,'EHTMCS15'); % Validate MCS-15
        if isEHTTB
            numLTFSym = cfg.NumEHTLTFSymbols;
        else
            validateConfig(cfg,'ExtraEHTLTFSymbols'); % Validate extra EHT-LTF symbols
            validateConfig(cfg,'EHTDUPMode'); % Validate EHT DUP mode
            allocInfo = ruInfo(cfg);
            numLTFSym = wlan.internal.numVHTLTFSymbols(max(allocInfo.NumSpaceTimeStreamsPerRU))+cfg.NumExtraEHTLTFSymbols;
        end
    end

    if isEHTRec && preEHTSIGIndices && cfg.GuardInterval==-1
        % EHT-LTF field indices are empty if the subfields listed in
        % Table 36-33, 36-36, 36-37 of IEEE P802.11be/D5.0 are unknown.
        indEHTLTF = zeros(0,2);
    else
        nFieldSamples = trc.TEHTLTFSYM*numLTFSym*sf;
        indEHTLTF = [numCumSamples+1 numCumSamples+nFieldSamples];
        numCumSamples = numCumSamples+nFieldSamples;
        validateIndices(indEHTLTF,osf,'EHT-LTF');
    end
    if nargin>2 && strcmpi(varargin{1},'EHT-LTF')
        ind = uint32(indEHTLTF);
        return;
    end

    % EHT-Data
    if isEHTRec && preEHTSIGIndices
        indEHTData = zeros(0,2);
    else
        if ~isEHTRec
            % Validate ChannelCoding for BCC. Validation is not required
            % for signal recovery as coding parameters are not required in
            % Equation 36-95 and 36-96 of IEEE P802.11be/D5.0.
            validateConfig(cfg,'Coding');
        end
        s = validateConfig(cfg,'DataLocationLength'); % Validate parameters for data field location and length
        Nsym = s.NumDataSymbols; % Number of data symbols
        if Nsym==0 % NDP
            indEHTData = zeros(0,2); % NDP
        else
            TEHTDATA = Nsym*trc.TSYM;
            nFieldSamples = TEHTDATA*sf;
            indEHTData = [numCumSamples+1 numCumSamples+nFieldSamples];
            numCumSamples = numCumSamples+nFieldSamples;
        end
    end

    validateIndices(indEHTData,osf,'EHT-Data');
    if nargin>2 && strcmpi(varargin{1},'EHT-Data')
        ind = uint32(indEHTData);
        return;
    end

    % EHT-PE
    % Calculate number of PE samples
    if isEHTRec && preEHTSIGIndices
        indEHTPE = zeros(0,2);
    else
        coder.assumeDefined(s);
        nFieldSamples = s.TPE*1000*sf; % Convert time in seconds to samples
        if s.TPE~=0
            indEHTPE = [numCumSamples+1 numCumSamples+nFieldSamples];
        else
            indEHTPE = zeros(0,2);
        end
        validateIndices(indEHTPE,osf,'EHT-PE');
    end

    if nargin>2 % Indices for EHT-PE field
        ind = uint32(indEHTPE);
        return;
    end

    % Return indices for all fields
    indField = struct;
    indField.LSTF = uint32(indLSTF);
    indField.LLTF = uint32(indLLTF);
    indField.LSIG = uint32(indLSIG);
    indField.RLSIG = uint32(indRLSIG);
    indField.USIG = uint32(indUSIG);
    indField.EHTSIG = uint32(indEHTSIG);
    indField.EHTSTF = uint32(indEHTSTF);
    indField.EHTLTF = uint32(indEHTLTF);
    indField.EHTData = uint32(indEHTData);
    indField.EHTPE = uint32(indEHTPE);
    ind = indField;
end

function out = getDMGIndicesRaw(format, fieldType, osf)
    coder.varsize('indStart','indEnd',[64 1],[1 0]);

    if strcmpi(fieldType, 'DMG-STF')
        indStart = 1;
        switch phyType(format)
          case 'Control'
            fieldLength = 128*50;
          case 'OFDM'
            fieldLength = 128*17*(3/2);
          otherwise % SC
            fieldLength = 128*17;
        end
        indEnd = indStart+fieldLength*osf-1;
    elseif strcmpi(fieldType, 'DMG-CE')
        prevInd = getDMGIndicesRaw(format,'DMG-STF',osf); % Previous field
        indStart = double(prevInd(2))+1;
        if strcmp(phyType(format),'OFDM')
            fieldLength = 128*9*(3/2);
        else % Control/SC
            fieldLength = 128*9;
        end
        indEnd = indStart+fieldLength*osf-1;
    elseif strcmpi(fieldType, 'DMG-Header')
        prevInd = getDMGIndicesRaw(format,'DMG-CE',osf); % Previous field
        indStart = double(prevInd(2))+1;
        switch phyType(format)
          case 'Control'
            fieldLength = 8192;
          case 'OFDM'
            fieldLength = 512+(512/4);
          otherwise % SC
            fieldLength = 1024;
        end
        indEnd = indStart+fieldLength*osf-1;
    elseif strcmpi(fieldType, 'DMG-Data')
        prevInd = getDMGIndicesRaw(format,'DMG-Header',osf); % Previous field
        indStart = double(prevInd(2))+1;
        validateConfig(format,'Length');
        switch phyType(format)
          case 'Control'
            parms = wlan.internal.dmgControlEncodingInfo(format);
            fieldLength = (11*8+(format.PSDULength-6)*8+parms.NCW*168)*32-8192;
          case 'OFDM'
            parms = wlan.internal.dmgOFDMEncodingInfo(format);
            fieldLength = parms.NSYM*(512+(512/4));
          otherwise % SC
            parms = wlan.internal.dmgSCEncodingInfo(format);
            fieldLength = (parms.NBLKS*512+64);
        end
        indEnd = indStart+fieldLength*osf-1;
    elseif strcmpi(fieldType, 'DMG-AGC')
        prevInd = getDMGIndicesRaw(format,'DMG-Data',osf); % Previous field
        indStart = double(prevInd(2))+1;
        if wlan.internal.isBRPPacket(format)
            numTRN = format.TrainingLength;
        else
            numTRN = 0;
        end
        if strcmp(phyType(format),'OFDM')
            fieldLength = 320*(3/2)*numTRN;
        else % Control/SC
            fieldLength = 320*numTRN;
        end
        indEnd = indStart+fieldLength*osf-1;

    elseif strcmpi(fieldType, 'DMG-AGCSubfields')
        prevInd = getDMGIndicesRaw(format,'DMG-Data',osf); % Previous field
        fieldStart = double(prevInd(2))+1;
        if wlan.internal.isBRPPacket(format)
            numTRN = format.TrainingLength;
        else
            numTRN = 0;
        end
        if strcmp(phyType(format),'OFDM')
            fieldLength = 320*(3/2);
        else % Control/SC
            fieldLength = 320;
        end
        indStart = fieldStart+(0:fieldLength*osf:(fieldLength*osf*numTRN)-1).';
        indEnd = indStart+fieldLength*osf-1;
    elseif strcmpi(fieldType, 'DMG-TRN')
        prevInd = getDMGIndicesRaw(format,'DMG-AGC',osf); % Previous field
        indStart = double(prevInd(2))+1;
        if wlan.internal.isBRPPacket(format)
            numTRNUnits = format.TrainingLength/4;
        else
            numTRNUnits = 0;
        end
        if strcmp(phyType(format),'OFDM')
            fieldLength = (3/2)*(640*4+1152)*numTRNUnits;
        else % Control/SC
            fieldLength = (640*4+1152)*numTRNUnits;
        end
        indEnd = indStart+fieldLength*osf-1;
    elseif strcmpi(fieldType, 'DMG-TRNSubfields')
        agcInd = getDMGIndicesRaw(format,'DMG-AGC',osf); % Previous field
        fieldStart = double(agcInd(2))+1;
        if strcmp(phyType(format),'OFDM')
            NumCESamples = 1152*(3/2);
            fieldLength = 640*(3/2);
        else % Control/SC
            NumCESamples = 1152;
            fieldLength = 640;
        end
        if wlan.internal.isBRPPacket(format)
            numTRN = format.TrainingLength;
        else
            numTRN = 0;
        end
        indStart = fieldStart+(NumCESamples*osf*ceil((1:numTRN).'/4))+(0:fieldLength*osf:(fieldLength*osf*numTRN-1)).';
        indEnd = indStart+fieldLength*osf-1;
    else % strcmpi(fieldType, 'DMG-TRNCE')
        agcInd = getDMGIndicesRaw(format,'DMG-AGC',osf); % Previous field
        fieldStart = double(agcInd(2))+1;
        if strcmp(phyType(format),'OFDM')
            fieldLength = 1152*(3/2);
            numTRNSamples = 640*4*(3/2);
        else % Control/SC
            fieldLength = 1152;
            numTRNSamples = 640*4;
        end
        if wlan.internal.isBRPPacket(format)
            numTRNUnits = format.TrainingLength/4;
        else
            numTRNUnits = 0;
        end
        indStart = fieldStart+((fieldLength+numTRNSamples)*osf*((1:(numTRNUnits)).'-1));
        indEnd = indStart+fieldLength*osf-1;
    end
    catInd = [indStart indEnd];
    validateIndices(catInd,osf,fieldType);
    out = uint32(catInd);

end

function out = getWURIndices(format, fieldType, osf, N20)
    N20 = N20*osf;
    coder.varsize('indStart','indEnd',[4 1],[1 0]); % For codegen
    if strcmpi(fieldType, 'L-STF')
        indStart = 1;                 % Start of L-STF field
        indEnd = 160*N20;             % End of L-STF field
    elseif strcmpi(fieldType, 'L-LTF')
        indStart = 160*N20+1;         % Start of L-LTF field
        indEnd = 320*N20;             % End of L-LTF field
    elseif strcmpi(fieldType, 'L-SIG')
        indStart = 320*N20+1;         % Start of L-SIG field
        indEnd = indStart+80*N20-1;   % End of L-SIG field
    elseif strcmpi(fieldType, 'BPSK-Mark1')
        indStart = 400*N20+1;         % Start of WUR BPSK-Mark1 field
        indEnd = indStart+80*N20-1;   % End of WUR BPSK-Mark1 field
    elseif strcmpi(fieldType, 'BPSK-Mark2')
        indStart = 480*N20+1;         % Start of WUR BPSK-Mark2 field
        indEnd = indStart+80*N20-1;   % End of WUR BPSK-Mark2 field
    elseif strcmpi(fieldType, 'WUR-Sync')
        indStart = zeros(format.NumUsers,1);
        indEnd = zeros(format.NumUsers,1);
        activeSubchannelIndex = getActiveSubchannelIndex(format);
        for i=1:format.NumUsers
            indStart(i) = 560*N20+1;         % Start of WUR Sync field
            if strcmpi(format.Subchannel{activeSubchannelIndex(i)}.DataRate,'LDR')
                indEnd(i) = indStart(i)+2560*N20-1;   % End of WUR LDR Sync field
            else % HDR Sync
                indEnd(i) = indStart(i)+1280*N20-1;   % End of WUR HDR Sync field
            end
        end
    else % WUR-Data
        indStart = zeros(format.NumUsers,1);
        indEnd = zeros(format.NumUsers,1);
        params = wlan.internal.wurTxTime(format);
        for i=1:format.NumUsers
            if strcmpi(format.Subchannel{params.ActiveSubchannels(i)}.DataRate,'LDR')
                indStart(i) = 3120*N20+1;         % Start of WUR LDR Data field
                indEnd(i) = indStart(i)+80*N20*params.NSYM(params.ActiveSubchannels(i))-1;   % End of WUR LDR Data field
            else % HDR Data
                indStart(i) = 1840*N20+1;         % Start of WUR HDR Data field
                indEnd(i) = indStart(i)+40*N20*params.NSYM(params.ActiveSubchannels(i))-1;   % End of WUR HDR Data field
            end
        end
    end

    catInd = [indStart indEnd];
    validateIndices(catInd,osf,fieldType);
    out = uint32(catInd);

end

function [numLTF, symLength, N2MHz] = getS1GParams(format,osf)

    channelBandwidth = format.ChannelBandwidth;
    numSTSTotal = sum(format.NumSpaceTimeStreams);
    numLTF = wlan.internal.numVHTLTFSymbols(numSTSTotal);

    if strcmp(channelBandwidth,'CBW1')
        N2MHz = 1;
        FFTLen = 32 * N2MHz * osf; % FFT length for S1G 1MHz
    else
        N2MHz = wlan.internal.cbwStr2Num(channelBandwidth)/2;
        FFTLen = 64 * N2MHz * osf; % FFT length for 2MHz bandwidth
    end

    if strcmp(format.GuardInterval,'Short')
        % Short symbol length for 2MHz bandwidth,
        % 1st symbol with long GuardInterval and rest with short GuardInterval
        symLength = [FFTLen * 5/4 FFTLen * 9/8];
    else
        % Long symbol length for 2MHz bandwidth
        symLength = FFTLen * 5/4;
    end

end

function [numLTF, symLength, N20MHz] = getVHTParams(format,osf)

    channelBandwidth = format.ChannelBandwidth;
    numSTSTotal = sum(format.NumSpaceTimeStreams);
    numLTF = wlan.internal.numVHTLTFSymbols(numSTSTotal);

    N20MHz = wlan.internal.cbwStr2Num(channelBandwidth)/20;
    FFTLen = 64 * N20MHz *osf; % FFT length for 20MHz bandwidth

    if strcmp(format.GuardInterval,'Short')
        % Short symbol length for 20MHz bandwidth
        symLength = FFTLen * 9/8;
    else
        % Long symbol length for 20MHz bandwidth
        symLength = FFTLen * 5/4;
    end

end

function [numLTF, symLength, N20MHz] = getHTParams(format,osf)

    chanBW = format.ChannelBandwidth;
    if wlan.internal.inESSMode(format)
        numESS = format.NumExtensionStreams;
    else
        numESS = 0;
    end

    numLTF = wlan.internal.numVHTLTFSymbols(format.NumSpaceTimeStreams) + wlan.internal.numHTELTFSymbols(numESS);

    N20MHz = wlan.internal.cbwStr2Num(chanBW)/20;
    FFTLen = 64 * N20MHz * osf; % FFT length for 20MHz bandwidth

    if strcmp(format.GuardInterval,'Short')
        % Short symbol length for 20MHz bandwidth
        symLength = FFTLen * 9/8;
    else
        % Long symbol length for 20MHz bandwidth
        symLength = FFTLen * 5/4;
    end

end

function validateIndices(indices,osf,varargin)
    if osf==1
        % No need to validate
        return
    end
    if ~isempty(indices)
        fieldLength = indices(2)-indices(1);
        field = varargin{1};
        if any(floor(fieldLength)~=fieldLength)
            coder.internal.error('wlan:wlanFieldIndices:InvalidOSF',sprintf('%f',osf),field,round((fieldLength+1)/osf));
        end
    end
end
