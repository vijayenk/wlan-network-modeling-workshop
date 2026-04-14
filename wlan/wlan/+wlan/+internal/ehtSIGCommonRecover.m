function [bits,failCRC,csi,eqSIGSymComb,varargout] = ehtSIGCommonRecover(x,chEst,nVar,ofdmInfo,cfg)
%ehtSIGCommonRecover Recover information bits from EHT SIG field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BITS,FAILCRC] = ehtSIGCommonRecover(RX,CHEST,NVAR,OFDMINFO,CFG)
%   recovers the EHT-SIG common field bits given the EHT-SIG field from an
%   EHT MU transmission, full channel estimate at the L-SIG field, noise
%   variance estimate, structure containing OFDM information for the
%   specified field and configuration, and an EHT configuration object of
%   type <a href="matlab:help('wlanEHTRecoveryConfig')">wlanEHTRecoveryConfig</a>.
%
%   BITS is a binary, int8 matrix containing the recovered common field
%   bits for each content channel of the EHT-SIG field.
%
%   # For non-OFDMA
%       The EHT-SIG common bit fields are defined in Table 36-36 of IEEE
%       P802.11be/D5.0 for EHT SU and MU-MIMO, and Table 36-37 for NDP.
%       The size of the BITS input depends on the PPDU type:
%
%       * For EHT SU the size is 20-by-1
%       * For NDP the size is 16-by-1
%       * For MU-MIMO the size is 20-by-C
%
%   # For OFDMA
%       The EHT-SIG common bit fields are defined in Table 36-33 of IEEE
%       P802.11be/D5.0. The size of the BITS input depends on the channel
%       bandwidth:
%
%       * For CBW20 and CBW40 the size is 36-by-C
%       * For CBW80 the size is 45-by-C
%       * For CBW160 the size is 73-by-C-by-L
%       * For CBW320 the size is 109-by-C-by-L
%
%   Where C is the number of content channels. It is 1 for 20 MHz and 2 for
%   all other bandwidths. L is the number of 80 MHz subblocks:
%       * L is 1 for 20 MHz, 40 MHz and 80 MHz
%       * L is 2 for 160 MHz
%       * L is 4 for 320 MHz
%
%   FAILCRC represents the result of the CRC for each common encoding block
%   and content channel. True represents a CRC failure. FAILCRC is an array
%   of size X-by-C-by-L. Where X is the number of EHT-SIG common encoding
%   blocks. X is 1 for non-OFDMA configurations. For OFDMA configurations X
%   is 1 for 20 MHz, 40 MHz, and 80 MHz, and 2 for all other bandwidths.
%   See Figure 36-31 and Figure 36-32 of IEEE P802.11be/D5.0.
%
%   CSI is a Nsc-by-1 or a Nsc-by-Nsts array that represents the soft
%   channel state information. Nsc is equal to the first dimension of the
%   EQCOMBSIGSYM output.
%
%   [...,EQCOMBSIGSYM] = ehtSIGCommonRecover(...) returns the equalized
%   data subcarriers after averaging over 80 MHz subblocks.
%
%   [...,EQSIGSYM] = ehtSIGCommonRecover(...) returns the equalized
%   data subcarriers without averaging over 80 MHz subblocks.
%
%   X is the received time-domain signal, specified as a single or double
%   complex matrix of size Ns-by-Nr, where Ns is the number of time-domain
%   samples in EHT-SIG field. If Ns is not an integer multiple of the OFDM
%   symbol length for the specified field, then mod(Ns,symbol length)
%   trailing samples are ignored.
%
%   CHEST is a real or complex array for which dimensions are
%   Nsc-by-1-by-Nr.
%
%   NVAR is the noise variance estimate, specified as a real nonnegative
%   scalar.
%
%   OFDMINFO is a structure containing OFDM information for the EHT-SIG
%   field and configuration.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanEHTRecoveryConfig')">wlanEHTRecoveryConfig</a>
%   that specifies the parameters for the EHT MU format.

% Demodulate EHT-SIG field
ehtsigDemod = wlanEHTDemodulate(x,'EHT-SIG',cfg);

% Estimate and correct common phase error
ehtsigDemod = wlanEHTTrackPilotError(ehtsigDemod,chEst(ofdmInfo.PilotIndices,:,:),cfg,'EHT-SIG');

% Extract data symbols
ehtsigDemodData = ehtsigDemod(ofdmInfo.DataIndices,:,:);

% Equalize
[eqSIGSymComb,csi] = wlanEHTEqualize(ehtsigDemodData, chEst(ofdmInfo.DataIndices,:,:),nVar,cfg,'EHT-SIG'); % Equalize and merge 80 MHz subblocks
if nargout==5
    varargout{1} = ofdmEqualize(ehtsigDemodData,chEst(ofdmInfo.DataIndices,:,:),nVar); % Equalize without merging 80 MHz subblocks
end

% Decode EHT-SIG common field
[bits,failCRC] = wlanEHTSIGCommonBitRecover(eqSIGSymComb,nVar,csi,cfg);

end