function mcsTable = getRateTable(cfgFormat)
%getRateTable Select the Rate parameters for WLAN formats
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   mcsTable = getRateTable(CFGFORMAT) returns the modulation and coding
%   parameters for the format configuration object CFGFORMAT. 

%   Copyright 2015-2024 The MathWorks, Inc.

% References:
% [1] IEEE Std 802.11ac - 2013.
% [2] "Next Generation Wireless LANs", E. Perahia & R. Stacey, Cambridge
% University Press, 2013. Section 7.4.
% [3] IEEE Std 802.11 - 2012.
% [4] IEEE P802.11-REVme/D6.0, June 2024
% [5] IEEE Std 802.11ad-2012
% [6] IEEE Std 802.11-2016

%#codegen

switch class(cfgFormat)
    case 'wlanVHTConfig' % VHT format   
        switch cfgFormat.ChannelBandwidth
            case 'CBW20'
                NSD = 52;
            case 'CBW40'
                NSD = 108;
            case {'CBW80', 'CBW80+80'}
                NSD = 234;
            otherwise % case 'CBW160'
                NSD = 468;
        end
        mcsTable = getVHTRateTable(cfgFormat, NSD);
    
    case 'wlanS1GConfig' % S1G format   
    
         NSD = wlan.internal.s1gSubcarriersPerSymbol('Data', cfgFormat.ChannelBandwidth);
         mcsTable = getVHTRateTable(cfgFormat, NSD);

         % Force NES=1; Tables 24-38 through 57 in IEEE P802.11ah/D5.0
         mcsTable.NES = ones(size(mcsTable.NES));
    
    case 'wlanHTConfig' % HT-Mixed format

        mcsTable = getHTMCSTable(cfgFormat);
    
    case 'wlanNonHTConfig' % non-HT format, for OFDM
    
        mcsTable = getNonHTMCSTable(cfgFormat.MCS);
    
    case 'wlanDMGConfig' % DMG format
        
        mcsTable = getDMGMCSTable(cfgFormat.MCS);
        
    otherwise % Add other formats

        mcsTable = [];
end

end

%-------------------------------------------------------------------------
function mcsTable = getNonHTMCSTable(mcs)
% Supports data rate values in set of {6, 9, 12, 18, 24, 36, 48, 54} Mbps
% as a fcn of the MCS values.

Nsd = 48;       % Data subcarriers
switch mcs
  case 0 % 6 Mbps
    Nbpscs = 1;  % 'BPSK'
    rate = 1/2;
  case 1 % 9 Mbps
    Nbpscs = 1; 
    rate   = 3/4;
  case 2 % 12 Mbps
    Nbpscs = 2;  % QPSK
    rate   = 1/2;
  case 3 % 18 Mbps
    Nbpscs = 2; 
    rate   = 3/4;
  case 4 % 24 Mbps
    Nbpscs = 4;  % 16QAM 
    rate   = 1/2;
  case 5 % 36 Mbps
    Nbpscs = 4;  
    rate   = 3/4;
  case 6  % 48 Mbps
    Nbpscs = 6;  % '64QAM'
    rate   = 2/3;
  otherwise % 7 => 54 Mbps
    Nbpscs = 6;
    rate   = 3/4;
end    

Ncbps = Nsd * Nbpscs;
Ndbps = Ncbps * rate;  

mcsTable = struct( ...
    'Rate',       rate, ...
    'NBPSCS',     Nbpscs, ...
    'NSD',        Nsd, ...
    'NCBPS',      Ncbps, ...
    'NDBPS',      Ndbps, ...
    'NES',        1, ...
    'mSTBC',      1);
end

%-------------------------------------------------------------------------
function mcsTable = getHTMCSTable(cfgFormat)
% Supports MCS values only in the range 0-31 for now.

switch cfgFormat.ChannelBandwidth
    case 'CBW20'
        Nsd = 52;
    otherwise % CBW40
        Nsd = 108;
end

% Strip Nss from MCS to get MC and Nss
Nss = floor(cfgFormat.MCS/8)+1;
mc = rem(cfgFormat.MCS, 8);

switch mc
  case 0
    Nbpscs = 1; % 'BPSK'
    rate   = 1/2;
  case 1
    Nbpscs = 2; % 'QPSK'
    rate   = 1/2;
  case 2
    Nbpscs = 2; 
    rate   = 3/4;
  case 3
    Nbpscs = 4; % '16QAM'
    rate   = 1/2;
  case 4
    Nbpscs = 4; 
    rate   = 3/4;
  case 5
    Nbpscs = 6; % '64QAM'
    rate   = 2/3;
  case 6
    Nbpscs = 6; 
    rate   = 3/4;
  otherwise % MCS == 7
    Nbpscs = 6;
    rate   = 5/6;
end    

Ncbps = Nsd * Nbpscs * Nss;
Ndbps = Ncbps * rate;  


if strcmp(cfgFormat.ChannelCoding,'LDPC')
    Nes = 1; % Set this to 1 for LDPC encoding
else
    % Any Ndbps>1200 => Nes=2, for 300 Mbps per encoder
    %   Confirmed with Tables 20-30 to 20-44.
    Nes = ceil(Ndbps/(4*300));  
end

STBC = cfgFormat.NumSpaceTimeStreams - Nss;
mSTBC = 1 + (STBC~=0);

mcsTable = struct( ...
    'Rate',       rate, ...
    'NBPSCS',     Nbpscs, ...
    'NSD',        Nsd, ...
    'NCBPS',      Ncbps, ...
    'NDBPS',      Ndbps, ...
    'NES',        Nes, ...
    'Nss',        Nss, ...
    'mSTBC',      mSTBC);
end

function mcsTable = getVHTRateTable(cfgFormat, NSD)

numUsers = cfgFormat.NumUsers;
mSTBC = (numUsers==1 && cfgFormat.STBC)+1;
numSS = cfgFormat.NumSpaceTimeStreams/mSTBC;
MCS = repmat(cfgFormat.MCS, 1, numUsers/length(cfgFormat.MCS));

if isa(cfgFormat,'wlanS1GConfig')
    channelCoding = {'BCC', 'BCC', 'BCC', 'BCC'}; % Maximum 4 users for, all BCC
else
    channelCoding = getChannelCoding(cfgFormat);
end
[rate, Nbpscs, Ncbps, Ndbps, Nes] = deal(zeros(1, numUsers));

for u = 1:numUsers
    [rate(u), Nbpscs(u), Ncbps(u), Ndbps(u), Nes(u)] = ...
        getVHTMCSTableForOneUser(MCS(u), NSD, numSS(u), channelCoding{u});
end


mcsTable = struct( ...
    'Rate',       rate, ...
    'NBPSCS',     Nbpscs, ...
    'NSD',        NSD, ...
    'NCBPS',      Ncbps, ...
    'NDBPS',      Ndbps, ...
    'NES',        Nes, ...
    'Nss',        numSS, ...
    'mSTBC',      mSTBC*ones(1,cfgFormat.NumUsers));
end

%-------------------------------------------------------------------------
function [rate, Nbpscs, Ncbps, Ndbps, Nes] = getVHTMCSTableForOneUser(MCS, Nsd, Nss,channelCoding)

switch MCS
  case 0
    Nbpscs = 1; % 'BPSK'
    rate   = 1/2;
    rep    = 1;
  case 1
    Nbpscs = 2; % 'QPSK'
    rate   = 1/2;
    rep    = 1;
  case 2
    Nbpscs = 2; 
    rate   = 3/4;
    rep    = 1;
  case 3
    Nbpscs = 4; % '16QAM'
    rate   = 1/2;
    rep    = 1;
  case 4
    Nbpscs = 4; 
    rate   = 3/4;
    rep    = 1;
  case 5
    Nbpscs = 6; % '64QAM'
    rate   = 2/3;
    rep    = 1;
  case 6
    Nbpscs = 6; 
    rate   = 3/4;
    rep    = 1;
  case 7
    Nbpscs = 6;
    rate   = 5/6;
    rep    = 1;
  case 8
    Nbpscs = 8; % 256QAM
    rate   = 3/4;
    rep    = 1;
  case 9
    Nbpscs = 8;
    rate   = 5/6;
    rep    = 1;
  case 10  
    Nbpscs = 1; % 'BPSK'
    rate   = 1/2;
    rep    = 2;
  case 11 
    Nbpscs = 10; % 1024QAM
    rate = 3/4;
    rep = 1;
  otherwise % MCS 12
    assert(MCS == 12);
    Nbpscs = 10; % 1024QAM
    rate = 5/6;
    rep = 1;
end

Ncbps = Nsd * Nbpscs * Nss;
Ndbps = Ncbps * rate / rep;  

if strcmp(channelCoding,'LDPC')
    Nes = 1; % Set this to 1 for LDPC encoding
else
    % Handle exceptions to Nes generic rule - Table 7.13 [2].
    %   For each case listed, work off the Ndbps value and create a look-up
    %   table for the Nes value.
    %   Only 9360 has a valid value from the generic rule also, 
    %   all others are exceptions
    NdbpsVec = [2457 8190 9828 9360 14040 9828 16380 19656 21840 14976 22464];
    expNes =   [   3    6    6    6     8    6     9    12    12     8    12];
    
    numNdbpsVec = 1:numel(NdbpsVec);
    exceptIdx = numNdbpsVec(Ndbps == NdbpsVec);
    if ~isempty(exceptIdx)
        if (Ndbps == 9360) && (Nss == 5) % One valid case for 160, 80+80
            Nes = 5;
        else  % Two exception cases
            Nes = expNes(exceptIdx(1));
        end
    else  % Generic rule: 3.6*600 - for a net 600Mbps per encoder
        Nes = ceil(Ndbps/2160);
    end
end
end


%-------------------------------------------------------------------------
function mcsTable = getDMGMCSTable(mcsIn)

    if ~ischar(mcsIn)
        mcs = int2str(mcsIn);
    else
        mcs = mcsIn;
    end

    % Defaults may not be applicable for all MCS but are required for
    % codegen
    Nsd = 336; % Number of data subcarriers
    repetition = 1;
    NCWMIN = 0;
    NBPSC = 0;
    
    % IEEE 802.11-2016
    switch mcs
        % Control, Table 20-10
        case '0' % 'DBPSK'
            NCBPS = 1;
            rate = 1/2;
            repetition = 1;
            
        % SC, Table 20-19
        case '1' % 'pi/2-BPSK'
            NCBPS = 1;
            rate = 1/2;
            repetition = 2;
            NCWMIN = 12;
        case '2' % 'pi/2-BPSK'
            NCBPS = 1;
            rate = 1/2;
            repetition = 1;
            NCWMIN = 12;
        case '3' % 'pi/2-BPSK'
            NCBPS = 1;
            rate = 5/8;
            repetition = 1;
            NCWMIN = 12;
        case '4' % 'pi/2-BPSK'
            NCBPS = 1;
            rate = 3/4;
            repetition = 1;
            NCWMIN = 12;
        case '5' % 'pi/2-BPSK'
            NCBPS = 1;
            rate = 13/16;
            repetition = 1;
            NCWMIN = 12;
        case '6' % 'pi/2-QPSK'
            NCBPS = 2;
            rate = 1/2;
            repetition = 1;
            NCWMIN = 23;
        case '7' % 'pi/2-QPSK'
            NCBPS = 2;
            rate = 5/8;
            repetition = 1;
            NCWMIN = 23;
        case '8' % 'pi/2-QPSK'
            NCBPS = 2;
            rate = 3/4;
            repetition = 1;
            NCWMIN = 23;
        case '9' % 'pi/2-QPSK'
            NCBPS = 2;
            rate = 13/16;
            repetition = 1;
            NCWMIN = 23;
        case '9.1' % 'pi/2-QPSK'
            NCBPS = 2;
            rate = 7/8;
            repetition = 1;
            NCWMIN = 25;
        case '10' % 'pi/2-16QAM'
            NCBPS = 4;
            rate = 1/2;
            repetition = 1;
            NCWMIN = 46;
        case '11' % 'pi/2-16QAM'
            NCBPS = 4;
            rate = 5/8;
            repetition = 1;
            NCWMIN = 46;
        case '12' % 'pi/2-16QAM'
            NCBPS = 4;
            rate = 3/4;
            repetition = 1;
            NCWMIN = 46;
        case '12.1' % 'pi/2-16QAM'
            NCBPS = 4;
            rate = 13/16;
            repetition = 1;
            NCWMIN = 46;
        case '12.2' % 'pi/2-16QAM'
            NCBPS = 4;
            rate = 7/8;
            repetition = 1;
            NCWMIN = 49;
        case '12.3' % 'pi/2-64QAM'
            NCBPS = 6;
            rate = 5/8;
            repetition = 1;
            NCWMIN = 69;
        case '12.4' % 'pi/2-64QAM'
            NCBPS = 6;
            rate = 3/4;
            repetition = 1;
            NCWMIN = 69;
        case '12.5' % 'pi/2-64QAM'
            NCBPS = 6;
            rate = 13/16;
            repetition = 1;
            NCWMIN = 69;
        case '12.6' % 'pi/2-64QAM'
            NCBPS = 6;
            rate = 7/8;
            repetition = 1;
            NCWMIN = 74;

        % OFDM, Table 20-14
        case '13' % SQPSK
            NBPSC = 1;
            rate  = 1/2;
            NCBPS = Nsd*NBPSC;
        case '14' % SQPSK
            NBPSC = 1;
            rate  = 5/8;
            NCBPS = Nsd*NBPSC;
        case '15' % QPSK
            NBPSC = 2;
            rate  = 1/2;
            NCBPS = Nsd*NBPSC;
        case '16' % QPSK
            NBPSC = 2;
            rate  = 5/8;
            NCBPS = Nsd*NBPSC;
        case '17' % QPSK
            NBPSC = 2;
            rate  = 3/4;
            NCBPS = Nsd*NBPSC;
        case '18' % 16-QAM
            NBPSC = 4;
            rate  = 1/2;
            NCBPS = Nsd*NBPSC;
        case '19' % 16-QAM
            NBPSC = 4;
            rate  = 5/8;
            NCBPS = Nsd*NBPSC;
        case '20' % 16-QAM
            NBPSC = 4;
            rate  = 3/4;
            NCBPS = Nsd*NBPSC;
        case '21' % 16-QAM
            NBPSC = 4;
            rate  = 13/16;
            NCBPS = Nsd*NBPSC;
        case '22' % 64-QAM
            NBPSC = 6;
            rate  = 5/8;
            NCBPS = Nsd*NBPSC;
        case '23' % 64-QAM
            NBPSC = 6;
            rate  = 3/4;
            NCBPS = Nsd*NBPSC;
        otherwise % 24 % 64-QAM
            NBPSC = 6;
            rate  = 13/16;
            NCBPS = Nsd*NBPSC;

    end
    
    NDBPS = NCBPS*rate; 

    mcsTable = struct( ...
        'Rate',       rate, ...
        'NCBPS',      NCBPS, ...
        'NDBPS',      NDBPS, ...
        'NBPSCS',     NBPSC, ...
        'Repetition', repetition, ...
        'NCWMIN',     NCWMIN);
    
end

