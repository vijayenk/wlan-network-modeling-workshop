function [cfgSU,failInterpretation] = interpretHESUSIGABits(sigaBits,cfgSU,varargin)
%interpretHESUSIGABits Interpret HE-SIG-A bits for HE SU packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CFGSU = interpretHESUSIGABits(SIGABITS,CFGSU) interpret HE-SIG-A bits
%   into HE-SIG-A fields defined in IEEE Std 802.11ax-2021, Table 27-18.
%   When you use this syntax and the function cannot interpret the
%   recovered HE-SIG-A bits due to an unexpected value an exception is
%   issued, and the function does not return an output.
%
%   CFGSU is the format configuration object of type <a href="matlab:help('wlanHERecoveryConfig')">wlanHERecoveryConfig</a>, 
%   which specifies the parameters for the recovered HE SU and HE ER SU
%   packet. The function returns the updated CFGSU after the interpretation
%   of HE-SIG-A bits.
%
%   FAILINTERPRETATION is a logical scalar and represent the result of
%   interpreting the recovered HE-SIG-A field bits. The function return
%   this as true when it cannot interpret the received HE-SIG-A bits.
%
%   SIGABITS are the int8 column vector of length 52, containing the
%   decoded HE-SIG-A bits.
%
%   [...,FAILINTERPRETATION] = interpretHEMUSIGABits(...,SUPPRESSERROR)
%   controls the behavior of the function due to an unexpected value of the
%   interpreted HE-SIG-A bits. SUPPRESSERROR is logical. When
%   SUPPRESSERROR is true and the function cannot interpret the recovered
%   HE-SIG-A bits due to an unexpected value, the function returns
%   FAILINTERPRETATION as true and cfgSU is unchanged. When SUPPRESSERROR
%   is false and the function cannot interpret the recovered HE-SIG-A bits
%   due to an unexpected value, an exception is issued, and the function
%   does not return an output. The default is false.

%   Copyright 2018-2022 The MathWorks, Inc.

%#codegen

nargoutchk(0,2);
suppressError = false; % Control the validation of the interpreted HE-SIG-A bits
failInterpretation = false;
if nargin>2
    suppressError = varargin{1};
end
cfgSUInput = cfgSU; % Copy of the input configuration object

cfgSU.PreHESpatialMapping = ~sigaBits(2);

cfgSU.UplinkIndication = sigaBits(3);

mcs = bit2int(double(sigaBits(4:7)),4,false);
if suppressError
    if mcs>11
        cfgSU = cfgSUInput; % Return the input object with no change
        failInterpretation = true;
        return
    end
end
cfgSU.MCS = mcs;

% Determine DCM later
cfgSU.BSSColor = bit2int(double(sigaBits(9:14)),6,false);

Reserved1 = sigaBits(15); %#ok<NASGU>

cfgSU.SpatialReuse = bit2int(double(sigaBits(16:19)),4,false);

upper106ToneRU = false; % For codegen
switch cfgSU.PacketFormat
    case 'HE-EXT-SU'
        cfgSU.ChannelBandwidth = 'CBW20';
        upper106ToneRUIndication = bit2int(double(sigaBits(20:21)),2,false);
        switch upper106ToneRUIndication(1)
            case 0
                upper106ToneRU = false;
            case 1
                upper106ToneRU = true;
            otherwise
                if suppressError
                    cfgSU = cfgSUInput; % Return the input object with no change
                    failInterpretation = true;
                    return
                else
                    coder.internal.error('wlan:wlanHERecoveryConfig:InvalidHEEXTSUBandwidth');
                end
        end
    otherwise
        % SU and Trigger
        chbwIndication = bit2int(double(sigaBits(20:21)),2,false);
        switch chbwIndication(1)
            case 0
                cfgSU.ChannelBandwidth = 'CBW20';
            case 1
                cfgSU.ChannelBandwidth = 'CBW40';
            case 2
                cfgSU.ChannelBandwidth = 'CBW80';
            otherwise % 3
                cfgSU.ChannelBandwidth = 'CBW160';
        end
end

cfgSU.DCM = sigaBits(8);

cfgSU.STBC = sigaBits(36);

GI = bit2int(double(sigaBits(22:23)),2,false);
switch GI
    case 0
        cfgSU.GuardInterval = 0.8;
        cfgSU.HELTFType = 1;
    case 1
        cfgSU.GuardInterval = 0.8;
        cfgSU.HELTFType = 2;
    case 2
        cfgSU.GuardInterval = 1.6;
        cfgSU.HELTFType = 2;
    otherwise % 3
        if sigaBits(8)==1 && sigaBits(36)==1 % DCM and STBC
            cfgSU.GuardInterval = 0.8;
            cfgSU.HELTFType = 4;
            cfgSU.DCM = 0; % False
            cfgSU.STBC = 0; % False
        else
            cfgSU.GuardInterval = 3.2;
            cfgSU.HELTFType = 4;
        end
end

cfgSU.TXOPDuration = bit2int(double(sigaBits(27:33)),7,false);

if sigaBits(34)==0
    cfgSU.ChannelCoding = 'BCC';
else
    cfgSU.ChannelCoding = 'LDPC';
end

cfgSU.LDPCExtraSymbol = sigaBits(35);

cfgSU.Beamforming = sigaBits(37);

preFECPaddingFactor = bit2int(double(sigaBits(38:39)),2,false);
switch preFECPaddingFactor
    case 0
        cfgSU.PreFECPaddingFactor = 4;
    case 1
        cfgSU.PreFECPaddingFactor = 1;
    case 2
        cfgSU.PreFECPaddingFactor = 2;
    otherwise % 3
        cfgSU.PreFECPaddingFactor = 3;
end

cfgSU.PEDisambiguity = sigaBits(40);

Reserved2 = logical(sigaBits(41)); %#ok<NASGU>

cfgSU.HighDoppler = sigaBits(42);

midamblePeriodicity = -1; % For codegen
if cfgSU.HighDoppler
    % B23 and B24 represents NumSpaceTimeStreams
    numSpaceTimeStreams = bit2int(double(sigaBits(24:25)),2,false)+1;
    if sigaBits(26)==0
        midamblePeriodicity = 10;
    else
        midamblePeriodicity = 20;
    end
else
    % B23, B24, and B25 represents NumSpaceTimeStreams
    numSpaceTimeStreams = bit2int(double(sigaBits(24:26)),3,false)+1;
end

pktFormatNSTSCheck = strcmp(cfgSU.PacketFormat,'HE-EXT-SU') && numSpaceTimeStreams>2;
if suppressError && pktFormatNSTSCheck
    cfgSU = cfgSUInput;
    failInterpretation = true;
    return
else
    coder.internal.errorIf(pktFormatNSTSCheck,'wlan:wlanHERecoveryConfig:InvalidNumSpaceTimeStreamsHEEXTSU',numSpaceTimeStreams);
end

cfgSU.NumSpaceTimeStreams = numSpaceTimeStreams;
cfgSU.MidamblePeriodicity = midamblePeriodicity;

ruIndex = 1;
switch cfgSU.ChannelBandwidth
    case 'CBW20'
        if (strcmp(cfgSU.PacketFormat,'HE-EXT-SU') && upper106ToneRU==true)
            ruSize = 106;
            ruIndex = 2;
        else
            ruSize = 242;
        end
    case 'CBW40'
        ruSize = 484;
    case 'CBW80'
        ruSize = 996;
    otherwise % 'CBW160'
        ruSize = 2*996;
end

Nheltf = wlan.internal.numVHTLTFSymbols(cfgSU.NumSpaceTimeStreams);
cfgSU.NumHELTFSymbols = Nheltf;
cfgSU.RUSize = ruSize;
cfgSU.RUIndex = ruIndex;

% For codegen
cfgSU.AllocationIndex = -1;
cfgSU.LowerCenter26ToneRU = -1;
cfgSU.UpperCenter26ToneRU = -1;
cfgSU.NumUsersPerContentChannel = -1;

end