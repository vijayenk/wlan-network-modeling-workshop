function validateEHTConfigObject(cfg)
%validateEHTConfigObject Validate EHT config object
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   validateEHTConfigObject(cfg) validates the EHT config object. The
%   config object must be wlanEHTMUConfig or wlanEHTTBConfig.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

validateattributes(cfg,{'wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig'},{},mfilename,'format configuration object');

end