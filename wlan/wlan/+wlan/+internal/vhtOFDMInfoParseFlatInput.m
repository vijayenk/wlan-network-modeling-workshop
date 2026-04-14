function [cbw,gi,osf] = vhtOFDMInfoParseFlatInput(fieldname,gifieldname,filename,varargin)
%vhtOFDMInfoParseFlatInput Parse inputs
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   [CBW,GI,OSF] = vhtOFDMInfoParseFlatInput(FIELDNAME,GIFIELDNAME,FILENAME,VARARGIN)
%   parses inputs VARARGIN to return the channel bandwidth CBW, guard
%   interval GI, and oversampling factor OSF.
%
%   FIELDNAME is the field of interest.
% 
%   GIFIELDNAME is the fieldname requiring the guard interval to be
%   specified.
% 
%   FILENAME is the calling filename.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

gi = 'Long'; % Default
cbw = wlan.internal.validateParam('CHANBW',varargin{1});
if strcmp(fieldname,gifieldname)
    if nargin<5
        % Require guard interval
        coder.internal.error('wlan:shared:ExpectedVHTGI',gifieldname);
    else
        gi = validateGuardInterval(varargin{2},filename);
        osf = parseOSF(varargin{3:end});
    end
else
    osf = parseOSF(varargin{2:end});
end
end

function gi = validateGuardInterval(in,fname)  
    if isempty(coder.target)
        gi = validatestring(in,{'Short','Long'},fname,'guard interval');
    else
        % Do not perform compile time check on type etc to allow for guard
        % interval to be optional in wlanHTOFDMInfo/wlanVHTOFDMInfo
        if ~(ischar(in) || isStringScalar(in)) || ~any(strcmp(in,{'Short','Long'}))
            coder.internal.error('wlan:shared:UnexpectedGI');
        end
        gi = char(in); % Force to char when string
    end
end

function osf = parseOSF(varargin)
    if isempty(coder.target)
        osf = wlan.internal.parseOSF(varargin{:});
    else
        % Treat GI as optional for codegen to as nnot required for all
        % fieldnames and codegen can't figure this out at compile time
        opArgs = {'GuardInterval'};
        nvNames = {'OversamplingFactor'};
        pStruct = coder.internal.parseInputs(opArgs,nvNames,[],varargin{:});
        osf = coder.internal.getParameterValue(pStruct.OversamplingFactor,1,varargin{:}); % Default 1
        validateattributes(osf,{'numeric'},{'scalar','>=',1},mfilename,'oversampling factor');
        osf = double(osf);
    end
end