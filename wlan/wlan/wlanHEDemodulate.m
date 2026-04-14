function demod = wlanHEDemodulate(rx,fieldname,varargin)
%wlanHEDemodulate Demodulate HE fields
%   SYM = wlanHEDemodulate(RX,FIELDNAME,CFG) demodulates the time-domain
%   received signal RX using OFDM demodulation parameters appropriate for
%   the specified FIELDNAME.
%
%   SYM is the demodulated frequency-domain signal, returned as a complex
%   matrix or 3-D array of size Nst-by-Nsym-by-Nr. Nst is the number of
%   active (occupied) subcarriers in the field. Nsym is the number of OFDM
%   symbols. Nr is the number of receive antennas.
%
%   RX is the received time-domain signal, specified as a single or double
%   complex matrix of size Ns-by-Nr, where Ns represents the number of
%   time-domain samples. If Ns is not an integer multiple of the OFDM
%   symbol length for the specified field, then mod(Ns,symbol length)
%   trailing samples are ignored.
%
%   FIELDNAME is the field to demodulate and must be 'L-LTF', 'L-SIG',
%   'RL-SIG', 'HE-SIG-A', 'HE-SIG-B', 'HE-LTF', or 'HE-Data'.
%
%   CFG is a format configuration object of type wlanHESUConfig,
%   wlanHEMUConfig, wlanHETBConfig, or wlanHERecoveryConfig. When
%   wlanHEMUConfig is provided and FIELDNAME is 'HE-LTF' or 'HE-Data' an
%   additional RU number argument is required as described below.
%
%   When CFG is a wlanHETBConfig object and the FeedbackNDP property
%   is true, the function interleaves the symbols for active and
%   complementary tone sets for the specified value of the RUToneSetIndex
%   property in accordance with Table 27-32 of IEEE Std 802.11ax-2021.
%
%   SYM = wlanHEDemodulate(RX,HEMUFIELD,CFGHEMU,RUNUMBER) returns the
%   demodulated symbols for the resource unit (RU) of interest for a
%   multi-user configuration.
%
%   HEMUFIELD is 'HE-Data' or 'HE-LTF'.
%   CFGHEMU is a format configuration object of type wlanHEMUConfig.
%   RUNUMBER is the number of the RU of interest.
%
%   When a format configuration object is not available, individual fields
%   can be demodulated using the below syntaxes:
%
%   SYM = wlanHEDemodulate(RX,'HE-Data',CHANBW,HEGI,RU) returns the
%   demodulated symbols for the resource unit (RU) of interest for a
%   multi-user configuration. If RU is not specified a full band
%   configuration is assumed.
%
%   CHANBW must be 'CBW20', 'CBW40', 'CBW80', or 'CBW160'. HEGI is the
%   guard interval in microseconds and must be one of 0.8, 1.6, and 3.2. RU
%   is a row vector specifying the RU information [size index]. Size must
%   be one of 26, 52, 106, 242, 484, 996 or 1992, and must be appropriate
%   for the specified channel bandwidth.
%
%   SYM = wlanHEDemodulate(RX,'HE-LTF',CHANBW,HEGI,LTFTYPE,RU) returns the
%   demodulated symbols for the resource unit (RU) of interest for a
%   multi-user configuration. If RU is not specified a full band
%   configuration is assumed.
%
%   LTFTYPE is the HE-LTF type and is 1,2 or 4.
%
%   SYM = wlanHEDemodulate(RX,PREHEFIELD,CHANBW) returns the demodulated
%   symbols for pre-HE fields.
%
%   PREHEFIELD is one of 'L-LTF','L-SIG','RL-SIG','HE-SIG-A','HE-SIG-B'.
%
%   SYM = wlanHEDemodulate(...,'OversamplingFactor',OSF) specifies the
%   optional oversampling factor of the waveform to demodulate. The
%   oversampling factor must be greater than or equal to 1. The default
%   value is 1. When you specify an oversampling factor greater than 1, the
%   function uses a larger FFT size to demodulate the oversampled waveform.
%   The oversampling factor must result in an integer number of samples in
%   the cyclic prefix.
%
%   SYM = wlanHEDemodulate (...,'OFDMSymbolOffset',SYMOFFSET) specifies the
%   optional OFDM symbol sampling offset as a fraction of the cyclic prefix
%   length between 0 and 1, inclusive. When unspecified, a value of 0.75 is
%   used.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

narginchk(3,10);

% Validate rx and field name
validateattributes(rx,{'single','double'},{'2d','finite','nonempty'},mfilename,'rx');
fieldname = validatestring(fieldname,{'HE-Data','HE-LTF','HE-SIG-B','HE-SIG-A','RL-SIG','L-SIG','L-LTF'},mfilename,'FIELDNAME');
numSamples = size(rx,1);

coder.internal.assert(coder.internal.isConst(fieldname),'wlan:shared:FieldNameMustBeConstant');

switch fieldname
  case 'HE-Data'
    if isa(varargin{1},'wlanHESUConfig') || isa(varargin{1},'wlanHETBConfig') || isa(varargin{1},'wlanHERecoveryConfig')
        % wlanHEDemodulate(RX,'HE-Data',CFG)
        nvp = parseOSFWithOptionalNumeric(nargin,varargin{:});
        cfgOFDM = wlanHEOFDMInfo('HE-Data',varargin{:});
    elseif isa(varargin{1},'wlanHEMUConfig')
        % wlanHEDemodulate(RX,'HE-Data',CFGMU,RUNUMBER,...)
        if nargin<4
            coder.internal.error('wlan:shared:ExpectedRUNumberHE');
            return;
        else
            nvp = wlan.internal.demodNVPairParse(varargin{3:end});
            cfgOFDM = wlanHEOFDMInfo('HE-Data',varargin{:});
        end
    else
        if nargin>4 && isnumeric(varargin{3})
            % wlanHEDemodulate(RX,'HE-Data',CHANBW,GI,RU,...)
            nvp = wlan.internal.demodNVPairParse(varargin{4:end});
            cfgOFDM = wlanHEOFDMInfo('HE-Data',varargin{:});
        else
            % wlanHEDemodulate(RX,'HE-Data',CHANBW,GI,...)
            if nargin<4
                coder.internal.error('wlan:shared:ExpectedGI');
                return;
            else
                nvp = wlan.internal.demodNVPairParse(varargin{3:end});
                cfgOFDM = wlanHEOFDMInfo('HE-Data',varargin{:});
            end
        end
    end

    % Validate input length
    wlan.internal.demodValidateMinInputLength(numSamples,cfgOFDM);

    % OFDM demodulate
    demod = wlan.internal.ofdmDemodulate(rx,cfgOFDM,nvp.SymOffset);

  case 'HE-LTF'
    isaHERecoveryConfig = isa(varargin{1},'wlanHERecoveryConfig');
    if isa(varargin{1},'wlanHESUConfig') || isa(varargin{1},'wlanHETBConfig') || isaHERecoveryConfig
        % wlanHEDemodulate(RX,'HE-LTF',CFG)
        cfgOFDM = wlanHEOFDMInfo('HE-LTF',varargin{:});
        nvp = parseOSFWithOptionalNumeric(nargin,varargin{:});
        cfg = varargin{1};
        HELTFType = cfg.HELTFType;
        coder.internal.errorIf(isaHERecoveryConfig && HELTFType==-1,'wlan:wlanHEDemodulate:InvalidLTFType'); % HELTFType undefined
    elseif isa(varargin{1},'wlanHEMUConfig')
        % wlanHEDemodulate(RX,'HE-LTF',CFGMU,RUNUMBER,...)
        if nargin<4
            coder.internal.error('wlan:shared:ExpectedRUNumberHE');
            return;
        else
            nvp = wlan.internal.demodNVPairParse(varargin{3:end});
            cfgOFDM = wlanHEOFDMInfo('HE-LTF',varargin{:});
            cfg = varargin{1};
            HELTFType = cfg.HELTFType;
        end
    else
        % wlanHEDemodulate(RX,'HE-LTF',CHANBW,GI,LTFTYPE,...)
        if nargin<4
            coder.internal.error('wlan:shared:ExpectedGI');
            return;
        elseif nargin<5
            coder.internal.error('wlan:wlanHEDemodulate:ExpectedLTFType');
            return;
        elseif nargin > 5 && ~(ischar(varargin{4}) || isstring(varargin{4}))
            % wlanHEDemodulate(RX,'HE-LTF',CHANBW,GI,LTFTYPE,RU,...)
            chanBW = varargin{1};
            gi = varargin{2};
            ru = varargin{4};
            nvp = wlan.internal.demodNVPairParse(varargin{5:end});
            cfgOFDM = wlanHEOFDMInfo('HE-LTF',chanBW,gi,ru,varargin{5:end});
        else
            % wlanHEDemodulate(RX,'HE-LTF',CHANBW,GI,LTFTYPE,...)
            nvp = wlan.internal.demodNVPairParse(varargin{4:end});
            cfgOFDM = wlanHEOFDMInfo('HE-LTF',varargin{1:2},varargin{4:end});
        end
        HELTFType = varargin{3};
        if ~isnumeric(HELTFType) || ~isscalar(HELTFType) || ~ismember(HELTFType,[1 2 4])
            coder.internal.error('wlan:wlanHEDemodulate:InvalidLTFType');
        end
    end

    demod = wlan.internal.ehtLTFDemodulate(rx,HELTFType,nvp.SymOffset,cfgOFDM);
  case {'HE-SIG-B','HE-SIG-A','RL-SIG','L-SIG'}
    % wlanHEDemodulate(RX,'HE-SIG-A',CFG,...)
    % wlanHEDemodulate(RX,'HE-SIG-A',CHANBW,...)
    nvp = parseOSFWithOptionalNumeric(nargin,varargin{:});
    cfgOFDM = wlanHEOFDMInfo(fieldname,varargin{:});

    % Validate input length
    wlan.internal.demodValidateMinInputLength(numSamples,cfgOFDM);

    demod = wlan.internal.ofdmDemodulate(rx,cfgOFDM,nvp.SymOffset);

  otherwise % 'L-LTF'
    assert(strcmp(fieldname,'L-LTF'))
    % wlanHEDemodulate(RX,'L-LTF',CFG,...)
    % wlanHEDemodulate(RX,'L-LTF',CHANBW,...)
    nvp = parseOSFWithOptionalNumeric(nargin,varargin{:});
    cfgOFDM = wlanHEOFDMInfo(fieldname,varargin{:});

    % Validate input length
    wlan.internal.demodValidateMinInputLength(numSamples,cfgOFDM);

    % Add extra L-SIG tones onto NumTones so we scale at receiver
    % the same for L-SIG field
    cfgOFDM.NumTones = cfgOFDM.NumTones+4*cfgOFDM.NumSubchannels;

    % Demodulate
    demod = wlan.internal.demodulateLLTF(rx,cfgOFDM,nvp.SymOffset);
end

end

function nvp = parseOSFWithOptionalNumeric(numInputs,varargin)
    if numInputs>3 & isnumeric(varargin{2})
        nvp = wlan.internal.demodNVPairParse(varargin{3:end});
    else
        nvp = wlan.internal.demodNVPairParse(varargin{2:end});
    end
end

