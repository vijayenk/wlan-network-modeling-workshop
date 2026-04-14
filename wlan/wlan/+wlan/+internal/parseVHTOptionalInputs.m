function [muSpec,userNum,outNumSTSVec,params] = parseVHTOptionalInputs(caller,inNumSTSVec,varargin)
%parseVHTOptionalInputs Parse and validate optional inputs
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CALLER is the name of the calling function.
%
%   NUMSTSVEC is the default value for numSTSVec. The source of this value
%   changes based on the calling function, as follows:
%       wlanVHTDataRecover : numSTSVecDefault = cfgVHT.NumSpaceTimeStreams
%       wlanVHTSIGBRecover : numSTSVecDefault = size(chanEst,2)
%
%   The optional inputs are those passed by the user in the calling
%   function. These combinations of optional inputs are allowed, in which
%   the last combination listed in point (2) is allowed only when this
%   function is called by wlanVHTDataRecover.
%     1) length(varargin)==2 --> [userNum, numSTS]
%                                N-V pair
%     2) length(varargin)>=3 --> [userNum, numSTS, N-V pair]
%                                N-V pair
%                                [userNum, N-V pair]

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

    numInputs = length(varargin);

    % Set defaults for the optional inputs
    muSpec = 0;

    % The path to follow depends on the number of optional inputs
    if numInputs==0
        params = wlan.internal.parseOptionalInputs(caller,varargin{:});
        userNum = 1;
        outNumSTSVec = inNumSTSVec;
    elseif numInputs==1
        % Only one possible input allowed:
        %   1. userNum (wlanVHTDataRecover)

        if strcmp(caller,'wlanVHTSIGBRecover')
            % Validate and parse optional recovery inputs
            params = wlan.internal.parseOptionalInputs(caller,varargin{:});
            userNum = 1;
        else
            % Parse first input (userNum)
            userNum = varargin{1};
            muSpec = 1;

            % Validate and parse optional recovery inputs
            params = wlan.internal.parseOptionalInputs(caller);
        end
        outNumSTSVec = inNumSTSVec;
    elseif numInputs==2
        % Only two possible combinations of inputs allowed:
        %   1. [userNum,numSTS]
        %   2. N-V pair

        if isnumeric(varargin{1}) % Case 1
            validateattributes(varargin{1},{'numeric'},{'real','integer','scalar','>=',1,'<=',4},caller,'USERNUMBER');
            if isnumeric(varargin{2})
                wlan.internal.validateParam('NUMSTS',varargin{2},caller);
                userNum = varargin{1};
                outNumSTSVec = varargin{2};
                muSpec = 2;

                % If userNum>1, NUMSTS must be a vector
                coder.internal.errorIf(userNum > length(outNumSTSVec),['wlan:' caller ':InvalidUserNum'],length(outNumSTSVec));

                % Validate and parse optional recovery inputs
                params = wlan.internal.parseOptionalInputs(caller);
            else % Invalid case, for instance of type [userNum, Name]
                 % Validate optional recovery inputs
                params = wlan.internal.parseOptionalInputs(caller,varargin{2});
                userNum = 1;
                outNumSTSVec = inNumSTSVec;
            end
        else % Case 2
             % Validate and parse optional recovery inputs
            params = wlan.internal.parseOptionalInputs(caller,varargin{:});
            userNum = 1;
            outNumSTSVec = inNumSTSVec;
        end
    else % numInputs>=3
         % Only three possible combinations of inputs allowed:
         %   1. [userNum,numSTS,N-V pair]
         %   2. [userNum,N-V pair] (wlanVHTDataRecover)
         %   3. N-V pair

        if isnumeric(varargin{1}) % First input is userNum
            validateattributes(varargin{1},{'numeric'},{'real','integer','scalar','>=',1,'<=',4},caller,'USERNUMBER');
            userNum = varargin{1};
            if isnumeric(varargin{2}) % Second input is numSTS - Case 1
                wlan.internal.validateParam('NUMSTS',varargin{2},caller);
                outNumSTSVec = varargin{2};
                muSpec = 2;

                % If userNum>1, NUMSTS must be a vector
                coder.internal.errorIf(userNum > length(outNumSTSVec),['wlan:' caller ':InvalidUserNum'],length(outNumSTSVec));

                firstNVIndex = 3;
            else % Case 2
                outNumSTSVec = inNumSTSVec;
                if strcmp(caller,'wlanVHTSIGBRecover')
                    wlan.internal.validateParam('NUMSTS',varargin{2},caller);
                else
                    muSpec = 1;
                    firstNVIndex = 2;
                end
            end
        else % Only N-V pair - Case 3
            firstNVIndex = 1;
            userNum = 1;
            outNumSTSVec = inNumSTSVec;
        end

        % Validate and parse optional recovery inputs
        params = wlan.internal.parseOptionalInputs(caller,varargin{firstNVIndex:end});
    end
end
