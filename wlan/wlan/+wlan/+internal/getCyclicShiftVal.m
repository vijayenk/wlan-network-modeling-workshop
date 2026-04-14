function cs = getCyclicShiftVal(format, Ntx, cbw)
%getCyclicShiftVal Get cyclic shift values
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CS = getCyclicShiftVal(FORMAT,NTX,CBW) returns the cyclic shift in
%   samples for each transmit antenna. CS is a 1-by-NTX vector.
%
%   FORMAT is 'OFDM', 'VHT' or 'S1G'.
%
%   CBW is the channel bandwidth in MHz: 1/2/4/8/16/20/40/80/160. 

%   Copyright 2015-2021 The MathWorks, Inc.

%#codegen

% All values in nanoseconds
switch cbw
    case 1 % 1 MHz; S1G
        % Table 24-17 (Per STS shifts, S1G_1M), IEEE P802.11ah/D5.0
        switch Ntx
            case 2
                cShift = [0; -4e3];
            case 3
                cShift = [0; -4e3; -1e3];
            case 4
                cShift = [0; -4e3; -1e3; -5e3];
            otherwise % Ntx = 1
                cShift = 0;
        end
    case {2,4,8,16} % 2 MHz variants; S1G
        % Table 24-6 (Per STS shifts, S1G_SHORT preamble), IEEE P802.11ah/D5.0
        % Table 24-12 (Per antenna shifts, S1G_LONG preamble), IEEE P802.11ah/D5.0
        % Table 24-13 (Per STS shifts, S1G_LONG preamble), IEEE P802.11ah/D5.0
        switch Ntx
            case 2
                cShift = [0; -4e3];
            case 3
                cShift = [0; -4e3; -2e3];
            case 4
                cShift = [0; -4e3; -2e3; -6e3];
            otherwise % Ntx = 1
                cShift = 0;
        end
    otherwise % cbw = {20,40,80,160}
        if strcmp(format, 'VHT')
            % Per STS shifts for VHT, IEEE 802.11-2016 Table 21-11.
            switch Ntx
                case 2
                    cShift = [0; -400];
                case 3
                    cShift = [0; -400; -200];
                case 4
                    cShift = [0; -400; -200; -600];
                case 5
                    cShift = [0; -400; -200; -600; -350];
                case 6
                    cShift = [0; -400; -200; -600; -350; -650];
                case 7
                    cShift = [0; -400; -200; -600; -350; -650; -100];
                case 8
                    cShift = [0; -400; -200; -600; -350; -650; -100; -750];
                otherwise % Ntx = 1
                    cShift = 0;
            end
        else 
            % Per antenna shifts for L-STF, L-LTF, L-SIG, and VHT-SIG-A
            % fields, IEEE 802.11-2016 Table 21-10.
            switch Ntx
                case 2
                    cShift = [0; -200];
                case 3
                    cShift = [0; -100; -200];
                case 4
                    cShift = [0; -50; -100; -150];
                case 5
                    cShift = [0; -175; -25; -50; -75];
                case 6
                    cShift = [0; -200; -25; -150; -175; -125];
                case 7
                    cShift = [0; -200; -150; -25; -175; -75; -50];
                case 8
                    cShift = [0; -175; -150; -125; -25; -100; -50; -200];
                otherwise % Ntx = 1
                    cShift = 0;
            end
        end
end

% Cyclic shift delay in number of samples cShift is in ns (1e-9) and cbw is
% in MHz (1e-6) therefore multiply by 1e-3 to give shift in samples
cs = cShift*cbw*1e-3;

end