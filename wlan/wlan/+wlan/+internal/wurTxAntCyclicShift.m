function T = wurTxAntCyclicShift(dataRate,cfgFormat,subchannelIndex)
%wurTxAntCyclicShift WUR Cyclic Shift Delay
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   T = wurTxAntCyclicShift(dataRate,cfgFormat,subChannelIndex) returns the
%   cyclic shift duration for various number of transmit antennas.
%
%   T is a vector of Nt-by-1 size, where Nt represents the number of
%   transmit antennas.
%
%   DATARATE specifies the transmission rate as character vector or string 
%   and must be 'LDR', or 'HDR'.
%
%   CFGFORMAT is the format configuration object of type <a
%   href="matlab:help('wlanWURConfig')">wlanWURConfig</a>,
%   which specifies the parameters for the WUR PPDU format.
%
%   SUBCHANNELINDEX indicates the subchannel index for CBW20, CBW40 and
%   CBW80 and must be between 1 and 4 inclusive.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

switch cfgFormat.Subchannel{subchannelIndex}.SymbolDesign
    case 'Example1'
        if strcmp(dataRate,'LDR')
            % IEEE P802.11ba/D8.0, December 2020, Table AC-4, Example 1
            switch cfgFormat.NumTransmitAntennas
                case 1
                    T = 0;
                case 2
                    T = [0 -1200].';
                case 3
                    T = [0 -1200 -2200].';
                case 4
                    T = [0 -1200 -2200 -2700].';
                case 5
                    T = [0 -1200 -2200 -2700 -700].';
                case 6
                    T = [0 -1200 -2200 -2700 -700 -1700].';
                case 7
                    T = [0 -1200 -2200 -2700 -700 -1700 -1200].';
                otherwise % NumTransmitAntennas = 8
                    T = [0 -1200 -2200 -2700 -700 -1700 -1200 -2700].';
            end
        else
            % IEEE P802.11ba/D8.0, December 2020, Table AC-3, Example 1
            switch cfgFormat.NumTransmitAntennas
                case 1
                    T = 0;
                case 2
                    T = [0 -600].';
                case 3
                    T = [0 -600 -1100].';
                case 4
                    T = [0 -600 -1100 -1350].';
                case 5
                    T = [0 -600 -1100 -1350 -350].';
                case 6
                    T = [0 -600 -1100 -1350 -350 -850].';
                case 7
                    T = [0 -600 -1100 -1350 -350 -850 -600].';
                otherwise % NumTransmitAntennas = 8
                    T = [0 -600 -1100 -1350 -350 -850 -600 -1350].';
            end
        end
    case 'Example2'
        if strcmp(dataRate,'LDR')
            % IEEE P802.11ba/D8.0, December 2020, Table AC-4, Example 2
            switch cfgFormat.NumTransmitAntennas
                case 1
                    T = 0;
                case 2
                    T = [0 -200].';
                case 3
                    T = [0 -1700 -200].';
                case 4
                    T = [0 -2200 -1200 -200].';
                case 5
                    T = [0 -2450 -1700 -950 -200].';
                case 6
                    T = [0 -2600 -2000 -1400 -800 -200].';
                case 7
                    T = [0 -2700 -2200 -1700 -1200 -700 -200].';
                otherwise % NumTransmitAntennas = 8
                    T = [0 -2750 -2350 -1900 -1500 -1050 -650 -200].';
            end
        else
            % IEEE P802.11ba/D8.0, December 2020, Table AC-3, Example 2
            switch cfgFormat.NumTransmitAntennas
                case 1
                    T = 0;
                case 2
                    T = [0 -100].';
                case 3
                    T = [0 -850 -100].';
                case 4
                    T = [0 -1100 -600 -100].';
                case 5
                    T = [0 -1200 -850 -450 -100].';
                case 6
                    T = [0 -1300 -1000 -700 -400 -100].';
                case 7
                    T = [0 -1350 -1100 -850 -600 -350 -100].';
                otherwise % NumTransmitAntennas = 8
                    T = [0 -1400 -1150 -950 -750 -550 -300 -100].';
            end
        end
    case 'Example3'
        if strcmp(dataRate,'LDR')
            % IEEE P802.11ba/D8.0, December 2020, Table AC-4, Example 3
            switch cfgFormat.NumTransmitAntennas
                case 1
                    T = 0;
                case 2
                    T = [0 -200].';
                case 3
                    T = [0 -1700 -200].';
                case 4
                    T = [0 -2200 -1200 -200].';
                case 5
                    T = [0 -2450 -1700 -950 -200].';
                case 6
                    T = [0 -2600 -2000 -1400 -800 -200].';
                case 7
                    T = [0 -2700 -2200 -1700 -1200 -700 -200].';
                otherwise % NumTransmitAntennas = 8
                    T = [0 -2750 -2350 -1900 -1500 -1050 -650 -200].';
            end
        else
            % IEEE P802.11ba/D8.0, December 2020, Table AC-3, Example 3
            switch cfgFormat.NumTransmitAntennas
                case 1
                    T = 0;
                case 2
                    T = [0 -100].';
                case 3
                    T = [0 -850 -100].';
                case 4
                    T = [0 -1100 -600 -100].';
                case 5
                    T = [0 -1200 -850 -450 -100].';
                case 6
                    T = [0 -1300 -1000 -700 -400 -100].';
                case 7
                    T = [0 -1350 -1100 -850 -600 -350 -100].';
                otherwise % NumTransmitAntennas = 8
                    T = [0 -1400 -1150 -950 -750 -550 -300 -100].';
            end
        end
    otherwise % UserDefined
        if strcmp(dataRate,'LDR')
            T = reshape(cfgFormat.Subchannel{subchannelIndex}.LDRCSD(1:cfgFormat.NumTransmitAntennas),[],1);
        else
            T = reshape(cfgFormat.Subchannel{subchannelIndex}.HDRCSD(1:cfgFormat.NumTransmitAntennas),[],1);
        end
end

end

