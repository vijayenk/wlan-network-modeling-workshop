function [Nsd,Nsp,Nsr] = s1gSubcarriersPerSymbol(field,varargin)
%s1gSubcarriersPerSymbol Subcarrier related constants for S1G
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [NSD,NSP,NSR] = s1gSubcarriersPerSymbol(FIELD,CHANBW) returns the
%   number of occupied data subcarriers (NSD), number of occupied pilot
%   subcarriers (NSP) and the highest subcarrier index (NSR) per OFDM
%   symbol for a given field and channel bandwidth. These constants are
%   given in Table 24-4 or Table 24-5 "Timing-related constants" in IEEE
%   P802.11ah/D5.0. Note Table 24-5 provides Nsd and Nsp per 2 MHz segment
%   but this function returns Nsd and Nsp per OFDM symbol.
%
%   [NSD,NSP,NSR] = s1gSubcarriersPerSymbol(FIELD) returns the constants
%   per OFDM symbol for all channel bandwidths. In this case each output is
%   a 4-by-1 or 5-by-1 column vector where each element is the constant for
%   a channel bandwidth. The first element is the constant for CBW1 and the
%   last is for CBW16. When FIELD is 'SIG-A' a 4-by-1 vector is returned as
%   CBW1 is not valid for this field.

%   Copyright 2016 The MathWorks, Inc.

%#codegen

narginchk(1,2);

% Table 24-4
% Each row is the element for a channel bandwidth
%              CBW1 CBW2 CBW4 CBW8 CBW16
NsdTable244 = [24;  52;  108; 234; 468]; % Number of data subcarriers
NspTable244 = [2;   4;   6;   8;   16];  % Number of pilot subcarriers
NsrTable244 = [13;  28;  58;  122; 250]; % Highest subcarrier index

switch field
    case 'SIG'
        if nargin>1
            % s1gSubcarriersPerSymbol('SIG',CHANBW)
            chanBW = varargin{1};
            if strcmp(chanBW,'CBW1')
                % Table 24-4 for 1 MHz SIG field
                Nsd = NsdTable244(1);
                Nsp = NspTable244(1);
                Nsr = NsrTable244(1);
                return;
            else
                % >= 2 MHz SIG field
                [Nsd, Nsp, Nsr] = table245ChanBW(chanBW);
            end
        else
            % s1gSubcarriersPerSymbol('SIG')
            [Nsd245, Nsp245, Nsr245] = table245((1:4).');
            % Return constants for 1MHz SIG concatenated with >= 2MHz SIG
            Nsd = [NsdTable244(1); Nsd245];
            Nsp = [NspTable244(1); Nsp245];
            Nsr = [NsrTable244(1); Nsr245];
        end
    case 'SIG-A'
        if nargin>1
            % s1gSubcarriersPerSymbol('SIG-A',CHANBW)
            chanBW = varargin{1};
            % CBW 1 is not valid for SIG-A
            [Nsd, Nsp, Nsr] = table245ChanBW(chanBW);
        else
            % s1gSubcarriersPerSymbol('SIG-A')
            [Nsd, Nsp, Nsr] = table245((1:4).');
        end
    otherwise % SIG-B, Data
        % Table 24-4
        if nargin>1
            % s1gSubcarriersPerSymbol(FIELD,CHANBW)
            % Return constants for a given channel bandwidth
            chanBW = varargin{1};
            switch chanBW
                case 'CBW1'
                    idx = 1;
                case 'CBW2'
                    idx = 2;
                case 'CBW4'
                    idx = 3;
                case 'CBW8'
                    idx = 4;
                otherwise % 'CBW16'
                    idx = 5;
            end
            Nsd = NsdTable244(idx);
            Nsp = NspTable244(idx);
            Nsr = NsrTable244(idx);
        else
            % s1gSubcarriersPerSymbol(FIELD)
            % Return constants for all channel bandwidths
            Nsd = NsdTable244;
            Nsp = NspTable244;
            Nsr = NsrTable244;
        end
end
end

% Return the relevant constants given the channel bandwidth
function [Nsd, Nsp, Nsr] = table245ChanBW(chanBW)
    switch chanBW
        case 'CBW2'
            idx = 1;
        case 'CBW4'
            idx = 2;
        case 'CBW8'
            idx = 3;
        otherwise % 'CBW16'
            idx = 4;
    end
    [Nsd, Nsp, Nsr] = table245(idx);
end

function [Nsd, Nsp, Nsr] = table245(idx)
    % Table 24-5
    % Each row is the element for a channel bandwidth. Note the values
    % >CBW2 have been changed as I believe they are incorrect
    %              CBW2 CBW4 CBW8 CBW16
    NsrTable245 = [26;  58;  122; 250]; % Highest subcarrier index

    numSeg = 2.^(idx-1);
    Nsd = 48*numSeg; % Table 24-5 is per segment so multiply to create per symbol
    Nsp = 4*numSeg;  % Table 24-5 is per segment so multiply to create per symbol
    Nsr = NsrTable245(idx); % per symbol Nsr
end