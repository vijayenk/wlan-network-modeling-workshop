function macAndPHYAbstraction(node, macAndPHYCfg)
%macAndPHYAbstraction Validate MAC/PHY abstractions w.r.t the link/device configuration
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   macAndPHYAbstraction(NODE, MACANDPHYCFG) validates MAC/PHY abstractions
%   w.r.t the specified link/device configuration, MACANDPHYCFG.
%
%   NODE is an object of type wlanNode.
%
%   MACANDPHYCFG is an object of type wlanDeviceConfig or wlanLinkConfig.

%   Copyright 2025 The MathWorks, Inc.

if ~node.DisableValidation
    % MAC frame abstraction is allowed only when PHY is abstracted
    if (strcmp(node.PHYModel, "full-phy") && strcmp(node.MACModel, "full-mac-with-frame-abstraction"))
        error(message('wlan:wlanNode:InvalidMACandPHYCombination'));
    end

    % Full MAC frame generation and decoding is not supported for multiuser
    % transmission
    if strcmp(node.MACModel, "full-mac") && any(strcmp([macAndPHYCfg(:).TransmissionFormat], "HE-MU-OFDMA"))
        error(message('wlan:wlanNode:UnsupportedMACModelForOFDMA'));
    end

    % ACI modeling is only supported for full-PHY
    if (any(~strcmpi([macAndPHYCfg(:).InterferenceModeling], 'co-channel')) && ~strcmp(node.PHYModel, "full-phy"))
        error(message('wlan:wlanNode:InterferenceModelingMustBeFullPHY'));
    end
end
end