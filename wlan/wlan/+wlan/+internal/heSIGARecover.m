function [bits,failCRC,cpe,eqCombSIGASym,varargout] = heSIGARecover(x,chanEst,nVar,ofdmInfo,cfg)
%heSIGARecover Recover information bits in HE-SIG-A field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BITS,FAILCRC] = heSIGARecover(RX,NOISEVAREST) recovers the
%   information bits given the HE-SIG-A field, and the noise variance
%   estimate.
%
%   BITS is an int8 column vector of length 52 containing the recovered
%   information bits in HE-SIG-A field.
% 
%   FAILCRC is true if BITS fails the CRC check. It is a logical scalar.
%
%   CPE is a real 1-by-Nsym vector containing the common phase error per
%   OFDM symbol averaged over receive antennas.
%
%   [...,EQCOMBSIGASYM] = ehtUSIGRecover(...) returns the equalized data
%   subcarriers after averaging over 20 MHz subchannels.
%
%   [...,EQUSIGASYM] = ehtUSIGRecover(...) returns the equalized data
%   subcarriers without averaging over 20 MHz subchannels.
%
%   X is the received time-domain signal, specified as a single or double
%   complex matrix of size Ns-by-Nr, where Ns is the number of time-domain
%   samples in HE-SIG-A field. If Ns is not an integer multiple of the OFDM
%   symbol length for the specified field, then mod(Ns,symbol length)
%   trailing samples are ignored.
%
%   CHEST is a real or complex array for which dimensions are
%   Nsc-by-1-by-Nr.
%
%   NVAR is the noise variance estimate. It is a real nonnegative scalar.
%
%   OFDMINFO is a structure containing OFDM information for the HE-SIG-A
%   field and configuration.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanHERecoveryConfig')">wlanHERecoveryConfig</a>
%   that specifies the parameters for the HE format.

%   Copyright 2024 The MathWorks, Inc.

sigaDemod = wlanHEDemodulate(x,'HE-SIG-A',cfg.ChannelBandwidth);
[hesigaDemod,cpe] = wlanHETrackPilotError(sigaDemod,chanEst,cfg,'HE-SIG-A');

% Equalize data carrying subcarriers, merge 20 MHz subchannels
[eqCombSIGASym,csi] = wlanHEEqualize(hesigaDemod(ofdmInfo.DataIndices,:,:),chanEst(ofdmInfo.DataIndices,:,:),nVar,cfg,'HE-SIG-A');
if nargout==5
    varargout{1} = ofdmEqualize(hesigaDemod(ofdmInfo.DataIndices,:,:),chanEst(ofdmInfo.DataIndices,:,:),nVar); % Equalize without merging 20 MHz 20 MHz subchannels
end

% Recover HE-SIG-A bits
[bits,failCRC] = wlanHESIGABitRecover(eqCombSIGASym,nVar,csi);

end