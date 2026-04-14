function [bits,failCRC,cpe,eqCombUSIGSym,varargout] = ehtUSIGRecover(x,chEst,nVar,ofdmInfo,cfg)
%ehtUSIGRecover Recover information bits in EHT U-SIG field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BITS,FAILCRC] = ehtUSIGRecover(X,CHEST,NVAR,OFDMINFO,CFG) recovers the
%   information bits given the U-SIG field from an EHT MU transmission,
%   full channel estimate at the L-SIG field, noise variance estimate,
%   structure containing OFDM information for the specified field and
%   configuration, and an EHT configuration object of type 
%   <a href="matlab:help('wlanEHTRecoveryConfig')">wlanEHTRecoveryConfig</a>.
%
%   BITS is an int8 matrix of size 52-by-L containing the recovered
%   information bits in the U-SIG field, where L is the number of 80 MHz
%   subblocks:
%   - L is 1 for 20 MHz, 40 MHz and 80 MHz
%   - L is 2 for 160 MHz
%   - L is 4 for 320 MHz
%
%   FAILCRC is true if BITS fails the CRC check. It is a logical scalar of
%   size 1-by-L.
%
%   CPE is a real 1-by-Nsym vector containing the common phase error per
%   OFDM symbol averaged over receive antennas.
%
%   [...,EQCOMBUSIGSYM] = ehtUSIGRecover(...) returns the equalized data
%   subcarriers after averaging over 80 MHz subblocks.
%
%   [...,EQUSIGSYM] = ehtUSIGRecover(...) returns the equalized data
%   subcarriers without averaging over 80 MHz subblocks.
%
%   X is the received time-domain signal, specified as a single or double
%   complex matrix of size Ns-by-Nr, where Ns is the number of time-domain
%   samples in U-SIG field. If Ns is not an integer multiple of the OFDM
%   symbol length for the specified field, then mod(Ns,symbol length)
%   trailing samples are ignored.
%
%   CHEST is a real or complex array for which dimensions are
%   Nsc-by-1-by-Nr.
%
%   NVAR is the noise variance estimate. It is a real nonnegative scalar.
%
%   OFDMINFO is a structure containing OFDM information for the EHT-SIG
%   field and configuration.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanEHTRecoveryConfig')">wlanEHTRecoveryConfig</a>
%   that specifies the parameters for the EHT MU format.

usigDemod = wlanEHTDemodulate(x,'U-SIG',cfg);
[usigDemod,cpe] = wlanEHTTrackPilotError(usigDemod,chEst,cfg,'U-SIG');
% Equalize data carrying subcarriers, merge 80 MHz subblocks
[eqCombUSIGSym,csi] = wlanEHTEqualize(usigDemod(ofdmInfo.DataIndices,:,:),chEst(ofdmInfo.DataIndices,:,:),nVar,cfg,'U-SIG');
if nargout==5
    varargout{1} = ofdmEqualize(usigDemod(ofdmInfo.DataIndices,:,:), chEst(ofdmInfo.DataIndices,:,:),nVar); % Equalize without merging 80 MHz subblocks
end
[bits,failCRC] = wlanUSIGBitRecover(eqCombUSIGSym,nVar,csi); % Only equalize

end