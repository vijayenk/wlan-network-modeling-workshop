function [est,ltf,p,nltf] = vhtltfEstimate(sym,chanBW,nsts,ind)
%vhtltfEstimate Channel estimate using the VHT-LTF
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [EST,SEQLTF,P,NUMLTF] = vhtltfEstimate(SYM,CHANBW,NSTS,IND) returns the
%   channel estimate for each subcarrier, the VHT-LTF sequence, P matrix,
%   and required number of VHT-LTF symbols. SYM is the received symbols,
%   CHANBW is the channel bandwidth, NSTS is the number of space-time
%   streams, and IND represents the subcarrier indices to use.

%   Copyright 2015-2022 The MathWorks, Inc.

%#codegen

[ltf,p,nltf] = wlan.internal.vhtltfSequence(chanBW,nsts);

if (nsts==1)
    % If one space time stream then use LS estimation directly
    est = squeeze(sym(:,1,:)) ./ ltf(ind);
    est = permute(est,[1 3 2]);
else               
    % MIMO channel estimation as per Perahia, Eldad, and Robert Stacey.
    % Next Generation Wireless LANs: 802.11 n and 802.11 ac. Cambridge
    % university press, 2013, page 100, Eq 4.39.

    % Verify enough symbols to estimate
    nsym = size(sym,2);
    coder.internal.errorIf(nsym<nltf, ...
        'wlan:wlanChannelEstimate:NotEnoughSymbols',nsts,nltf,nsym);

    % MIMO channel estimate
    est = wlan.internal.mimoChannelEstimate(sym,ltf(ind),nsts);
end

end
