function [Ncol,Nrow,Nrot] = interleaveParameters(type,numCBPSSI,numBPSCS,chanBW,numSS)
%interleaveParameters Returns BCC Interleaver/deinterleaver parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [NCOL,NROW,NROT] = interleaveParameters(TYPE,NUMCBPSSI,NUMBPSCS,...
%   CHANBW,NUMSS) outputs the configuration parameters of a BCC 
%   interleaver/deinterleaver.
%
%   NCOL is a positive integer scalar with the number of columns in the BCC
%   interleaver/deinterleaver.
%
%   NROW is a positive integer scalar with the number of rows in the BCC
%   interleaver/deinterleaver.
%
%   NROT is a nonnegative integer scalar with the number of rotations in 
%   the BCC interleaver/deinterleaver.
%
%   TYPE is a character vector or string with the type of interleaving to 
%   perform. It must be one of 'Non-HT' or 'VHT'.
%
%   NUMCBPSSI is the number of coded bits per OFDM symbol per spatial 
%   stream per interleaver block. It is a positive integer scalar.
%
%   NUMBPSCS is the number of coded bits per single carrier per spatial
%   stream. It is a positive integer scalar equal to 1, 2, 4, 6, 8, or 10.
%
%   CHANBW is a character vector or string with the channel bandwidth. It  
%   must be one of: 'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16', 'CBW20',   
%   'CBW40', 'CBW80', or 'CBW160'.
%
%   NUMSS is a positive integer scalar with the number of spatial streams.
%   It must be within the interval [1, 8]. 
%
%   See also wlanBCCInterleave and wlanBCCDeinterleave.

%   Copyright 2016-2024 The Mathworks, Inc.

%#codegen

if strcmp(type, 'Non-HT') % 'Non-HT' Interleaver. IEEE Std 802.11-2012, Section 18.3.5.7
    Ncol  = 16;  % fixed value, Eq. 18-18
    Nrow  = numCBPSSI/Ncol;
    Nrot = 0;
else   % 'VHT' interleaver. IEEE Std 802.11ac-2013, Section 22.3.10.8
    % Rows, columns, and rotations. IEEE Std 802.11ac-2013, Table 22-17
    switch chanBW
        case {'CBW1'} % Table 24-20 in IEEE P802.11ah/5.0
            Ncol = 8;
            Nrow = 3*numBPSCS;
            Nrot = 2; % NSS always <= 4
        case {'CBW2','CBW20'}
            Ncol = 13;
            Nrow = 4*numBPSCS;
            if numSS <= 4
                Nrot = 11;
            else
                Nrot = 6;
            end
        case {'CBW4','CBW40'}
            Ncol = 18;
            Nrow = 6*numBPSCS;
            if numSS <= 4
                Nrot = 29;
            else
                Nrot = 13;
            end
        otherwise % {'CBW8','CBW16','CBW80','CBW160'}
            Ncol = 26;
            Nrow = 9*numBPSCS;
            if numSS <= 4
                Nrot = 58;
            else
                Nrot = 28;
            end
    end
end