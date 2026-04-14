function [bits,failCRC,varargout] = wlanEHTSIGUserBitRecover(x,nVar,varargin)
%wlanEHTSIGUserBitRecover Recover user field bits from EHT-SIG field
%   [BITS,FAILCRC,CFG] = wlanEHTSIGUserBitRecover(X,NVAR,CFG) recovers the
%   EHT-SIG user field bits given the EHT-SIG field from an EHT MU
%   transmission, the noise variance estimate, and the EHT configuration
%   object of type wlanEHTRecoveryConfig. When you use this syntax and
%   the function cannot interpret the recovered EHT-SIG user field bits due
%   to an unexpected value, an exception is issued, and the function does
%   not return an output.
%
%   BITS is an int8 matrix of size 22-by-NumUsers, where NumUsers is the
%   number of users in the transmission, containing the recovered user
%   field bits for all users. The function only returns BITS if it can
%   decode the corresponding content channel.
%
%   For an OFDMA configuration where the same users are signaled in all 80
%   MHz subblocks, BITS is an int8 matrix of size 22-by-NumUsers, where
%   NumUsers is the number of users in an 80 MHz subblock.
%
%   FAILCRC represents the result of the CRC for each user. It is true if
%   the user fails the CRC. It is a logical row vector of size
%   1-by-NumUsers.
%
%   For an OFDMA configuration where the same users are signaled in all 80
%   MHz subblocks, FAILCRC is a logical row vector of size 1-by-NumUsers,
%   where NumUsers is the number of users in an 80 MHz subblock.
%
%   Returned CFG is a cell array of size 1-by-NumUsers. CFG is the updated
%   format configuration object after EHT-SIG user field decoding, of type
%   wlanEHTRecoveryConfig. The updated format configuration object CFG
%   is only returned for the users who pass the CRC.
%
%   For an OFDMA configuration where the same users are signaled in all 80
%   MHz subblocks the updated format configuration object CFG is returned
%   only for the users who pass the CRC in an 80 MHz subblock.
%
%   [BITS,FAILCRC] = wlanEHTSIGUserBitRecover(...), when you use this
%   syntax and the function cannot interpret the recovered EHT-SIG user
%   field bits due to an unexpected value, no exception is issued.
%
%   X is a vector containing the complex demodulated and equalized EHT-SIG
%   user field symbols. It is of size Nsd-by-Nsym, where Nsd is the
%   number of data subcarriers in EHT-SIG field. Nsym is the number of
%   EHT-SIG field symbols. The size of X depends on the PPDU type and
%   channel bandwidth:
%
%   # For non-OFDMA
%       For bandwidths greater than 40 MHz, X contains the combined 20 MHz
%       subchannel repetitions.
%
%       * For CBW20 Nsd is 52.
%       * For CBW40, CBW80, CBW160, and CBW320. Nsd is 104
%
%   # For OFDMA
%       For bandwidths greater than 80 MHz, X contains the combined
%       content channels within each 80 MHz subblock
%       * For CBW20 Nsd is 52
%       * For CBW40 and CBW80 Nsd is 104
%       * For CBW160 Nsd is 208
%       * For CBW320 Nsd is 416
%
%   NVAR is the noise variance estimate, specified as a nonnegative scalar.
%
%   CFG is a format configuration object of type wlanEHTRecoveryConfig
%   and specifies the parameters for the EHT MU format.
%
%   [...] = wlanEHTSIGUserBitRecover(...,CSI,CFG) uses the channel state
%   information to enhance the demapping of OFDM subcarriers. The CSI input
%   is an Nsd-by-1 column vector of real values, where Nsd is the number of
%   active subcarriers in the EHT-SIG field.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

    narginchk(3,4);
    updateConfig = nargout==3; % Validate the interpreted bit values
    validateattributes(x,{'single','double'},{'2d','finite'},mfilename,'x');
    [nsd,nSym] = size(x);

    if isa(varargin{1},'wlanEHTRecoveryConfig')
        % wlanEHTSIGUserBitRecover(RX,NVAR,CFG)
        csi = ones(nsd,1);
        cfg = varargin{1};
    elseif nargin>3 && isa(varargin{2},'wlanEHTRecoveryConfig')
        % wlanEHTSIGUserBitRecover(RX,NVAR,CSI,CFG)
        csi = varargin{1};
        cfg = varargin{2};
    else
        coder.internal.error('wlan:eht:InvalidConfigType');
    end

    % Validate channel bandwidth
    chanBW = wlan.internal.validateParam('EHTCHANBW',cfg.ChannelBandwidth,mfilename);
    cbw = wlan.internal.cbwStr2Num(chanBW);
    validateConfig(cfg,'EHTSIG');
    coder.internal.errorIf(nSym~=cfg.NumEHTSIGSymbolsSignaled,'wlan:eht:InvalidNumEHTSIGSyms',nSym,cfg.NumEHTSIGSymbolsSignaled);
    coder.internal.errorIf(any(size(csi)~=[nsd 1]),'wlan:he:InvalidCSISize',nsd,1);
    coder.internal.errorIf(cfg.PPDUType==wlan.type.EHTPPDUType.ndp,'wlan:eht:InvalidUsersNDP');

    [~,failInterpretation] = validateConfig(cfg,'EHTLTFGI',updateConfig);
    bits = zeros(22,0,'int8');
    coder.varsize("bits",[22 144],[0 1])
    failCRC = false(1,0);
    coder.varsize("failCRC",[1 144],[0 1]);

    isOFDMA = cfg.PPDUType==wlan.type.EHTPPDUType.dl_ofdma;
    % If any content channel per segment fails for OFDMA or all content channel fail for non-OFDMA then return empty.

    if ~isOFDMA
        coder.internal.assert(isvector(cfg.NumUsersPerContentChannel),'wlan:codegen:NotAVector','NumUsersPerContentChannel')
    end

    if failInterpretation || isOFDMA && any(cfg.NumUsersPerContentChannel==-1,'all') || ~isOFDMA && all(cfg.NumUsersPerContentChannel(1,:)==-1)
        varargout{1} = {}; % Return the input object with no change
        return
    end

    L = wlan.internal.ehtNumSubblocks(cfg.PPDUType,cbw); % Number of 80 MHz subblocks
    params = wlan.internal.ehtSIGRateTable(cfg.EHTSIGMCS);
    mode = cfg.compressionMode;
    c = wlan.internal.ehtSIGCommonFieldInfo(cbw,mode,params.NDBPS,false);
    Nsc = 52; % Number of subcarrier in a single content channel
    Nsb = nsd/L; % Number of subcarriers per 80 MHz subblock
    expectedNumSC = Nsc*c.NumContentChannels*L;
    coder.internal.errorIf(nsd~=expectedNumSC,'wlan:he:InvalidRowLength',expectedNumSC);
    u = wlan.internal.ehtSIGUserFieldInfo;

    % Process valid content channel for non-OFDMA
    invalidContentChannels = false(1,c.NumContentChannels);
    for i=1:c.NumContentChannels
        invalidContentChannels(i) = cfg.NumUsersPerContentChannel(i)==-1;
    end

    if any(mode==[0 2])
        if any(invalidContentChannels) && ~invalidContentChannels(1)
            % Process the first content channel
            startIndex = 1;
            endIndex = 1;
        elseif any(invalidContentChannels) && invalidContentChannels(1)
            % Process the second content channel
            startIndex = 2;
            endIndex = 2;
        else % Process all content channels
            startIndex = 1;
            endIndex = startIndex+double(cbw>20); % Only one content channel in CBW20
        end
    else % EHT SU
        startIndex = 1;
        endIndex = 1;
    end

    ehtSIGInfo = wlan.internal.ehtSIGCodingInfo(cfg);
    % Initialization
    bitsContentCh1 = zeros(22,0,'int8');
    bitsContentCh2 = zeros(22,0,'int8');
    failCRC1 = false(1,0);
    failCRC2 = false(1,0);

    if isOFDMA
        numFirstUserFieldBits = 0;
        userOffset = 0; % No offset as no user is signaled in common field for OFDMA
    else
        numFirstUserFieldBits = u.NumUserFieldBits+u.NumCRCBits+u.NumTailBits;
        userOffset = 1; % Offset due to the first user signaled in EHT common field for non-OFDMA configuration
    end

    %% Process all users
    for l=1:L % Process each 80 MHz subblock
        for cch = startIndex:endIndex % Process each content channel
            subBlkIndex = (1:Nsc)+Nsc*(cch-1) + Nsb*(l-1); % Index of an 80 MHz subblock
            decodeBits = wlan.internal.heSIGBDecode(x(subBlkIndex,:),csi(subBlkIndex,1),nVar,params,cfg.EHTSIGMCS);

            % Common field bits and first user bits
            commonBits = decodeBits(1:ehtSIGInfo.NumCommonFieldBits);
            numUsersInContentChannel = ehtSIGInfo.NumUsersPerSegmentPerContentChannel(l,cch);
            userBits = coder.nullcopy(zeros(u.NumUserFieldBits,numUsersInContentChannel,'int8')); % Pre-allocation bit storage
            oddNumberOfUsers = mod(numUsersInContentChannel-userOffset,2);
            if oddNumberOfUsers
                numPairs = floor((numUsersInContentChannel-1)/2);
                oddbits = decodeBits(ehtSIGInfo.NumCommonFieldBits+numFirstUserFieldBits+numPairs*u.NumUserFieldPairBits+(1:u.NumUserFieldBits+u.NumTailBits+u.NumCRCBits));
            else
                numPairs = floor(numUsersInContentChannel/2); % Extract pairs
                oddbits = zeros(0,1,'int8');
            end
            decodedUserPairs = decodeBits(ehtSIGInfo.NumCommonFieldBits+numFirstUserFieldBits+(1:u.NumUserFieldPairBits*numPairs));
            crcBits = coder.nullcopy(zeros(4,numPairs+oddNumberOfUsers+userOffset,'int8')); % userOffset is added for the first user

            if isOFDMA
                failCRCPerUser = false(1,0); % Reset after processing the content channel
            else
                % The first user is in the common encoding block for non-OFDMA
                firstbits = decodeBits(ehtSIGInfo.NumCommonFieldBits+(1:numFirstUserFieldBits));
                checksum = wlan.internal.crcGenerate([commonBits; firstbits(1:u.NumUserFieldBits,:)]);
                failCRCPerUser = any(checksum(1:4)~=firstbits(u.NumUserFieldBits+(1:u.NumCRCBits),:));
                userBits(:,1) = firstbits(1:u.NumUserFieldBits,:);
                crcBits(:,1) = firstbits(u.NumUserFieldBits+(1:u.NumCRCBits));
            end

            % Reshape so each column is a pair of user fields (excluding any odd number)
            if numPairs~=0
                decodedUserBlock = reshape(decodedUserPairs,u.NumUserFieldPairBits,numPairs); % 54-by-numPairs
                userBits(:,1+userOffset:userOffset+numPairs*2) = reshape(decodedUserBlock(1:u.NumUserFieldBits*2,:),u.NumUserFieldBits,[]);
                crcBits(:,1+userOffset:userOffset+numPairs) = decodedUserBlock(u.NumUserFieldBits*2+(1:u.NumCRCBits),:);
                % Test checksums for pairs
                for ip=1:numPairs
                    checksum = wlan.internal.crcGenerate(decodedUserBlock(1:u.NumUserFieldBits*2,ip),8);
                    commonUserBlockError = any(checksum(1:4)~=crcBits(:,userOffset+ip)); % 1 is added for the first user
                                                                                         % Same CRC for both users in a pair
                    failCRCPerUser = [failCRCPerUser repmat(commonUserBlockError,1,2)]; %#ok<AGROW>
                end
            end

            if oddNumberOfUsers
                % If odd number of users, add the final user
                userBits(:,numUsersInContentChannel) = oddbits(1:u.NumUserFieldBits);
                crcBits(:,numPairs+1+userOffset) = oddbits(u.NumUserFieldBits+(1:u.NumCRCBits)); % userOffset is added for the first user in non-OFDMA
                                                                                                 % Test checksum for final user
                checksum = wlan.internal.crcGenerate(userBits(:,numUsersInContentChannel),8);
                commonUserBlockError = any(checksum(1:4)~=crcBits(:,numPairs+1+userOffset)); % userOffset is added for the first user in non-OFDMA
                                                                                             % Append CRC for the last user
                failCRCPerUser = [failCRCPerUser commonUserBlockError]; %#ok<AGROW>
            end

            if cch==1
                bitsContentCh1 = userBits;
                failCRC1 = failCRCPerUser;
            else
                bitsContentCh2 = userBits;
                failCRC2 = failCRCPerUser;
            end
        end
        bits = [bits bitsContentCh1 bitsContentCh2]; %#ok<AGROW> % EHT-SIG user field bits
        failCRC = [failCRC failCRC1 failCRC2]; %#ok<AGROW> % CRC for all user
    end

    % For 160/320 MHz, when the same users are signaled in all 80 MHz
    % subblocks than only return users from a single subblock which has least
    % number of users which fail the CRC.
    if isOFDMA && ~cfg.UsersSignaledInSingleSubblock && size(unique(cfg.AllocationIndex,'rows'),1)==1
        [rows,col] = size(bits);
        bitsTemp = reshape(bits,rows,col/L,L); % Bits-by-NumUsers-by-L
        failCRCTemp = reshape(failCRC,[],L);   % failCRC-by-L
        [~,validIdx] = min(sum(failCRCTemp));  % Get the index of the 80 MHz subblock which has minimum number of CRC failures per user
        bits = bitsTemp(:,:,validIdx);         % Extract bits for the relevant 80 MHz subblock
        failCRC = failCRCTemp(:,validIdx).';   % Extract failCRC for the relevant 80 MHz subblock
    end

    if updateConfig
        if all(failCRC,'all')
            % If CRC fails for all users or if there are no users within an RU
            varargout{1} = {};
        else
            varargout{1} = wlan.internal.interpretEHTSIGUserBits(bits,failCRC,cfg);
        end
    end
end
