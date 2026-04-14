function [symM,chEstM] = mergeSubcarriers(sym,chEst,nSCUnique,varargin)
%mergeSubcarriers Merge subcarriers for equalization
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [SSYMM,CHESTM] = mergeSubcarriers(SYM,CHEST,NSCUNIQUE) manipulates the
%   SYM and CHEST inputs such that the first dimensions of the outputs are
%   NSCUNIQUE and the third dimensions are nSC*nRx/NSCUNIQUE.
%
%   [SSYMM,CHESTM] = mergeSubcarriers(...,NSUBBLOCK) manipulates the SYM
%   and CHEST inputs such that the first dimensions of the outputs are
%   NSCUNIQUE*NSUBBLOCK and the third dimensions are
%   nSC*nRx/(NSCUNIQUE*NSUBBLOCK). NSUBBLOCK represents the number of
%   subblocks that are in in SYM and CHEST.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    narginchk(3,4)
    if nargin > 3
        nSubblock = varargin{1};
    else
        nSubblock = 1;
    end

    [nSC,nSym,nRx] = size(sym);
    nSTS = size(chEst,2);

    % Number of subcarriers in merged result
    nSCMerged = nSCUnique*nSubblock;

    % Number of subchannels in each subblock
    nSubchanPerSubblock = nSC/nSCMerged;

    % Total number of subcarriers in each subblock
    nSCPerSubblock = nSC/nSubblock;

    %Initialize outputs and merge subcarriers
    symM = coder.nullcopy(zeros(nSCMerged,nSym,nSubchanPerSubblock*nRx,'like',sym));
    chEstM = coder.nullcopy(zeros(nSCMerged,nSTS,nSubchanPerSubblock*nRx,'like',chEst));
    for i = 1:nSubblock
        mergedIndices = (1:nSCUnique)+(i-1)*nSCUnique;
        indices = (1:nSCPerSubblock)+(i-1)*nSCPerSubblock;
        symM(mergedIndices,:,:) = permute(reshape(permute(sym(indices,:,:),[1 3 2]),nSCUnique,[],nSym),[1 3 2]);
        chEstM(mergedIndices,:,:) = permute(reshape(permute(chEst(indices,:,:),[1 3 2]),nSCUnique,[],nSTS),[1 3 2]);
    end

end
