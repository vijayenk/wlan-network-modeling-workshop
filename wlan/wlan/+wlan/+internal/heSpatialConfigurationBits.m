function Y = heSpatialConfigurationBits(numSTS,varargin)
%heSpatialConfigurationBits HE spatial configuration bit for MU-MIMO
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heSpatialConfigurationBits(NUMSTS) generates spatial configuration
%   field encoding bit for MU-MIMO as in IEEE Std 802.11ax-2021, Table
%   27-30.
%
%   NUMSTS is a vector containing the number of space-time streams of all
%   users sharing a resource unit.
%
%   Y = heSpatialConfigurationBits(NUMSTS,RUNUMBER) validates the number of
%   space-time streams to force the combinations in IEEE 802.11ax-2021,
%   Table 27-30.
%
%   RUNUMBER is the resource unit number, and is used to form an error
%   message.

%   Copyright 2017-2022 The MathWorks, Inc.

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
           if numSTS(2)==1
               % Y = 0-3
               stsErrorIf(~(any(numSTS(1) == 1:4)));
               Y = int2bit(numSTS(1)-1,4,false);
           elseif numSTS(2)==2
               % Y = 4-6
               stsErrorIf(~(any(numSTS(1) == 2:4)));
               Y = int2bit(numSTS(1)+2,4,false);
           elseif numSTS(2)==3
               % Y = 7-8
               stsErrorIf(~(any(numSTS(1) == 3:4)));
               Y = int2bit(numSTS(1)+4,4,false);
           else
               % Y = 9
               stsErrorIf(any(numSTS(1:2) ~= 4));
               Y = int2bit(9,4,false);
           end
       case 3
           if (numSTS(2)==1 && numSTS(3)==1)
               % Y = 0-3
               stsErrorIf(~(any(numSTS(1) == 1:4)));
               Y = int2bit(numSTS(1)-1,4,false);
           elseif (numSTS(2)==2 && numSTS(3)==1)
               % Y = 4-6
               stsErrorIf(~(any(numSTS(1) == 2:4)));
               Y = int2bit(numSTS(1)+2,4,false);
           elseif (numSTS(2)==3 && numSTS(3)==1)
               % Y = 7-8
               stsErrorIf(~(any(numSTS(1) == 3:4)));
               Y = int2bit(numSTS(1)+4,4,false);
           elseif (numSTS(2)==2 && numSTS(3)==2)
               % Y = 9-11
               stsErrorIf(~(any(numSTS(1) == 2:4)));
               Y = int2bit(numSTS(1)+7,4,false);
           else
               % Y = 12
               stsErrorIf(any(numSTS(1:2) ~= 3));
               stsErrorIf(numSTS(3) ~= 2);
               Y = int2bit(12,4,false);
           end
       case 4
           if (numSTS(2)==1 && numSTS(3)==1 && numSTS(4)==1)
               % Y = 0-3
               stsErrorIf(~(any(numSTS(1) == 1:4)));
               Y = int2bit(numSTS(1)-1,4,false);
           elseif (numSTS(2)==2 && numSTS(3)==1 && numSTS(4)==1)
               % Y = 4-6
               stsErrorIf(~(any(numSTS(1) == 2:4)));
               Y = int2bit(numSTS(1)+2,4,false);
           elseif (numSTS(2)==3 && numSTS(3)==1 && numSTS(4)==1)
               % Y = 7
               stsErrorIf(numSTS(1) ~= 3);
               Y = int2bit(7,4,false);
           elseif (numSTS(2)==2 && numSTS(3)==2 && numSTS(4)==1)
               % Y = 8-9
               stsErrorIf(~(any(numSTS(1) == 2:3)));
               Y = int2bit(numSTS(1)+6,4,false);
           else
               % Y = 10
               stsErrorIf(any(numSTS(1:4) ~= 2));
               Y = int2bit(10,4,false);
           end
       case 5
           if all(numSTS(2:5)==1)
               % Y = 0-3
               stsErrorIf(~(any(numSTS(1) == 1:4)));
               Y = int2bit(numSTS(1)-1,4,false);
           elseif numSTS(3)==1
               % Y = 4-5
               stsErrorIf(~(any(numSTS(1) == 2:3)));
               stsErrorIf(numSTS(2) ~= 2);
               stsErrorIf(any(numSTS(3:5) ~= 1));
               Y = int2bit(numSTS(1)+2,4,false);
           else
               % Y = 6
               stsErrorIf(~all(numSTS==[2 2 2 1 1]'));
               Y = int2bit(6,4,false);
           end            
       case 6
           if all(numSTS(2:6)==1)
               % Y = 0-2
               stsErrorIf(~(any(numSTS(1) == 1:3)));
               Y = int2bit(numSTS(1)-1,4,false);
           else
               % Y = 3
               stsErrorIf(any(numSTS(1:2) ~= 2));
               stsErrorIf(any(numSTS(3:6) ~= 1));
               Y = int2bit(3,4,false);
           end  
       case 7
           % Y = 0-1
           stsErrorIf(~(any(numSTS(1) == 1:2)));
           stsErrorIf(any(numSTS(2:7) ~= 1));
           Y = int2bit(numSTS(1)-1,4,false);
       otherwise % 8 Users
           % Y = 0
           assert(numUsers==8);
           stsErrorIf(any(numSTS(1:8) ~= 1));
           Y = int2bit(0,4,false);
   end

else
    % OFDMA or MU-MIMO with 1 user
    Y = int2bit(numSTS(1)-1,4,false); % Only 3 bits transmitted in non-OFDMA case but return 4 for consistency (4th bit becomes beamforming bit)
end

function stsErrorIf(condition)
    coder.internal.errorIf(validate && condition,'wlan:he:NumSTSPerUserInvalid',ruNumber);
end

end