function bits = s1gSignalingBits(cfgS1G)
%s1gSignalingBits S1G signaling bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   BITS = s1gSignalingBits(CFGS1G) generates the signaling bits for a
%   given configuration.
%
%   BITS is the signaling bits used for the S1G SIGNAL field. It is a
%   binary column vector.
%
%   CFGS1G is the format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a> which
%   specifies the parameters for the S1G format.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

if strcmp(cfgS1G.ChannelBandwidth,'CBW1')
    % 1 MHz mode
    bits = s1g1MSignalingBits(cfgS1G);
else % {'CBW2','CBW4','CBW8','CBW16'}
    if strcmp(cfgS1G.Preamble,'Short')
        bits = s1gShortSignalingBits(cfgS1G);
    else % Long
        if cfgS1G.NumUsers>1 % MU
            bits = s1gLongMUSignalingBits(cfgS1G);
        else % SU: cfgS1G.NumUsers==1
            bits = s1gLongSUSignalingBits(cfgS1G);
        end
    end
end
end

% Table 24-11 Fields in the SIG field of short preamble, IEEE P802.11ah/D5.0
function bits = s1gShortSignalingBits(cfgS1G)
    % SIG1
    b0 = 1; % reserved
    
    % STBC
    b1 = cfgS1G.STBC;
    
    % Uplink indication
    b2 = cfgS1G.UplinkIndication;

    % Channel bandwidth
    b34 = channelBandwidthBits(cfgS1G.ChannelBandwidth);

    % Nsts
    b56 = int2bit(sum(cfgS1G.NumSpaceTimeStreams)-1,2,false);
    
    % ID
    b715 = idBits(cfgS1G);

    % Short GI
    b16 = strcmp(cfgS1G.GuardInterval,'Short');

    % Channel coding
    b1718 = channelCodingBits();
    
    % MCS
    b1922 = int2bit(cfgS1G.MCS(1),4,false);
    
    % Smoothing
    b23 = cfgS1G.RecommendSmoothing;
    
    % SIG1 structure 
    sig1 = [b0; b1; b2; b34; b56; b715; b16; b1718; b1922; b23];

    % SIG2
    b09 = aggregationLengthBits(cfgS1G);
    
    b1011 = responseIndicationBits(cfgS1G.ResponseIndication);
    
    b12 = cfgS1G.TravelingPilots;
    
    b13 = 0; % NDP Indication bit
    
    % Concatenate the first 0-12 bits of sig2
    sig2 = [b09; b1011; b12; b13];
        
    bits = [sig1; sig2];
end

% Table 24-14 Fields in the SIG-A field of S1G_LONG preamble SU PPDU, IEEE P802.11ah/D5.0
function bits = s1gLongSUSignalingBits(cfgS1G)
    % SIG1
    b0 = 0; % MU/SU, force to single user
    
    % STBC
    b1 = cfgS1G.STBC;
    
    % Uplink indication
    b2 = cfgS1G.UplinkIndication;
    
    % Channel bandwidth
    b34 = channelBandwidthBits(cfgS1G.ChannelBandwidth);

    % Nsts
    b56 = int2bit(sum(cfgS1G.NumSpaceTimeStreams)-1,2,false);
    
    % ID
    b715 = idBits(cfgS1G);

    % Short GI
    b16 = strcmp(cfgS1G.GuardInterval,'Short');

    % Channel coding
    b1718 = channelCodingBits();
    
    % MCS
    b1922 = int2bit(cfgS1G.MCS(1),4,false);

    % Smoothing/Beam change bit    
    if sum(cfgS1G.NumSpaceTimeStreams)==1
        % Beam change signaled for 1 STS
        switch cfgS1G.SpatialMapping
            case 'Custom'
                b23 = cfgS1G.Beamforming; % User value for Beam change
            case 'Direct'
                b23 = false; % No Beam change for Direct
            otherwise % {'Fourier','Hadamard'}
                b23 = true; % Beam change as not direct
        end
    else
        % Recommend smoothing signaled for > 1 STS
        b23 = cfgS1G.RecommendSmoothing;
    end
    
    % SIG1 structure 
    sig1 = [b0; b1; b2; b34; b56; b715; b16; b1718; b1922; b23];

    % SIG2
    b09 = aggregationLengthBits(cfgS1G);
    
    b1011 = responseIndicationBits(cfgS1G.ResponseIndication);
    
    b12 = 1; % Reserved bit 
    
    b13 = cfgS1G.TravelingPilots;
    
    % Concatenate the first 0-12 bits of SIG2
    sig2 = [b09; b1011; b12; b13];
    
    bits = [sig1; sig2];
end

% Table 24-15 Fields in the SIG-A field of S1G_LONG preamble MU PPDU, IEEE P802.11ah/D5.0
function bits = s1gLongMUSignalingBits(cfgS1G)
    % SIG1
    b0 = 1; % MU/SU, force to multi-user
    
    % STBC
    b1 = 0; % No STBC for MU
    
    b2 = 1; % Reserved
    
    % Nsts
    b310 = zeros(8,1);
    for u = 1:cfgS1G.NumUsers
        b310(2*cfgS1G.UserPositions(u)+(1:2).') = int2bit(cfgS1G.NumSpaceTimeStreams(u),2,false);
    end
    
    % Channel bandwidth
    b1112 = channelBandwidthBits(cfgS1G.ChannelBandwidth);

    % ID
    b1318 = int2bit(cfgS1G.GroupID,6,false);
  
    % Short GI
    b19 = strcmp(cfgS1G.GuardInterval,'Short');

    % Channel coding
    b2023 = ones(4, 1);
    for u = 1:cfgS1G.NumUsers
        % Currently assumes only BCC coding. If NSTS is 0 the bit is
        % reserved  true, otherwise it is set to 0 for BCC coding.
        b2023(cfgS1G.UserPositions(u)+1) = cfgS1G.NumSpaceTimeStreams(u)==0;
    end
        
    % SIG1 structure 
    sig1 = [b0; b1; b2; b310; b1112; b1318; b19; b2023];
    
    % SIG2
    b0 = 0; % LDPC related, 0 for BCC
    b1 = 1; % Reserved
    
    % Aggregation is mandatory for MU and when aggregation is used
    % Nsym should be used for length.
    s = validateConfig(cfgS1G,'MCS');
    b210 = int2bit(s.NumDataSymbols,9,false); % Length
    
    b1112 = responseIndicationBits(cfgS1G.ResponseIndication);
       
    b13 = cfgS1G.TravelingPilots;
    
    % Concatenate the first 0-12 bits of SIG2
    sig2 = [b0; b1; b210; b1112; b13];
    
    bits = [sig1; sig2];
end

% Table 24-18 Fields in the SIG field of S1G_1M PPDU, IEEE P802.11ah/D5.0
function bits = s1g1MSignalingBits(cfgS1G)
    % SIG1
    b01 = int2bit(sum(cfgS1G.NumSpaceTimeStreams)-1,2,false);
    b2 = strcmp(cfgS1G.GuardInterval,'Short');
    b34 = channelCodingBits();
    b5 = cfgS1G.STBC;
    
    % SIG2, SIG3 & SIG4
    b6 = 1; % reserved
    b710 = int2bit(cfgS1G.MCS(1),4,false);
    b1120 = aggregationLengthBits(cfgS1G);
    b2122 = responseIndicationBits(cfgS1G.ResponseIndication);
    b23 = cfgS1G.RecommendSmoothing;
    
    % SIG5
    b24 = cfgS1G.TravelingPilots;
    
    b25 = 0; % NDP Indication bit
          
    bits = [b01; b2; b34; b5; b6; b710; b1120; b2122; b23; b24; b25];
end

% Returns 2 bits used to signal response indication
function bits = responseIndicationBits(ResponseIndication)
    switch ResponseIndication
        case 'None'
            riNum = 0;
        case 'NDP'
            riNum = 1;
        case 'Normal'
            riNum = 2;
        otherwise % 'Long'
            riNum = 3;
    end
    bits = int2bit(riNum,2,false); % Response Indication
end

% Returns 10 bits used to signal aggregation and length
function bits = aggregationLengthBits(cfgS1G)
    % Aggregation used for MU or when number of octets in PSDU>511; Section
    % 9.13.5, Transport of A-MPDU by the PHY data service, IEEE
    % P802.11ah/D5.0. Force aggregation true
    b0 = 1; % Aggregation
    s = validateConfig(cfgS1G,'MCS');
    b19 =  int2bit(s.NumDataSymbols,9,false); % Length
    bits = [b0; b19];
end

function bits = channelCodingBits()
    % Channel coding, always BCC
    b1 = 0;
    b2 = 1; % Reserved
    bits = [b1; b2];
end

% Returns 2 bits used to signal channel bandwidth
function bits = channelBandwidthBits(ChannelBandwidth)
    switch ChannelBandwidth
        case 'CBW2'
            cbwNum = 0;
        case 'CBW4'
            cbwNum = 1;
        case 'CBW8'
            cbwNum = 2;
        otherwise % 'CBW16'
            cbwNum = 3;
    end
    bits = int2bit(cbwNum,2,false);
end

% Returns 9 bits used to signal ID
function bits = idBits(cfgS1G)
    % ID
    if cfgS1G.UplinkIndication
        % If UplinkIndication=1 all bits are PARTIAL_AID
        bits = int2bit(cfgS1G.PartialAID,9,false);
    else
        % If UplinkIndication=0, first bits are COLOR, second bits are PARTIAL_AID
        b79 = int2bit(cfgS1G.Color,3,false);
        b1015 = int2bit(cfgS1G.PartialAID,6,false);
        bits = [b79; b1015];
    end
end