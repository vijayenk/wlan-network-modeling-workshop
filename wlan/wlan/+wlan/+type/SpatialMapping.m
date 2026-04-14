classdef SpatialMapping < uint8
%SpatialMapping Enumeration for spatial mapping schemes
%
%   Use the SpatialMapping enumeration to set the SpatialMapping property
%   of a <a href="matlab:help('wlanEHTRU')">wlanEHTRU</a> object used within a <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> object.
%
%   SpatialMapping enumeration:
%
%   direct   - Use direct mapping for one-to-one mapping of space-time
%              streams with transmit antennas. In direct mapping each
%              space-time stream is transmitted on single antenna and there
%              is no interference between space-time streams.
%   hadamard - Use Hadamard matrix to mix space-time streams on all
%              avalible antennas.
%   fourier  - Use Fourier matrix to mix space-time streams on all
%              avalible antennas.
%   custom   - Use custom spatial mapping scheme.
%
%   % Example:
%   %  Create an MU-MIMO object for a 20 MHz channel bandwidth and set the
%   %  spatial mapping to Fourier.
%
%   cfgEHT = wlanEHTMUConfig('CBW20');
%   cfgEHT.NumTransmitAntennas = 2;
%   cfgEHT.RU{1}.SpatialMapping = wlan.type.SpatialMapping.fourier;
%   disp(cfgEHT.RU{1})
%
%   See also wlan.type.ChannelCoding, wlan.type.PostFECPaddingSource

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    enumeration
        direct (0)
        hadamard (1)
        fourier (2)
        custom (3)
    end

    methods(Static,Hidden)

        function retVal = addClassNameToEnumNames()

            % addClassNameToEnumNames specifies whether to add the class name
            % as a prefix to enumeration member names in generated code. This
            % is needed to avoid conflict of enum definition of 'direct' in
            % generated code and function prototype definitions in the lapack
            % library.
            retVal = true;
        end
    end

end
