function respMCS = responseMCS(obj, frameFormat, chanWidth, aggregatedMPDU, ...
    mcs, numSTS)
%responseMCS Return the MCS to be used for sending response frame
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   RESPMCS = responseMCS(OBJ, FRAMEFORMAT, CHANWIDTH, AGGREGATEDMPDU, MCS,
%   NUMSTS) returns the MCS index to be used for the response frame.
%
%   RESPMCS is an integer specifying the MCS index for the response frame.
%   In case of MU transmission, it is a vector with values corresponding to
%   each user.
%
%   OBJ is the MAC layer object, of type edcaMAC.
%
%   FRAMEFORMAT is the PHY format of the frame soliciting the response,
%   specified as a constant value defined in wlan.internal.FrameFormats.
%
%   CHANWIDTH is an integer specifying the channel bandwidth of the frame
%   soliciting the response.
%
%   AGGREGATEDMPDU is the flag indicating if the frame soliciting the
%   response is aggregated.
%
%   MCS is the MCS index of the frame soliciting the response. In case of
%   MU transmission, it is a vector with values corresponding to each user.
%
%   NUMSTS is an integer representing the number of space-time streams
%   used for the frame soliciting the response.

%   Copyright 2022-2025 The MathWorks, Inc.

cbw = wlan.internal.utils.getChannelBandwidthStr(chanWidth);

switch frameFormat
    case obj.NonHT
        respMCS = max(obj.NonHTMCSIndicesForBasicRates(obj.NonHTMCSIndicesForBasicRates <= mcs));

    case obj.HTMixed
        htConfig = obj.HTConfig; % Copy into local variable for performance
        htConfig.ChannelBandwidth = cbw;
        htConfig.AggregatedMPDU = aggregatedMPDU;
        htConfig.MCS = mcs;
        htConfig.NumTransmitAntennas = numSTS; % Set as NumSTS for validation
        htConfig.NumSpaceTimeStreams = numSTS;

        r = wlan.internal.getRateTable(htConfig);
        symbolTime = 4; % in microseconds
        rxRate = r.NDBPS/symbolTime;
        % Response frame MCS
        respMCS = max(obj.NonHTMCSIndicesForBasicRates(obj.BasicRates <= rxRate));

    case obj.VHT
        vhtConfig = obj.VHTConfig;
        vhtConfig.ChannelBandwidth = cbw;
        vhtConfig.MCS = mcs;
        vhtConfig.NumTransmitAntennas = numSTS; % Set as NumSTS for validation
        vhtConfig.NumSpaceTimeStreams = numSTS;

        r = wlan.internal.getRateTable(vhtConfig);
        symbolTime = 4; % in microseconds
        rxRate = r.NDBPS(1)/symbolTime;
        % Response frame MCS
        respMCS = max(obj.NonHTMCSIndicesForBasicRates(obj.BasicRates <= rxRate));

    case {obj.HE_SU, obj.HE_EXT_SU}
        heSUConfig = obj.HESUConfig;
        heSUConfig.ChannelBandwidth = cbw;
        heSUConfig.MCS = mcs;
        heSUConfig.ExtendedRange = (frameFormat == obj.HE_EXT_SU);
        heSUConfig.NumTransmitAntennas = numSTS; % Set as NumSTS for validation
        heSUConfig.NumSpaceTimeStreams = numSTS;

        assert(heSUConfig.STBC==false,'STBC not supported')
        r = wlan.internal.heRateDependentParameters(ruInfo(heSUConfig).RUSizes,mcs,numSTS,heSUConfig.DCM);
        switch heSUConfig.GuardInterval
            case 3.2
                symbolTime = 16; % in microseconds
            case 1.6
                symbolTime = 14.4; % in microseconds
            otherwise % 0.8
                symbolTime = 13.6; % in microseconds
        end
        rxRate = r.NDBPS/symbolTime;
        % Response frame MCS
        respMCS = max(obj.NonHTMCSIndicesForBasicRates(obj.BasicRates <= rxRate));

    case obj.EHT_SU
        ehtSUConfig = wlanEHTMUConfig(cbw);
        ehtSUConfig.User{1}.MCS = mcs;
        ehtSUConfig.User{1}.NumSpaceTimeStreams = numSTS;
        ehtSUConfig.NumTransmitAntennas = numSTS;
        r = wlan.internal.heRateDependentParameters(ruInfo(ehtSUConfig).RUSizes{1},mcs,numSTS,false);
        switch ehtSUConfig.GuardInterval
            case 3.2
                symbolTime = 16; % in microseconds
            case 1.6
                symbolTime = 14.4; % in microseconds
            otherwise % 0.8
                symbolTime = 13.6; % in microseconds
        end
        rxRate = r.NDBPS/symbolTime;
        % Response frame MCS
        respMCS = max(obj.NonHTMCSIndicesForBasicRates(obj.BasicRates <= rxRate));

    case obj.HE_TB
        rxRates = zeros(obj.Tx.NumTxUsers, 1);

        % Compute rates at which UL HE TB frames are received
        for userIdx = 1:obj.Tx.NumTxUsers
            % Fill user specific fields
            obj.ULTBSysCfg.User{userIdx}.NumTransmitAntennas = numSTS(userIdx);
            obj.ULTBSysCfg.User{userIdx}.NumSpaceTimeStreams = numSTS(userIdx);
            obj.ULTBSysCfg.User{userIdx}.MCS = mcs(userIdx);
        end

        % Get HE-TB configuration objects for all users
        cfgTB = getUserConfig(obj.ULTBSysCfg);

        % Get data rates corresponding to each uplink user
        for userIdx = 1:obj.Tx.NumTxUsers
            switch cfgTB{userIdx}.GuardInterval
                case 3.2
                    symbolTime = 16; % in microseconds
                case 1.6
                    symbolTime = 14.4; % in microseconds
                otherwise % 0.8
                    symbolTime = 13.6; % in microseconds
            end
            [~, r] = wlan.internal.heCodingParameters(cfgTB{userIdx});
            rxRates(userIdx) = r.NDBPS/symbolTime;
        end

        minRxRate = min(rxRates); % Min of all uplink data rates
        respMCS = max(obj.NonHTMCSIndicesForBasicRates(obj.BasicRates <= minRxRate));

        % If the data rate of frame soliciting response is less than 6Mbps,
        % use 6Mbps for response frame.
        if isempty(respMCS)
            respMCS = obj.NonHTMCSIndex6Mbps;
        end

    otherwise % HE-MU format
        cfgMU = obj.Tx.CfgHEMU;

        cfgMU.NumTransmitAntennas = numSTS(obj.UserIndexSU);
        for idx = 1:numel(cfgMU.User)
            cfgMU.User{idx}.MCS = mcs(idx);
            % All users assumed to have same number of space-time streams
            cfgMU.User{idx}.NumSpaceTimeStreams = numSTS(idx);
        end
        [~, r] = wlan.internal.heCodingParameters(cfgMU);
        switch cfgMU.GuardInterval
            case 3.2
                symbolTime = 16; % in microseconds
            case 1.6
                symbolTime = 14.4; % in microseconds
            otherwise % 0.8
                symbolTime = 13.6; % in microseconds
        end
        respMCS = zeros(numel(cfgMU.User), 1);
        for userIdx = 1:numel(cfgMU.User)
            rxRate = r(userIdx).NDBPS/symbolTime;
            mcsIdx = max(obj.NonHTMCSIndicesForBasicRates(obj.BasicRates <= rxRate));
            % If rxRate is less than 6 Mbps, mcsIdx will be empty. Assign
            % 6 Mbps in this case.
            if isempty(mcsIdx)
                mcsIdx = obj.NonHTMCSIndex6Mbps;
            end
            respMCS(userIdx) = mcsIdx;
        end
end
end
