function [modscheme,rate] = mcs2rate(format,mcs)
%mcs2rate Convert MCS to rate
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen
switch format
    case 'NonHT'
        % Non-HT modulation and coding scheme from MCS
        switch mcs
            case 0
                modscheme = 2;
                rate = 1/2;
            case 1
                modscheme = 2;
                rate = 3/4;
            case 2
                modscheme = 4;
                rate = 1/2;
            case 3
                modscheme = 4;
                rate = 3/4;
            case 4
                modscheme = 16;
                rate = 1/2;
            case 5
                modscheme = 16;
                rate = 3/4;
            case 6
                modscheme = 64;
                rate = 2/3;
            otherwise % 7
                assert(mcs==7,'Invalid MCS for Non-HT');
                modscheme = 64;
                rate = 3/4;
        end

    case {'VHT','HE_SU','HE_EXT_SU','HE_MU','HE_TB','EHT_SU'}
        % EHT, HE, and VHT modulation and coding scheme from MCS
        switch mcs
            case 0
                modscheme = 2;
                rate = 1/2;
            case 1
                modscheme = 4;
                rate = 1/2;
            case 2
                modscheme = 4;
                rate = 3/4;
            case 3
                modscheme = 16;
                rate = 1/2;
            case 4
                modscheme = 16;
                rate = 3/4;
            case 5
                modscheme = 64;
                rate = 2/3;
            case 6
                modscheme = 64;
                rate = 3/4;
            case 7
                modscheme = 64;
                rate = 5/6;
            case 8
                modscheme = 256;
                rate = 3/4;
            case 9
                modscheme = 256;
                rate = 5/6;
            case 10
                modscheme = 1024;
                rate = 3/4;
            case 11
                modscheme = 1024;
                rate = 5/6;
            case 12
                modscheme = 4096;
                rate = 3/4;
            otherwise % 13
                assert(mcs==13);
                modscheme = 4096;
                rate = 5/6;
        end

    otherwise
        assert(strcmp(format,'HTMixed'),'Invalid format')

        % HT MCS wraps around every 8 as it climbs spatial-streams
        mcs = mod(mcs,8);
        % HT modulation and coding scheme from MCS
        switch mcs
            case 0
                modscheme = 2;
                rate = 1/2;
            case 1
                modscheme = 4;
                rate = 1/2;
            case 2
                modscheme = 4;
                rate = 3/4;
            case 3
                modscheme = 16;
                rate = 1/2;
            case 4
                modscheme = 16;
                rate = 3/4;
            case 5
                modscheme = 64;
                rate = 2/3;
            case 6
                modscheme = 64;
                rate = 3/4;
            otherwise % 7
                modscheme = 64;
                rate = 5/6;
        end
end
end
