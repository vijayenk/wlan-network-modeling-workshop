function k = s1gKPilotTravel(chanBW,Nsts,Nsym)
%KPilotFix Set of traveling pilot subcarrier indices for S1G
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%    K = s1gKPilotTravel(CHANBW,NSTS,NSYM) returns the subcarrier indices
%    for each pilot for each OFDM symbol for a given channel bandwidth
%    character vector CHANBW and number of space-time streams NSTS. In this
%    K is a matrix with NSYM columns.

%   Copyright 2016 The MathWorks, Inc.

%#codegen

% Table 24-21
KPilot_Travel_NSTS1_1MHz = [[-2  -10 -5 -13 -8 -3 -11 -6 -1 -9 -4 -12 -7]; ...
                            [12  4   9  1   6  11 3   8  13 5  10 2   7]];
            
% Table 24-22
KPilot_Travel_NSTS1_2MHz = [[-28 -24 -20 -16 -26 -22 -18 -27 -23 -19 -15 -25 -21 -17]; ...
                            [-12 -8 -4 -2 -14 -10 -6 -11 -7 -3 1 -13 -9 -5]; ...
                            [4 8 12 16 2 6 10 5 9 13 17 -1 3 7]; ...
                            [20 24 28 26 14 18 22 21 25 23 27 11 15 19]];

% Table 24-23
KPilot_Travel_NSTS1_4MHz = [[-49 -41 -33 -25 -17 -9 -58 -50 -42 -34 -26 -18 -10 -2 -51 -43 -35 -27 -19]; ...
                            [-30 -22 -14 -6 -55 -47 -39 -31 -23 -15 -7 -56 -48 -40 -32 -24 -16 -8 -57]; ...
                            [-11 -3 -52 -44 -36 -28 -20 -12 -4 -53 -45 -37 -29 -21 -13 -5 -54 -46 -38]; ...
                            [11 19 27 35 43 51 2 10 18 26 34 42 50 58 9 17 25 33 41]; ...
                            [30 38 46 54 5 13 21 29 37 45 53 4 12 20 28 36 44 52 3]; ...
                            [49 57 8 16 24 32 40 48 56 7 15 23 31 39 47 55 6 14 22]];
                        
% Table 24-24
KPilot_Travel_NSTS1_8MHz = [[-122 -118 -114 -110 -106 -102 -98 -94 -120 -116 -112 -108 -104 -100 -96 -92 -121 -117 -113 -109 -105 -101 -97 -93 -119 -115 -111 -107 -103 -99 -95 -91]; ...
                            [-90 -86 -82 -78 -74 -70 -66 -62 -88 -84 -80 -76 -72 -68 -64 -60 -89 -85 -81 -77 -73 -69 -65 -61 -87 -83 -79 -75 -71 -67 -63 -59]; ...
                            [-58 -54 -50 -46 -42 -38 -34 -30 -56 -52 -48 -44 -40 -36 -32 -28 -57 -53 -49 -45 -41 -37 -33 -29 -55 -51 -47 -43 -39 -35 -31 -27]; ...
                            [-26 -22 -18 -14 -10 -6 -2 2 -24 -20 -16 -12 -8 -4 2 4 -25 -21 -17 -13 -9 -5 -2 3 -23 -19 -15 -11 -7 -3 2 5]; ...
                            [ 6 10 14 18 22 26 30 34 8 12 16 20 24 28 32 36 7 11 15 19 23 27 31 35 9 13 17 21 25 29 33 27]; ...
                            [ 38 42 46 50 54 58 62 66 40 44 48 52 56 60 64 68 39 43 47 51 55 59 63 67 41 45 49 53 57 61 65 69]; ...
                            [70 74 78 82 86 90 94 98 72 76 80 84 88 92 96 100 71 75 79 83 87 91 95 99 73 77 81 85 89 93 97 101]; ...
                            [102 106 110 114 118 122 120 -120 104 108 112 116 120 122 -2 -122 103 107 111 115 119 121 2 -121 105 109 113 117 121 121 -2 -121]]; 

% Table 24-25
KPilot_Travel_NSTS2_1MHz = [[-3 -13 -9 -5 -1 -11 -7]; ...
                            [11 1 5 9 13 3 7]];

% Table 24-26
KPilot_Travel_NSTS2_2MHz = [[-28 -24 -20 -16 -26 -22 -18]; ...
                            [-12 -8 -4 -2 -14 -10 -6]; ...
                            [4 8 12 16 2 6 10]; ...
                            [20 24 28 26 14 18 22]];

% Table 24-27
KPilot_Travel_NSTS2_4MHz = [[-50 -44 -38 -32 -26 -20 -14 -8 -2 -56]; ...
                            [-30 -24 -18 -12 -6 -58 -54 -48 -42 -36]; ...
                            [-10 -4 -58 -52 -46 -40 -34 -28 -22 -16]; ...
                            [10 16 22 28 34 40 46 52 58 4]; ...
                            [30 36 42 48 54 58 6 12 18 24]; ...
                            [50 56 2 8 14 20 26 32 38 44]];

% Table 24-28
KPilot_Travel_NSTS2_8MHz = [[-122 -118 -114 -110 -106 -102 -98 -94 -120 -116 -112 -108 -104 -100 -96 -92]; ...
                            [-90 -86 -82 -78 -74 -70 -66 -62 -88 -84 -80 -76 -72 -68 -64 -60]; ...
                            [-58 -54 -50 -46 -42 -38 -34 -30 -56 -52 -48 -44 -40 -36 -32 -28]; ...
                            [-26 -22 -18 -14 -10 -6 -2 2 -24 -20 -16 -12 -8 -4 2 4]; ...
                            [ 6 10 14 18 22 26 30 34 8 12 16 20 24 28 32 36]; ...
                            [ 38 42 46 50 54 58 62 66 40 44 48 52 56 60 64 68]; ...
                            [70 74 78 82 86 90 94 98 72 76 80 84 88 92 96 100]; ...
                            [102 106 110 114 118 122 120 -120 104 108 112 116 120 122 -2 -122]];

n = (0:Nsym-1).';
% Traveling pilots not defined for >2 STS. 2 STS only valid when STBC used
if Nsts==1
    switch chanBW
        case 'CBW1'
            Ntpbw = 13;
            KPilot_Travel = KPilot_Travel_NSTS1_1MHz;
        case 'CBW2'
            Ntpbw = 14;
            KPilot_Travel = KPilot_Travel_NSTS1_2MHz;
        case 'CBW4'
            Ntpbw = 19;
            KPilot_Travel = KPilot_Travel_NSTS1_4MHz;
        case 'CBW8'
            Ntpbw = 32;
            KPilot_Travel = KPilot_Travel_NSTS1_8MHz;
        otherwise % 'CBW16'
            Ntpbw = 32;
            KPilot_Travel = [KPilot_Travel_NSTS1_8MHz-128; ...
                             KPilot_Travel_NSTS1_8MHz+128]; % Eqn 24-50
    end
    m = mod(n,Ntpbw); % Eqn 24-48
else % Nsts==2
    switch chanBW
        case 'CBW1'
            Ntpbw = 7;
            KPilot_Travel = KPilot_Travel_NSTS2_1MHz;
        case 'CBW2'
            Ntpbw = 7;
            KPilot_Travel = KPilot_Travel_NSTS2_2MHz;
        case 'CBW4'
            Ntpbw = 10;
            KPilot_Travel = KPilot_Travel_NSTS2_4MHz;
        case 'CBW8'
            Ntpbw = 16;
            KPilot_Travel = KPilot_Travel_NSTS2_8MHz;
        otherwise % 'CBW16'
             Ntpbw = 16;
            KPilot_Travel = [KPilot_Travel_NSTS2_8MHz-128; ...
                             KPilot_Travel_NSTS2_8MHz+128]; % Eqn 24-50
    end
    m = mod(floor(n/2),Ntpbw); % Eqn 24-49
end
k = KPilot_Travel(:,m+1);
end