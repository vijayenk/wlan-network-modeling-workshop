function Q = heExtractRUFromSpatialMappingMatrix(cfgHE)
%heExtractRUFromSpatialMappingMatrix Extract spatial mapping matrix for RU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Q = heExtractRUFromSpatialMappingMatrix(CFGHE) returns the spatial
%   mapping matrix to apply to an RU for an HE SU or HE Trigger Based
%   configuration, when the spatial mapping matrix applies to the entire
%   242 tone bandwidth.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

allocationInfo = ruInfo(cfgHE);
cbw = wlan.internal.cbwStr2Num(cfgHE.ChannelBandwidth);
if any(strcmp(packetFormat(cfgHE),{'HE-EXT-SU','HE-TB'}))
    % Deal with case for SU_EXT or TB when 242 custom Q matrix is
    % passed but we only need a smaller RU from it, e.g. 106 tone.
    if strcmp(cfgHE.SpatialMapping,'Custom')
        mappingMatrix = cfgHE.SpatialMappingMatrix;
        if size(mappingMatrix,1) < 26 % Minimum Nst
            % Scalar, or Nsts-by-Ntx
            Q = mappingMatrix;
        else 
            % Nst-by-Nsts-by-Ntx
            if allocationInfo.RUSizes<size(mappingMatrix,1)
                % Assume spatial mapping matrix is full-band and extract RU
                % of interest
                kActiveRU = wlan.internal.heRUSubcarrierIndices(cbw,allocationInfo.RUSizes,allocationInfo.RUIndices);
                kFullBand = wlan.internal.heRUSubcarrierIndices(cbw);
                activeIndexHE = wlan.internal.intersectRUIndices(kFullBand(:),kActiveRU);
                Q = mappingMatrix(activeIndexHE,:,:);
            else
                % If RU size is greater than or equal to the mapping
                % matrix provided use directly
                assert(allocationInfo.RUSizes==size(mappingMatrix,1));
                Q = mappingMatrix;
            end
        end
    else
        % Direct, Fourier, Hadamard
        Q = 1;
    end
else
    Q = cfgHE.SpatialMappingMatrix;
end

end