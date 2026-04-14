function params = dmgExtendedMCSParameters(varargin)
%dmgExtendedMCSParameters Parameters for DMG extended SC MCS
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PARAMS = dmgExtendedMCSParameters(CFGDMG) returns DMG extended MCS 
%   parameters as per IEEE 802.11-2016.
%
%   PARAMS is a structure the following fields:
%     BaseMCS     - The base MCS as per Table 20-19
%     BaseLength1 - Base_Length1 calculation as per Table 20-18
%     BaseLength2 - Base_Length2 calculation as per Table 20-18
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.
%
%   PARAMS = dmgExtendedMCSParameters(MCS,NBLKS) returns for a given MCS
%   and NBLKs.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

narginchk(1,2);
    
if nargin==1
    % PARAMS = dmgExtendedMCSParameters(CFGDMG)
    cfg = varargin{1};
    encodingParams = wlan.internal.dmgSCEncodingInfo(cfg);
    NBLKS = encodingParams.NBLKS;
    MCS = cfg.MCS;
else
    % PARAMS = dmgExtendedMCSParameters(MCS,NBLKS)
    MCS = varargin{1};
    NBLKS = varargin{2};
end

% IEEE 802.11-2016, Table 20-18 and Table 20-19
switch MCS
    case '9.1'
        baseMCS = '6';                   
        baseLength1 = floor(NBLKS*4/3)*42;
        baseLength2 = floor(floor(NBLKS*56/39)*68.25);                    
    case '12.1'
        baseMCS = '7';
        baseLength1 = floor(floor(NBLKS*4/3)*52.5);
        baseLength2 = floor(floor(NBLKS*8/3)*68.25);
    case '12.2'
        baseMCS = '8';
        baseLength1 = floor(NBLKS*4/3)*63;
        baseLength2 = floor(floor(NBLKS*112/39)*68.25);
    case '12.3'
        baseMCS = '9';
        baseLength1 = floor(floor(NBLKS*4/3)*68.25);
        baseLength2 = NBLKS*210;
    case '12.4'
        baseMCS = '10';
        baseLength1 = floor(NBLKS*8/3)*42;
        baseLength2 = NBLKS*252;
    case '12.5'
        baseMCS = '11';
        baseLength1 = floor(floor(NBLKS*8/3)*52.5);
        baseLength2 = NBLKS*273;
    otherwise % 12.6
        baseMCS = '12';
        baseLength1 = floor(NBLKS*8/3)*63;
        baseLength2 = floor(floor(NBLKS*56/13)*68.25);
end

params = struct;
params.BaseMCS = baseMCS;
params.BaseLength1 = baseLength1;
params.BaseLength2 = baseLength2;

end