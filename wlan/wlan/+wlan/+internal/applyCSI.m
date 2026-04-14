function y = applyCSI(x,csi,NBPSCS)
%applyCSI Apply CSI bit-wise to demapped OFDM symbols
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = applyCSI(X,CSI,NBPSCS) apply CSI bit-wise to demapped bits, X,
%   given a column vector containing the CSI and NBPSCS. NBPSCS is the
%   number of bits per subcarrier per spatial-stream.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

numOFDMSym = size(x,2);
numSD = size(x,1)/NBPSCS;
y = reshape(reshape(x,NBPSCS,numSD,numOFDMSym).*reshape(csi,1,numSD),NBPSCS*numSD,numOFDMSym);

end
