function [pilotInd,numTones,refPilots,ofdmInfo] = trackingPreHEOFDMInfo(fieldName,numOFDMSym,chanBW)
%trackingPreHEOFDMInfo OFDM parameters for pre HE fields
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [PILOTIND,NUMTONES,REFPILOTS,OFDMINFO] =
%   trackingPreHEOFDMInfo(FIELDNAME,NUMOFDMSYM,CHANBW) returns:
%
%   # PILOTIND are pilot indices within the occupied subcarriers
%   # NUMTONES are the number of occupied subcarriers
%   # REFPILOTS Non-HT pilot sequence
%   # OFDMINFO OFDM configuration parameters for pre-HE fields
%
%   FIELDNAME is a character vector or string describing the EHT fields
%   which must be 'L-LTF', 'L-SIG', 'RL-SIG', 'U-SIG', or 'EHT-SIG'.
%
%   NUMOFDMSYM is the number of OFDM symbols.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   which must be 'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

%Get the OFDM information for pre-HE fields
switch fieldName
    case {'L-SIG','RL-SIG'}
        z = 0; % Pilot symbol offset
        [refPilots,ofdmInfo] = preRefPilots(numOFDMSym,z,chanBW,'L-SIG');
        % L-LTF used to equalize L-SIG and RL-SIG which have different size than demodulated symbols
        [ofdmCfg,~,pilotInd] = wlan.internal.hePreHEOFDMConfig(chanBW,'L-LTF');
        numTones = ofdmCfg.NumTones;
    case {'HE-SIG-A','U-SIG'}
        z = 2;
        [refPilots,ofdmInfo] = preRefPilots(numOFDMSym,z,chanBW,'U-SIG');
        pilotInd = ofdmInfo.PilotIndices;
        numTones = ofdmInfo.NumTones;
    otherwise % HE-SIG-B or EHT-SIG
        z = 4;
        [refPilots,ofdmInfo] = preRefPilots(numOFDMSym,z,chanBW,'EHT-SIG');
        pilotInd = ofdmInfo.PilotIndices;
        numTones = ofdmInfo.NumTones;
end

end

function [refPilots,ofdmInfo] = preRefPilots(numSym,z,chanBW,fieldName)
% preRefPilots Non-HT pilot sequence

    [preHEOFDMInfo,~,preHEPilotInd] = wlan.internal.hePreHEOFDMConfig(chanBW,fieldName);
    refPilots = wlan.internal.nonHTPilots(numSym,z);
    refPilots = repmat(refPilots,preHEOFDMInfo.NumSubchannels,1);
    ofdmInfo = struct;
    ofdmInfo.NumTones = preHEOFDMInfo.NumTones;
    ofdmInfo.PilotIndices = preHEPilotInd;
end