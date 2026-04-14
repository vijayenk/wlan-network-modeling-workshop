function validateHEConfigObject(cfg)
%validateHEConfigObject Validate HE config object
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   validateHEConfigObject(cfg) validates the HE config object. The config
%   object must be wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig, or
%   wlanHERecoveryConfig.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

validateattributes(cfg,{'wlanHESUConfig','wlanHEMUConfig','wlanHETBConfig','wlanHERecoveryConfig'},{},mfilename,'format configuration object');

end