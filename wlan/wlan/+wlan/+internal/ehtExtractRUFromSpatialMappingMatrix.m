function Q = ehtExtractRUFromSpatialMappingMatrix(cfgEHT)
%ehtExtractRUFromSpatialMappingMatrix Extract spatial mapping matrix for RU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Q = ehtExtractRUFromSpatialMappingMatrix(CFGEHT) returns the spatial
%   mapping matrix to apply to an RU for an EHT Trigger Based
%   configuration, when the spatial mapping matrix applies to the entire
%   242 tone bandwidth.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

allocationInfo = ruInfo(cfgEHT);
ruSize = sum(allocationInfo.RUSizes{1});
cbw = wlan.internal.cbwStr2Num(cfgEHT.ChannelBandwidth);
% EHT TB when 242 custom Q matrix is passed but we only need a smaller
% RU from it, e.g. 106 tone.
if cfgEHT.SpatialMapping==wlan.type.SpatialMapping.custom
    mappingMatrix = cfgEHT.SpatialMappingMatrix;
    if size(mappingMatrix,1) < 26 % Minimum Nst
        % Scalar, or Nsts-by-Ntx
        Q = mappingMatrix;
    else 
        % Nst-by-Nsts-by-Ntx
        if ruSize<size(mappingMatrix,1)
            % Assume spatial mapping matrix is full-band and extract RU of interest
            kActiveRU = wlan.internal.ehtRUSubcarrierIndices(cbw,allocationInfo.RUSizes{1},allocationInfo.RUIndices{1});
            kFullBand = wlan.internal.ehtRUSubcarrierIndices(cbw);
            activeIndexHE = wlan.internal.intersectRUIndices(kFullBand(:),kActiveRU);
            Q = mappingMatrix(activeIndexHE,:,:);
        else
            % If RU size is greater than or equal to the mapping
            % matrix provided use directly
            assert(ruSize==size(mappingMatrix,1));
            Q = mappingMatrix;
        end
    end
else
    % Direct, Fourier, Hadamard
    Q = 1;
end
end