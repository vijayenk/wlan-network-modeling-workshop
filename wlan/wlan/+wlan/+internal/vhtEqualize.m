function [eqSym,csi,varargout] = vhtEqualize(sym,chEst,noiseEst,cfg,fieldVal,userIdx)
%vhtEqualize VHT symbol equalization without validation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [eqSym,csi] = wlan.internal.vhtEqualize(...) returns the merged
%   equalized symbols and CSI.
%
%   [...,unmergedEqSym,unmergedCSI] = wlan.internal.vhtEqualize(...) also
%   returns the unmerged equalized symbols and CSI.

%   Copyright 2024-2025 The MathWorks, Inc.

%#codegen
    arguments
        sym
        chEst
        noiseEst
        cfg
        fieldVal
        userIdx
    end
    assert(nargout <= 4,'The max number of possible outputs for wlan.internal.vhtEqualize is 4')
    nsc = size(sym,1);
    [~,numSubchannels] = wlan.internal.cbw2nfft(cfg.ChannelBandwidth);
    nSCUnique = nsc/numSubchannels;

    alg = wlan.internal.determineEqualizerAlgorithm(noiseEst);

    isPreVHT = matches(fieldVal,{'L-SIG','VHT-SIG-A'});

    if isPreVHT
        % Merge repeated subcarriers
        [symMerged,chanEstMerged] = wlan.internal.mergeSubcarriers(sym,chEst,nSCUnique);
        % Equalize data
        [eqSym,csi] = wlan.internal.equalize(symMerged,chanEstMerged,alg,noiseEst);
    elseif matches(fieldVal,'VHT-SIG-B')
        if any(size(chEst,2) == [4 7 8])
            % Perform P-matrix multiplication by negating data subcarriers in 4th and 8th space-time streams
            ofdmInfo = wlan.internal.vhtOFDMInfo(fieldVal,cfg.ChannelBandwidth);
            if nsc == ofdmInfo.NumTones
                chEst(ofdmInfo.DataIndices,4:4:end,:) = -chEst(ofdmInfo.DataIndices,4:4:end,:);
            else
                chEst(:,4:4:end,:) = -chEst(:,4:4:end,:);
            end
        end
        [eqSymAllUsers,csiAllUsers] = wlan.internal.equalize(sym,chEst,alg,noiseEst);
        [eqSym,csi] = wlan.internal.getUserSTS(eqSymAllUsers,csiAllUsers,cfg,userIdx);
        % Merge across space time streams
        eqSym = mean(eqSym,3);
        csi = sum(csi,2);
    elseif matches(fieldVal,"VHT-Data") && cfg.STBC && mod(size(chEst,2),2)==0 % VHT-Data STBC combining. Check that second dimension is even (for codegen)
        nSS = size(chEst,2)/2;
        [eqSym,csi] = wlan.internal.stbcCombine(sym,chEst,nSS,alg,noiseEst);
    else % VHT-Data equalization
        [eqSymAllUsers,csiAllUsers] = wlan.internal.equalize(sym,chEst,alg,noiseEst);
        [eqSym,csi] = wlan.internal.getUserSTS(eqSymAllUsers,csiAllUsers,cfg,userIdx);
    end

    if nargout > 2
        % Provide unmerged symbols and csi if requested
        if isPreVHT
            [varargout{1},varargout{2}] = wlan.internal.equalize(sym,chEst,alg,noiseEst);
        else % No merging happens in VHT portion of packet
            varargout{1} = eqSym;
            varargout{2} = csi;
        end
    end

end
