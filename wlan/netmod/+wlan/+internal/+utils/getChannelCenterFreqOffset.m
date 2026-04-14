function centerFreqOffset = getChannelCenterFreqOffset(operatingBW)
%GETCHANNELCENTERFREQOFFSET Get the center frequency offset of all possible
%bandwdiths given a transmitter or receiver operating bandwidth
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%

%   Copyright 2024-2025 The MathWorks, Inc.

centerFreqOffset40 = [];
centerFreqOffset80 = [];
centerFreqOffset160 = [];
centerFreqOffset320 = [];

numSubchannels20 = operatingBW/20;
if numSubchannels20 == 1
    centerFreqOffset20 = 0;
else
    centerFreqOffset20 = 10e6 * (-numSubchannels20+1:2:numSubchannels20);
end

if operatingBW >= 40
    numSubchannels40 = operatingBW/40;
    if numSubchannels40 == 1
        centerFreqOffset40 = 0;
    else
        centerFreqOffset40 = 20e6 * (-numSubchannels40+1:2:numSubchannels40);
    end
end

if operatingBW >= 80
    numSubchannels80 = operatingBW/80;
    if numSubchannels80 == 1
        centerFreqOffset80 = 0;
    else
        centerFreqOffset80 = 40e6 * (-numSubchannels80+1:2:numSubchannels80);
    end
end

if operatingBW >= 160
    numSubchannels160 = operatingBW/160;
    if numSubchannels160 == 1
        centerFreqOffset160 = 0;
    else
        centerFreqOffset160 = 80e6 * (-numSubchannels160+1:2:numSubchannels160);
    end
end

if operatingBW == 320
    centerFreqOffset320 = 0;
end

centerFreqOffset = cell(5,1);
centerFreqOffset{1} = centerFreqOffset20;
centerFreqOffset{2} = centerFreqOffset40;
centerFreqOffset{3} = centerFreqOffset80;
centerFreqOffset{4} = centerFreqOffset160;
centerFreqOffset{5} = centerFreqOffset320;
end
