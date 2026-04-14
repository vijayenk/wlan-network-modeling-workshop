classdef wlanOFDMWaveformConfiguration < wirelessWaveformGenerator.wlanWaveformConfiguration
%

%   Copyright 2018-2025 The MathWorks, Inc.

    methods % constructor
        function obj = wlanOFDMWaveformConfiguration(parent)
            obj@wirelessWaveformGenerator.wlanWaveformConfiguration(parent); % call base constructor
        end

        function b = spectrumEnabled(~)
            b = true;
        end

        function b = timeScopeEnabled(~)
            b = false;
        end

        function b = constellationEnabled(~)
            b = false;
        end

        function updateWindowTransitionTime(obj, ~)
            genDialog = obj.getGenerationDialog();
            if ~isempty(genDialog) && isa(genDialog, 'wirelessWaveformGenerator.wlanGenerationConfiguration')
                windowTimeChanged(genDialog, obj); % check Window Time with new BW value
            end
        end
    end
end
