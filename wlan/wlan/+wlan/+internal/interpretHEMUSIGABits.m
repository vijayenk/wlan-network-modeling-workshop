function [cfgMU,failInterpretation] = interpretHEMUSIGABits(sigaBits,cfgMU,varargin)
%interpretHEMUSIGABits Interpret HE-SIG-A bits for HE MU packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [CFGMU,FAILINTERPRETATION] = interpretHEMUSIGABits(SIGABITS,CFGMU)
%   interpret HE-SIG-A bits into HE-SIG-A fields defined in IEEE
%   Std 802.11ax-2021, Table 27-18. When you use this syntax and the function
%   cannot interpret the recovered HE-SIG-A bits due to an unexpected value
%   an exception is issued, and the function does not return an output.
%
%   CFGMU is the format configuration object of type <a href="matlab:help('wlanHERecoveryConfig')">wlanHERecoveryConfig</a>,
%   which specifies the parameters for the recovered HE MU packet. The
%   function returns the updated CFGMU after the interpretation of HE-SIG-A
%   bits.
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
%   interpreted HE-SIG-A bits. SUPPRESSERROR is logical. When SUPPRESSERROR
%   is true and the function cannot interpret the recovered HE-SIG-A bits
%   due to an unexpected value, the function returns FAILINTERPRETATION as
%   true and cfgMU is unchanged. When SUPPRESSERROR is false and the
%   function cannot interpret the recovered HE-SIG-A bits due to an
%   unexpected value, an exception is issued, and the function does not
%   return an output. The default is false.

%   Copyright 2018-2022 The MathWorks, Inc.

%#codegen

nargoutchk(0,2);
suppressError = false; % Control the validation of the interpreted HE-SIG-A bits
failInterpretation = false;
if nargin>2
    suppressError = varargin{1};
end
cfgMUInput = cfgMU; % Copy of the input configuration object

cfgMU.UplinkIndication = sigaBits(1);
cfgMU.SIGBDCM = sigaBits(5);
sigbMCS = bit2int(double(sigaBits(2:4)),3,false);
cfgMU.BSSColor = bit2int(double(sigaBits(6:11)),6,false);
cfgMU.SpatialReuse = bit2int(double(sigaBits(12:15)),4,false);

if suppressError
    if sigbMCS>5
        cfgMU = cfgMUInput; % Return the input object with no change
        failInterpretation = true;
        return
    end
end

cfgMU.SIGBMCS = sigbMCS;
chbwIndication = bit2int(double(sigaBits(16:18)),3,false);
switch chbwIndication
    case 0
        chanBW = 'CBW20';
        preamblePuncturing = 'None'; % Preamble puncturing is not applicable
    case 1
        chanBW = 'CBW40';
        preamblePuncturing = 'None'; % Preamble puncturing is not applicable
    case 2
        chanBW = 'CBW80';
        preamblePuncturing = 'None'; % Preamble puncturing is not applicable
    case 3
        chanBW = 'CBW160';
        preamblePuncturing = 'None'; % Preamble puncturing is not applicable
    case 4
        chanBW = 'CBW80';
        preamblePuncturing = 'Mode-1';
    case 5
        chanBW = 'CBW80';
        preamblePuncturing = 'Mode-2';
    case 6
        chanBW = 'CBW160';
        preamblePuncturing = 'Mode-3';
    otherwise % CBW160
        chanBW = 'CBW160';
        preamblePuncturing = 'Mode-4';
end
cfgMU.PreamblePuncturing = preamblePuncturing;
cfgMU.ChannelBandwidth = chanBW;
cfgMU.SIGBCompression = sigaBits(23);

numSubChannels = 1; %#ok<NASGU> % For codegen
numHESIGBSymbolsRecovered = 0; % For codegen
if cfgMU.SIGBCompression==true
    % Allocation index and number of user are known for SIGB compressed waveform
    numUsers  = bit2int(double(sigaBits(19:22)),4,false)+1; % Number of user in an RU
    if numUsers>8
        if suppressError
            cfgMU = cfgMUInput; % Return the input object with no change
            failInterpretation = true;
            return
        else
            coder.internal.error('wlan:wlanHERecoveryConfig:InvalidNumUsers');
        end
    end
    cfgMU.NumSIGBSymbolsSignaled = -1; % For codegen
    switch chanBW
        case 'CBW20'
            allocationIndex = 191+numUsers;
        case 'CBW40'
            allocationIndex = 199+numUsers;
        case 'CBW80'
            allocationIndex = 207+numUsers;
        otherwise % 160MHz
            allocationIndex = 215+numUsers;
    end
else
    switch chanBW
       case 'CBW20'
            numSubChannels = 1; % Number of HE-SIG-B content channels
        case 'CBW40'
            numSubChannels = 2;
        case 'CBW80'
            numSubChannels = 4;
        otherwise % 160MHz
            numSubChannels = 8;
    end
    numHESIGBSymbolsRecovered = bit2int(double(sigaBits(19:22)),4,false)+1;
    allocationIndex = -1*ones(1,numSubChannels);
    numUsers = -1; % Number of users are unknown
end

cfgMU.AllocationIndex = allocationIndex;

GI = bit2int(double(sigaBits(24:25)),2,false);
switch GI
    case 0
        cfgMU.GuardInterval = 0.8;
        cfgMU.HELTFType = 4;
    case 1
        cfgMU.GuardInterval = 0.8;
        cfgMU.HELTFType = 2;
    case 2
        cfgMU.GuardInterval = 1.6;
        cfgMU.HELTFType = 2;
    otherwise % 3
        cfgMU.GuardInterval = 3.2;
        cfgMU.HELTFType = 4;
end

cfgMU.HighDoppler = sigaBits(26);

cfgMU.TXOPDuration = bit2int(double(sigaBits(27:33)),7,false);

midamblePeriodicity = -1;
if cfgMU.HighDoppler
    numHELTF = bit2int(double(sigaBits(35:36)),2,false);
    switch numHELTF
        case 0
           numHELTFSymbols = 1;
        case 1
           numHELTFSymbols = 2;
        case 2
           numHELTFSymbols = 4;
        otherwise
            if suppressError
                cfgMU = cfgMUInput; % Return the input object with no change
                failInterpretation = true;
                return
            else
                coder.internal.error('wlan:wlanHERecoveryConfig:InvalidHELTFSymbol');
            end
    end
    
    if sigaBits(37)==0
        midamblePeriodicity = 10;
    else
        midamblePeriodicity = 20;
    end
else % No Doppler
    numHELTF = bit2int(double(sigaBits(35:37)),3,false);
    switch numHELTF
        case 0
            numHELTFSymbols = 1;
        case 1
            numHELTFSymbols = 2;
        case 2
            numHELTFSymbols = 4;
        case 3
            numHELTFSymbols = 6;
        case 4
            numHELTFSymbols = 8;
        otherwise
            if suppressError
                cfgMU = cfgMUInput; % Return the input object with no change
                failInterpretation = true;
                return
            else
                coder.internal.error('wlan:wlanHERecoveryConfig:InvalidHELTFSymbol');
            end
    end
end

cfgMU.MidamblePeriodicity = midamblePeriodicity;

cfgMU.NumHELTFSymbols = numHELTFSymbols;

cfgMU.LDPCExtraSymbol = sigaBits(38);

cfgMU.STBC = sigaBits(39);

preFECPaddingFactor = bit2int(double(sigaBits(40:41)),2,false);
switch preFECPaddingFactor
    case 0
        cfgMU.PreFECPaddingFactor = 4;
    case 1
        cfgMU.PreFECPaddingFactor = 1;
    case 2
        cfgMU.PreFECPaddingFactor = 2;
    otherwise % 3
        cfgMU.PreFECPaddingFactor = 3;
end

cfgMU.PEDisambiguity = sigaBits(42);

if cfgMU.SIGBCompression
    % Get the number of users on each signaled 20 MHz subchannel
    if strcmp(chanBW,'CBW20')
        numUsersPer20 = numUsers;
    else
        % Split user fields between two content channels
        numUsersPer20 = coder.nullcopy(zeros(1,2));
        numUsersPer20(1) = ceil(numUsers/2);
        numUsersPer20(2) = numUsers-ceil(numUsers/2);
    end
else
    cfgMU.NumSIGBSymbolsSignaled = numHESIGBSymbolsRecovered(1); % Defined in HE-SIG-A field
    if strcmp(cfgMU.ChannelBandwidth,'CBW20')
        numUsersPer20 = -1; % Unknown
    else
        numUsersPer20 = -1*ones(1,2);
    end
end

cfgMU.NumUsersPerContentChannel = numUsersPer20;

end