function demod = wlanEHTDemodulate(rx,fieldname,cfg,varargin)
%wlanEHTDemodulate Demodulate EHT fields
%   SYM = wlanEHTDemodulate(RX,FIELDNAME,CFG) demodulates the received
%   time-domain signal RX using OFDM demodulation parameters appropriate
%   for the specified FIELDNAME.
%
%   SYM is the demodulated frequency-domain signal, returned as a complex
%   matrix or 3-D array of size Nst-by-Nsym-by-Nr. Nst is the number of
%   active (occupied) subcarriers in the field. Nsym is the number of OFDM
%   symbols. Nr is the number of receive antennas.
%
%   RX is the received time-domain signal, specified as a single or double
%   complex matrix of size Ns-by-Nr, where Ns is the number of time-domain
%   samples. If Ns is not an integer multiple of the OFDM symbol length for
%   the specified field, then mod(Ns,symbol length) trailing samples are
%   ignored.
%
%   FIELDNAME is the field to demodulate and must be 'L-LTF', 'L-SIG',
%   'RL-SIG', 'U-SIG', 'EHT-SIG', 'EHT-LTF', or 'EHT-Data'.
%
%   CFG is a format configuration object of type wlanEHTMUConfig, 
%   wlanEHTTBConfig, or wlanEHTRecoveryConfig.
%
%   SYM = wlanEHTDemodulate(RX,FIELDNAME,CFG,RUNUMBER) returns the
%   demodulated symbols for the resource unit (RU) of interest, RUNUMBER.
%
%   #  For an EHT MU OFDMA PPDU type, when FIELDNAME is 'EHT-LTF' or
%      'EHT-Data', RUNUMBER is required.
%   #  For a EHT MU non-OFDMA PPDU type, when FIELDNAME is 'EHT-LTF' or
%      'EHT-Data', RUNUMBER is not required.
%   #  For an EHT TB PPDU type RUNUMBER is not required.
%   #  When FIELDNAME is 'L-LTF', 'L-SIG', 'RL-SIG', 'U-SIG', or 'EHT-SIG',
%      RUNUMBER is not required.
%
%   RUNUMBER is not required for wlanEHTRecoveryConfig.
%
%   SYM = wlanEHTDemodulate(...,'OversamplingFactor',OSF) specifies the
%   optional oversampling factor of the waveform to demodulate. The
%   oversampling factor must be greater than or equal to 1. The default
%   value is 1. Specifying an oversampling factor greater than 1 uses a
%   larger FFT size to demodulate the oversampled waveform. The
%   oversampling factor must result in an integer number of samples in the
%   cyclic prefix.
%
%   SYM = wlanEHTDemodulate(...,'OFDMSymbolOffset',SYMOFFSET) specifies the
%   optional OFDM symbol sampling offset as a fraction of the cyclic prefix
%   length between 0 and 1, inclusive. When unspecified, a value of 0.75 is
%   used.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

narginchk(3,8);

% Validate rx and field name
validateattributes(rx,{'single','double'},{'2d','finite','nonempty'},mfilename,'rx');
fieldname = validatestring(fieldname,{'EHT-Data','EHT-LTF','EHT-SIG','U-SIG','RL-SIG','L-SIG','L-LTF'},mfilename,'field');
validateattributes(cfg,{'wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig'},{'scalar'},mfilename,'format configuration object');
numSamples = size(rx,1);
isEHTMU = isa(cfg,'wlanEHTMUConfig');

switch fieldname
    case {'EHT-Data','EHT-LTF'}
        allocInfo = ruInfo(cfg);
        mode = compressionMode(cfg);
        wlan.internal.mustBeDefined(mode,'CompressionMode'); % Check for undefined state
        if mode==0 && isEHTMU % EHT MU (OFDMA)
            if nargin>3 && isnumeric(varargin{1}) % For codegen
                % wlanEHTDemodulate(RX,FIELDNAME,CFG,RUNUMBER,...)
                ruNumber = varargin{1};
                wlan.internal.validateRUNumber(ruNumber,allocInfo.NumRUs);
                nvp = wlan.internal.demodNVPairParse(varargin{2:end});
                symOffset = nvp.SymOffset;
            else % RUNUMBER must be provided for OFDMA PPDU type
                coder.internal.error('wlan:shared:ExpectedRUNumberEHT');
            end
        else % EHT MU (Non-OFDMA), EHT TB or EHT Recovery
            ruNumber = 1; % RUNUMBER is ignored for non-OFDMA PPDU type
            if nargin>3 && isnumeric(varargin{1})
                % wlanEHTDemodulate(RX,FIELDNAME,CFG,RUNUMBER,...)
                nvp = wlan.internal.demodNVPairParse(varargin{2:end});
            else % wlanEHTDemodulate(RX,FIELDNAME,CFG,...)
                nvp = wlan.internal.demodNVPairParse(varargin{1:end});
            end
            symOffset = nvp.SymOffset;
        end
        cfgOFDM = wlanEHTOFDMInfo(fieldname,cfg,ruNumber,'OversamplingFactor',nvp.OversamplingFactor);
    otherwise % 'EHT-SIG','U-SIG','RL-SIG','L-SIG','L-LTF'
        if nargin>3 && isnumeric(varargin{1})
            nvp = wlan.internal.demodNVPairParse(varargin{2:end});
        else
            nvp = wlan.internal.demodNVPairParse(varargin{1:end});
        end
        symOffset = nvp.SymOffset;
        cfgOFDM = wlanEHTOFDMInfo(fieldname,cfg,1,'OversamplingFactor',nvp.OversamplingFactor);
end

switch fieldname
    case 'EHT-Data'
        % Validate input length
        wlan.internal.demodValidateMinInputLength(numSamples,cfgOFDM);

        % OFDM demodulate
        demod = wlan.internal.ofdmDemodulate(rx,cfgOFDM,symOffset);
    case 'EHT-LTF'
        demod = wlan.internal.ehtLTFDemodulate(rx,cfg.EHTLTFType,symOffset,cfgOFDM);
    case {'EHT-SIG','U-SIG','RL-SIG','L-SIG'}
        % Validate input length
        wlan.internal.demodValidateMinInputLength(numSamples,cfgOFDM);

        demod = wlan.internal.ofdmDemodulate(rx,cfgOFDM,symOffset);
    otherwise % 'L-LTF'
        assert(strcmp(fieldname,'L-LTF'))

        % Validate input length
        wlan.internal.demodValidateMinInputLength(numSamples,cfgOFDM);

        % Add extra L-SIG tones onto NumTones so we scale at receiver
        % the same for L-SIG field
        cfgOFDM.NumTones = cfgOFDM.NumTones+4*cfgOFDM.NumSubchannels;

        % Demodulate
        demod = wlan.internal.demodulateLLTF(rx,cfgOFDM,symOffset);
end

end

