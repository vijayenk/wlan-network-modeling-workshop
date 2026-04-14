function perUserFields = defaultPerUserFields
%defaultPerUserFields returns a default per user field.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   PERUSERFIELDS = defaultPerUserFields() returns a structure the fields
%
%   MCS                 - Modulation coding scheme index in range [0, 11]
%   Length              - Length of the received PSDU
%   NumSpaceTimeStreams - Configure multiple streams of data (MIMO)
%   SpatialMapping      - Spatial mapping - "Direct" or "Fourier"
%   StationID           - Array of station identifiers that identify
%                         the STA or group of STAs that are supposed to
%                         receive an RU in HE-MU PPDU
%   TxPower	            - Specifies the transmission power of the node in dBm

%   Copyright 2022-2025 The MathWorks, Inc.

    perUserFields = struct('MCS', 0, 'Length', 0, ...
                'NumSpaceTimeStreams', 0, ...
                'SpatialMapping', "Direct", ...
                'StationID', 0, ...
                'TxPower', 0);
end
