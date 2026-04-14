function [ltfSC,varargout] = vhtltfSequence(chanBW,numSTS,varargin)
%vhtltfSequence HT, VHT and S1G subcarrier sequence and parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [LTFSYM,P,NUMDLTF] = vhtltfSequence(CHANBW,NUMSTS) returns the
%   subcarrier values for HT-LTF/VHT-LTF/S1G-LTF, P matrix and the number
%   of LTF symbols, for a given channel bandwidth CHANBW and number of
%   space-time streams NUMSTS, for HT-Mixed, VHT and S1G formats.
%
%   [LTFSYM,P,NUMDLTF,NUMELTF] = vhtltfSequence(CHANBW,NUMSTS,NUMESS)
%   returns the subcarrier values for the HT-LTF, P matrix and number of
%   HT-LTF symbols (both data and extension) for a given channel bandwidth
%   CHANBW, number of space-time streams NUMSTS and number of extension
%   streams NUMESS, for the HT-Mixed format.

%   Copyright 2015-2017 The MathWorks, Inc.

%#codegen

narginchk(2,3);
nargoutchk(0,4);
if nargin>2
    htMode = true;
    numESS = varargin{1}; % in range [0, 3]
else 
    htMode = false;
    numESS = 0;
end

% Subcarrier values for the VHT-LTF symbol including guard bands and DC
[ltfLeft, ltfRight] = wlan.internal.lltfSequence(); % Sequences based on lltf

switch chanBW
    case 'CBW1'
        % Sequence from IEEE P802.11ah/D5.0 Section 24.3.8.3.3
        ltfSC = [0; 0; 0; 1; -1; 1; -1; -1; 1; -1; 1; 1; -1; 1; 1; 1; 0;  ...
            -1; -1; -1; 1; -1; -1; -1; 1; -1; 1; 1; 1; -1; 0; 0];
    case {'CBW2','CBW20'}
        % Same for S1G, HT and VHT
        ltfSC = [zeros(4,1); 1; 1; ltfLeft; 0; ltfRight;-1;-1; zeros(3,1)];
    case {'CBW4','CBW40'}
        % Same for S1G, HT and VHT
        ltfSC = [ zeros(6,1); ltfLeft; 1; ltfRight;-1;-1;-1; 1; 0; 0; 0; ...
            -1;1; 1;-1; ltfLeft; 1; ltfRight;  zeros(5,1)];
    case {'CBW8','CBW80'}
        % S1G and VHT only
        ltfSC = [zeros(6,1); ltfLeft; 1; ltfRight;-1;-1;-1; 1; 1;-1; 1; ...
            -1; 1; 1;-1; ltfLeft; 1; ltfRight; 1;-1; 1;-1; 0; 0; 0; ...
            1;-1;-1; 1; ltfLeft; 1; ltfRight;-1;-1;-1; 1; 1;-1; 1; ...
            -1; 1; 1;-1; ltfLeft; 1; ltfRight; zeros(5,1)];
    otherwise % {'CBW160','CBW16'}
        % S1G and VHT only
        vltf80 = [ltfLeft; 1; ltfRight;-1;-1;-1; 1; 1;-1; 1;-1; 1; 1;-1; ...
            ltfLeft; 1; ltfRight; 1;-1; 1;-1; 0; 0; 0; 1;-1;-1; 1; ...
            ltfLeft; 1; ltfRight;-1;-1;-1; 1; 1;-1; 1;-1; 1; 1;-1; ...
            ltfLeft; 1; ltfRight];
        ltfSC = [zeros(6,1); vltf80; 0; 0; 0; 0; 0; 0; 0; ...
            0; 0; 0; 0; vltf80; zeros(5,1)];
end

if (nargout>1)
    % Return the orthogonal mapping matrix
    varargout{1} = wlan.internal.mappingMatrix(numSTS);
end

if (nargout>2)
    % Number of HT/VHT LTF symbols
    numLTFSym = wlan.internal.numVHTLTFSymbols(numSTS);
    varargout{2} = numLTFSym;
    if (nargout==4) && htMode % HT-mixed
        % Include E-LTFs
        numELTFSym = wlan.internal.numHTELTFSymbols(numESS);
        varargout{3} = numELTFSym;
    end
end

end