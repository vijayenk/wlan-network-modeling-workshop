function y = wlanBCCDeinterleave(x, type, numCBPSSI, varargin)
%wlanBCCInterleave BCC Deinterleaver
%
%   Y = wlanBCCDeinterleave(X, TYPE, NUMCBPSSI, CHANBW) outputs the binary
%   convolutionally deinterleaved input X for a given interleaver TYPE, as
%   defined in IEEE 802.11-2012 Section 18.3.5.7, IEEE 802.11ac-2013
%   Section 22.3.10.8, and IEEE 802.11ah Section 24.3.9.8.
%
%   Y is an array of size (Ncbpssi*Nsym)-by-Nss-by-Nseg containing binary 
%   convolutionally deinterleaved data. Ncbpssi is the number of coded bits
%   per OFDM symbol per spatial stream per interleaver block, Nsym is the
%   number of OFDM symbols, Nss is the number of spatial streams, and Nseg
%   is the number of segments.
%
%   X is a single or double precision array of size
%   (Ncbpssi*Nsym)-by-Nss-by-Nseg containing binary convolutionally
%   interleaved data. Nss is limited to 1 for 'Non-HT' TYPE, whereas it is
%   limited to 1 to 8 for 'VHT' TYPE.
%
%   TYPE is a character vector or string specifying the type of 
%   deinterleaving to perform. It must be 'Non-HT' or 'VHT'.
%
%   NUMCBPSSI is the number of coded bits per OFDM symbol per spatial 
%   stream per interleaver block. It is a positive integer scalar equal to
%   Nsd*Nbpscs for 'Non-HT' TYPE, and equal to Nsd*Nbpscs/Nseg for
%   'VHT' TYPE, where Nsd is the number of data subcarriers, and Nbpscs is 
%   the number of coded bits per subcarrier per spatial stream.
%
%   CHANBW is a character vector or string with the channel bandwidth. It
%   must be one of 'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16', 'CBW20',
%   'CBW40', 'CBW80', or 'CBW160'. CHANBW is not a required parameter for
%   the 'Non-HT' deinterleaver TYPE.
%   
%   Y = wlanBCCDeinterleave(X, TYPE, NUMCBPSSI) is used for the Non-HT
%   deinterleaver TYPE.

%   Copyright 2015-2024 The MathWorks, Inc.


%#codegen

% Validate Deinterleaver inputs
[chanBW,numBPSCS] = wlan.internal.validateInterleaveInputs(type,numCBPSSI,varargin{:});

% Return an empty matrix if x is empty
if isempty(x)
    y = zeros(size(x),'like',x);
    return;
end

% Validate input signal
validateattributes(x,{'double','single'},{'3d','finite'},mfilename,'Input');
coder.internal.errorIf((mod(size(x,1),numCBPSSI)~=0),'wlan:wlanBCCInterleave:InvalidIntInputRows');
coder.internal.errorIf((strcmp(type,'Non-HT') && size(x,2)~=1),'wlan:wlanBCCInterleave:InvalidNonHTIntInputColumns');
coder.internal.errorIf((strcmp(type,'VHT') && size(x,2)>8),'wlan:wlanBCCInterleave:InvalidVHTIntInputColumns');

% Number of spatial streams
numSS = size(x,2);

% Get BCC interleaver/deinterleaver parameters
[Ncol,Nrow,Nrot] = wlan.internal.interleaveParameters(type,numCBPSSI,numBPSCS,chanBW,numSS);

y = wlan.internal.bccDeinterleaveCore(x,numBPSCS,numCBPSSI,Ncol,Nrow,Nrot);

end
