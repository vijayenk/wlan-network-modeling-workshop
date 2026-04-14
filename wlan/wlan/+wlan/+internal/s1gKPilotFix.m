function k = s1gKPilotFix(chanBW,varargin)
%KPilotFix Set of fixed pilot subcarrier indices for S1G
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%    K = s1gKPilotFix(CHANBW) returns a set of subcarrier indices as a
%    column vector containing pilots for a given channel bandwidth
%    character vector CHANBW.
%
%    K = s1gKPilotFix(CHANBW,NSYM) returns the subcarrier indices for each
%    pilot for each OFDM symbol. In this case K is a matrix with NSYM
%    columns.

%   Copyright 2016 The MathWorks, Inc.

%#codegen

narginchk(1,2);

% Section 24.3.9.10, IEEE P802.11ah/D5.0
switch chanBW
    case 'CBW1'
        k = [-7; 7];
    case 'CBW2'
        k = [-21; -7; 7; 21];
    case 'CBW4'
        k = [-53; -25; -11; 11; 25; 53];
    case 'CBW8'
        k = [-103; -75; -39; -11; 11; 39; 75; 103];
    otherwise % 'CBW16'
        k = [-231; -203; -167; -139; -117; -89; -53; -25; 25; 53; 89; 117; 139; 167; 203; 231];
end
% Return pilots for number of OFDM symbols requested
if nargin>1
    Nsym = varargin{1};
    k = repmat(k,1,Nsym);
end

end