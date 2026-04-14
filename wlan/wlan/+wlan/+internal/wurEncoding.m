function seqEncoding = wurEncoding(bits,dataRate)
%wurEncoding WUR Encoding
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   seqEncoding = wurEncoding(bits,dataRate) returns the encoded sequence
%   for WUR Data fields.
%
%   SEQENCODING is a vector containing the encoded bits of 0 and 1.
%
%   BITS is a column vector, which specifies the bits of 0 and 1 to be
%   encoded.
%
%   DATARATE specifies the transmission rate as character vector or string 
%   and must be 'LDR', or 'HDR'.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

if strcmp(dataRate,'LDR')
    % IEEE P802.11ba/D8.0, December 2020, Table 30-9
    encBitTable = [1 0 1 0; 0 1 0 1]; % First row = 0, second row = 1
else
    % IEEE P802.11ba/D8.0, December 2020, Table 30-10
    encBitTable = [1 0; 0 1]; % First row = 0, second row = 1
end

% Map input bits to encoded bits
seqEncoding = zeros(size(encBitTable,2),numel(bits));
seqEncoding(:,bits==1) = repmat(encBitTable(2,:).',1,sum(bits==1));
seqEncoding(:,bits==0) = repmat(encBitTable(1,:).',1,sum(bits==0));
seqEncoding = seqEncoding(:);

end
