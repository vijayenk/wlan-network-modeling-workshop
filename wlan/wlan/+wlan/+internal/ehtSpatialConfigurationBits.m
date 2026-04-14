function Y = ehtSpatialConfigurationBits(numSTS,varargin)
%ehtSpatialConfigurationBits EHT spatial configuration bit for MU-MIMO
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtSpatialConfigurationBits(NUMSTS) generates spatial configuration
%   subfield encoding bits for MU-MIMO as in IEEE P802.11be/D1.5, Table
%   36-42.
%
%   NUMSTS is a vector containing the number of space-time streams of all
%   users sharing a resource unit.
%
%   Y = ehtSpatialConfigurationBits(NUMSTS,RUNUMBER) validates the number
%   of space-time streams to force the combinations in IEEE P802.11be/D1.5,
%   Table 36-42.
%
%   RUNUMBER is the resource unit number, and is used to form an error
%   message.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Default do not validate
validate = false;
ruNumber = 1;
if nargin>1
    validate = true;
    ruNumber = varargin{1};
end

% numSTS is the number of space-time streams per user (element)
numUsers = numel(numSTS);

if numUsers>1 % Condition for MU-MIMO (full allocation)
    switch numUsers
        case 2
            if numSTS(2)==1 % Y = 0-3
                stsErrorIf(~(any(numSTS(1)==1:4)));
                Y = int2bit(numSTS(1)-1,6,false);
            elseif numSTS(2)==2 % Y = 4-6
                stsErrorIf(~(any(numSTS(1)==2:4)));
                Y = int2bit(numSTS(1)+2,6,false);
            elseif numSTS(2)==3 % Y = 7-8
                stsErrorIf(~(any(numSTS(1)==3:4)));
                Y = int2bit(numSTS(1)+4,6,false);
            else % Y = 9
                stsErrorIf(~all(numSTS(1:2)==4));
                Y = int2bit(9,6,false);
            end
        case 3
            if (numSTS(2)==1 && numSTS(3)==1) % Y = 0-3
                stsErrorIf(~(any(numSTS(1)==1:4)));
                Y = int2bit(numSTS(1)-1,6,false);
            elseif (numSTS(2)==2 && numSTS(3)==1) % Y = 4-6
                stsErrorIf(~(any(numSTS(1)==2:4)));
                Y = int2bit(numSTS(1)+2,6,false);
            elseif (numSTS(2)==3 && numSTS(3)==1) % Y = 7-8
                stsErrorIf(~(any(numSTS(1)==3:4)));
                Y = int2bit(numSTS(1)+4,6,false);
            elseif (numSTS(2)==2 && numSTS(3)==2) % Y = 10-12
                stsErrorIf(~any(numSTS(1)==2:4));
                Y = int2bit(numSTS(1)+8,6,false);
            else % Y = 13
                stsErrorIf(~all(numSTS(1:2)==3) || numSTS(3)~=2);
                Y = int2bit(numSTS(1)+10,6,false);
            end
        case 4
            if (numSTS(2)==1 && numSTS(3)==1 && numSTS(4)==1) % Y = 0-3
                stsErrorIf(~(any(numSTS(1)==1:4)));
                Y = int2bit(numSTS(1)-1,6,false);
            elseif (numSTS(2)==2 && numSTS(3)==1 && numSTS(4)==1) % Y = 4-6
                stsErrorIf(~(any(numSTS(1)==2:4)));
                Y = int2bit(numSTS(1)+2,6,false);
            elseif (numSTS(2)==3 && numSTS(3)==1 && numSTS(4)==1) % Y = 7
                stsErrorIf(~(any(numSTS(1)==3)));
                Y = int2bit(numSTS(1)+4,6,false);
            elseif (numSTS(2)==2 && numSTS(3)==2 && numSTS(4)==1) % Y = 10-11
                stsErrorIf(~(any(numSTS(1)==2:3)));
                Y = int2bit(numSTS(1)+8,6,false);
            else % Y = 20
                stsErrorIf(~all(numSTS(1:4)==2));
                Y = int2bit(numSTS(1)+18,6,false);
             end
        case 5
            if all(numSTS(2:5)==1) % Y = 0-3
                Y = int2bit(numSTS(1)-1,6,false);
            elseif (numSTS(2)==2 && numSTS(3)==1 && numSTS(4)==1 && numSTS(5)==1) % Y = 4-5
                stsErrorIf(~(any(numSTS(1)==2:3)));
                Y = int2bit(numSTS(1)+2,6,false);
            else % Y = 10
                stsErrorIf(~(all(numSTS(1:3)==2)) || ~(all(numSTS(4:5)==1)));
                Y = int2bit(numSTS(1)+8,6,false);
            end
        case 6
            if all(numSTS(2:6)==1) % Y = 0-2
                stsErrorIf(~(any(numSTS(1)==1:3)));
                Y = int2bit(numSTS(1)-1,6,false);
            else % Y = 4
                stsErrorIf(~(all(numSTS(1:2)==2)) || ~(all(numSTS(3:6)==1)));
                Y = int2bit(numSTS(1)+2,6,false);
            end
        case 7
            stsErrorIf(~(any(numSTS(1)==1:2)) || ~(all(numSTS(2:7)==1))); % Y = 0-1
            Y = int2bit(numSTS(1)-1,6,false);
        otherwise % 8 Users
            Y = int2bit(numSTS(1)-1,6,false); % Y = 0
    end
else % OFDMA or MU-MIMO with 1 user
    Y = int2bit(numSTS(1)-1,6,false);
end
    function stsErrorIf(condition)
        coder.internal.errorIf(validate && condition,'wlan:eht:NumSTSPerUserInvalid',ruNumber);
    end
end