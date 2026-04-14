classdef Constants
%Constants Constants used across the layers of WLAN node
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2022-2025 The MathWorks, Inc.

% Packet data types
properties (Constant)
    % Packet is empty
    PacketTypeEmpty = 0

    % Data containing IQ samples (Full MAC + Full PHY)
    DataTypeIQData = 1

    % Data containing MAC PPDU bits (Full MAC + Abstract PHY)
    DataTypeMACFrameBits = 2

    % Data containing MAC configuration structure (Abstract MAC + Abstract PHY)
    DataTypeMACFrameStruct = 3
end

% Standard types
properties (Constant)
    Std80211a = 0;
    Std80211g = 1;
    Std80211n = 2;
    Std80211ac = 3;
    Std80211ax = 4;
    Std80211be = 5;
end

% AC-TID mapping
properties (Constant)
    AC2TID = [3 1 5 7];
    TID2AC = [0 1 1 0 2 2 3 3];
end

% Frame types
properties (Constant)
    UnknownFrameType = 0;
    RTS = 1;
    CTS = 2;
    QoSData = 3;
    ACK = 4;
    BlockAck = 5;
    MURTSTrigger = 6;
    MUBARTrigger = 7;
    BasicTrigger = 8;
    QoSNull = 9;
    MultiSTABlockAck = 10;
    Beacon = 11;
    CFEnd = 12;
    Management = 101;
end
end
