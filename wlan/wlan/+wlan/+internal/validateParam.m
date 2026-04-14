function varargout = validateParam(prmName, prmValue, varargin)
%validateParam Validate WLAN parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   wlan.internal.validateParam(PRMNAME, PRMVALUE, CALLER) validates a
%   parameter value, PRMVALUE, for the parameter name, PRMNAME from the
%   calling fcn, CALLER. For shared messages, the CALLER input can be
%   avoided.
%
%   wlan.internal.validateParam(..., ERRID) validates using the specified
%   error message ID. Only the last part of the full mnemonic needs to be
%   specified to form the "wlan:CALLER:ERRID" ID.
%
%   varargout = wlan.internal.validateParam(...) optionally returns the
%   matching string from the options when validating a string.
%
%   Examples:
%       wlan.internal.validateParam('NUMSTS', numSTSVec, ...
%           'wlanVHTLTFDemodulate');
%
%       wlan.internal.validateParam('CHANBW', chanBW, ...
%           'wlanVHTLTFDemodulate', 'myErrID');
%
%       chanBW = wlan.internal.validateParam('CHANBW', chanBW);
%
%   Only supports parameter self validation. No cross-parameter validity as
%   yet.

%   Copyright 2016-2024 The MathWorks, Inc.

%#codegen

narginchk(2,4);
if nargin==2
    caller = 'shared'; % Use the shared catalog, by default
elseif nargin==3
    caller = varargin{1};    
else  % Override the default ID
    caller = varargin{1};    
    errID = varargin{2};
end

switch prmName
    case 'NUMSTS'
        % VHT Number of Space-time streams
        validateattributes(prmValue, {'numeric'}, {'real','integer','row','>=',1,'<=',8}, caller, prmName);

        if nargin<4    % Default ID
            errID = 'InvalidMUSTS';
        end
        coder.internal.errorIf(~isscalar(prmValue) && ...
            ((length(prmValue) > 4) || any(prmValue > 4) || sum(prmValue) > 8), ['wlan:shared:' errID], 4, 4, 8);
    case 'CHANBW'
        % HT/VHT Channel Bandwidth
        varargout{1} = validatestring(prmValue, ...
            {'CBW20', 'CBW40', 'CBW80', 'CBW160'}, caller, 'channel bandwidth');
        % Error on partial matches with validatestring
        coder.internal.errorIf(any(strcmpi(prmValue,{'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16'})), ...
                'wlan:shared:InvalidChanBW');
    case 'NONHTCHANBW'
        % Non-HT/HT/VHT Channel Bandwidth
        varargout{1} = validatestring(prmValue, ...
            {'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160' , 'CBW320'}, caller, 'channel bandwidth');
        % Error on partial matches with validatestring
        coder.internal.errorIf(any(strcmpi(prmValue,{'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16'})), ...
                'wlan:shared:InvalidNonHTChanBW');

    case 'NONHTEHTCHANBW'
        % Non-HT/EHT Channel Bandwidth
        varargout{1} = validatestring(prmValue, ...
            {'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160', 'CBW320'}, caller, 'channel bandwidth');
        % Error on partial matches with validatestring
        coder.internal.errorIf(any(strcmpi(prmValue,{'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16', 'CBW32'})), ...
                'wlan:shared:InvalidNonHTEHTChanBW');
    case 'S1GVHTCHANBW'
        % HT/VHT/S1G Channel Bandwidth
         varargout{1} = validatestring(prmValue, ...
             {'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16', 'CBW20', 'CBW40', 'CBW80', 'CBW160'}, caller, 'channel bandwidth');
    case 'NUMBPSCS'
        % Number of coded bits per symbol per spatial stream
        if nargin < 4   % Default ID
            errID = 'InvalidNUMBPSCS';
        end
        % Validate numBPSCS
        coder.internal.errorIf(~isnumeric(prmValue) || ~isscalar(prmValue) || ~any(prmValue == [1 2 4 6 8 10]), ...
            ['wlan:shared:' errID]);
    case 'NUMES'
        % Number of encoded streams
        if nargin < 4   % Default ID
            errID = 'InvalidNUMES';
        end
        % Validate numES
        coder.internal.errorIf(~isnumeric(prmValue) || ~isscalar(prmValue) || ~any(prmValue == [1:9, 12]), ...
            ['wlan:shared:' errID]);
        
        % Add more parameters
    case 'HTCHANBW'
        varargout{1} = validatestring(prmValue, {'CBW20', 'CBW40'}, caller, 'channel bandwidth');
        % Error on partial matches with validatestring
        coder.internal.errorIf(any(strcmpi(prmValue,{'CBW2', 'CBW4'})), ...
                'wlan:wlanHTSIGRecover:InvalidChanBW');
    case 'S1GCHANBW'
        % S1G Channel Bandwidth
        varargout{1} = validatestring(prmValue, {'CBW1','CBW2','CBW4','CBW8','CBW16'}, caller, 'channel bandwidth');
    case 'EHTCHANBW'
        % EHT Channel Bandwidth
        varargout{1} = validatestring(prmValue, ...
            {'CBW20', 'CBW40', 'CBW80', 'CBW160', 'CBW320'}, caller, 'channel bandwidth');
        % Error on partial matches with validatestring
        coder.internal.errorIf(any(strcmpi(prmValue,{'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16', 'CBW32'})), ...
                'wlan:shared:InvalidEHTChanBW');
    otherwise
        % Do nothing
end
    
end
