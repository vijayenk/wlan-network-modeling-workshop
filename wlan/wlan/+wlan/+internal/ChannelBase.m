classdef (Hidden) ChannelBase < matlab.System
%ChannelBase Filter input signal through a TGn and TGac fading channel
%   The implementation is based on TGn, TGac, TGah and TGax channel models,
%   as specified by the IEEE 802.11 Wireless LAN Working group [1,2,3,4].
%   The power delay profile, spatial correlation and Doppler filter
%   coefficients values are based on TGn Implementation note version 3.2 -
%   May 2004.
%
%   %   References:
%   [1] Erceg, V. et al. "TGn Channel Models."  Doc. IEEE 802.11-03/940r4.
%   [2] Briet, G. et al. "TGac Channel Model Addendum." Doc. IEEE 802.11-09/0308r12.
%   [3] Porat, R, Sk. Yong, K. Doppler. "TGah Channel Model." IEEE 802.11-11/0968r4.
%   [4] Jianhan, L. et al. "IEEE 802.11ax Channel Model Document". IEEE 802.11-14/0882r4.

% Copyright 2015-2025 The MathWorks, Inc.

%#codegen

properties (Nontunable)
    %DelayProfile Channel propagation condition
    %   Specify the Delay profile model of WLAN multipath fading channel as
    %   one of 'Model-A' | 'Model-B' | 'Model-C' | 'Model-D' | 'Model-E' |
    %   'Model-F' | 'None'. The default is 'Model-B'.
    DelayProfile {matlab.system.mustBeMember(DelayProfile,{'Model-A','Model-B','Model-C','Model-D','Model-E','Model-F','None'})} = 'Model-B';
    %LargeScaleFadingEffect Large scale fading effect
    %   Specify the large scale fading effect in WLAN multipath fading
    %   channel as one of 'None' | 'Pathloss' | 'Shadowing' | 'Pathloss and
    %   shadowing'. The default is 'None'.
    LargeScaleFadingEffect = 'None';
    %TransmitReceiveDistance Distance between transmitter and receiver (m)
    %   Specify the separation between transmitter and receiver in meters.
    %   Used to compute the path loss, and to determine whether the channel
    %   has LOS or NLOS condition. The path loss and standard deviation of
    %   shadow fading loss is dependent on the separation between the
    %   transmitter and the receiver. The default is 3.
    TransmitReceiveDistance = 3;
    %PowerLineFrequency Power line frequency (Hz)
    %   Specify the power line frequency as one of '50Hz' | '60Hz'. The
    %   power line frequency is 60Hz in US and 50Hz in Europe. This
    %   property only applies when DelayProfile is set to Model-D or
    %   Model-E. The default is 60Hz.
    PowerLineFrequency = '60Hz';
    %RandomStream Source of random number stream
    %   Specify the source of the random number stream as one of 'Global
    %   stream' | 'mt19937ar with seed'. If you set this property to
    %   'Global stream', the current global random number stream is used
    %   for random number generation. In this case the reset function
    %   resets the channel filter and creates a new channel realization. If
    %   you set this property to 'mt19937ar with seed', the mt19937ar
    %   algorithm is used for random number generation. In this case the
    %   reset method not only resets the filters but also re-initializes
    %   the random number stream to the value of the Seed property. The
    %   default value of this property is 'Global stream'.
    RandomStream = 'Global stream';
    %Seed Initial seed
    %   Specify the initial seed of a mt19937ar random number generator
    %   algorithm as a double precision, real, nonnegative integer scalar.
    %   This property applies when you set the RandomStream property to
    %   'mt19937ar with seed'. The Seed is to re-initialize the mt19937ar
    %   random number stream in the reset method. The default value of this
    %   property is 73.
    Seed = 73;
    %OutputDataType PATHGAINS data type when ChannelFiltering is false
    %  Specify the PATHGAINS data type as either 'single' or 'double' when
    %  ChannelFiltering is false. The default value of this property is
    %  'double'.
    OutputDataType = 'double';

    %NormalizePathGains Normalize average path gains to 0 dB
    %   Set this property to true to normalize the fading processes such
    %   that the total power of the path gains, averaged over time, is 0dB.
    %   The default is true.
    NormalizePathGains (1, 1) logical = true;
    %FluorescentEffect Enable fluorescent effect
    %   Set this property to add fluorescent effect. This property is only
    %   applicable for DelayProfile, Model-D and Model-E. The default is
    %   true.
    FluorescentEffect (1, 1) logical = true;
    %NormalizeChannelOutputs Normalize output by number of receive antennas
    %   Set this property to true to normalize the channel outputs by the
    %   number of receive antennas. The default is true.
    NormalizeChannelOutputs (1, 1) logical = true;
    %PathGainsOutputPort Output channel path gains
    %   Set this property to true to output the channel path gains of the
    %   underlying fading process. The default value of this property is
    %   false.
    PathGainsOutputPort (1, 1) logical = false;
    %ChannelFiltering Perform filtering of input signal
    %   Set this property to false to disable channel filtering. If set to
    %   false then the step method will not accept an input signal and the
    %   duration of the fading process realization will be controlled by
    %   the NumSamples property (at the sampling rate given by the
    %   SampleRate property). The step method output will not include an
    %   output signal, only the path gains. The default value of this
    %   property is true.
    ChannelFiltering (1, 1) logical = true;
end

properties (Access = private,Nontunable)
    % Number of transmit antennas
    pNt;
    % Number of receive antennas
    pNr;
    % Number of links, NL = pNt*pNr
    pNumLinks;
    % Channel sampling frequency
    pFc;
    % Normalized channel sampling rate
    pDoppler;
    % Doppler filter weights
    pNumeratorB;
    pDenominatorB;
    pNumeratorS;
    pDenominatorS;
    % Number of multipaths
    pNumPaths;
    % Antenna correlation
    pAntennaCorrelation23b;
    % Check for static channel
    pIsStaticChannel;
    % Power line frequency
    pPowerLineFrequency;
    % Default shadowing value
    pDefaultShadowFading;
    % Include Fluorescent Effect
    pInFluorescentEffect;
    % Rician K factor in decibels
    pKfactor;
    % Path power
    pPathPower;
    % Path delays
    pPathDelays;
    % Input data type
    pInputDataType = 'double';
end

properties (Access = private)
    % Rician LOS component
    pRicianLOS;
    % Rician NLOS component
    pRicianNLOS;
    % Running Time Instance
    pRunningTimeInstant;
    % Index for oversampled channel samples
    pOversampledFadingTime;
    % Matrix to store the fading samples before interpolation
    pOversampledFadingMatrix;
    % Vector of channel samples at channel sampling rate
    pFadingTime;
    % White Gaussian noise state
    pRNGStream
    % Seeding state of legacy generator
    pLegacyState;
    % Filter state
    pFilterState;
    % Random phase
    pRandomInterfererToCarrierRatio;
    % State retention
    pLastTwoRows;
    % Fading offset
    pFadingOffset;
    % Looping variables
    pRunningTime;
    % Dummy offset
    pOffset;
    % Fluorescent effect random phase
    pRandomPhase;
    % Large scale losses
    pLargeScaleLosses;
    % Stream
    pStream;
    % Static channel path gains that stay constant for each input frame
    pStaticChannelPathGains;
    % Channel filter object
    cChannelFilter;
    % Path power
    pPathPowerdBs;
    % ShadowFading in decibels
    pShadowFading = 0;
    % Path loss in decibels
    pPathloss = 0;
end

properties (Access = protected,Nontunable)
    % Legacy generator
    pLegacyGenerator;
end

properties(Constant,Hidden)
    RandomStreamSet = matlab.system.StringSet({'Global stream','mt19937ar with seed'});
    DelayProfileSet = matlab.system.StringSet({'Model-A','Model-B','Model-C','Model-D','Model-E','Model-F','None'}); % Use for tab complete. Use property definition for validation
    LargeScaleFadingEffectSet = matlab.system.StringSet({'None','Pathloss','Shadowing','Pathloss and shadowing'});
    PowerLineFrequencySet = matlab.system.StringSet({'50Hz','60Hz'});
    OutputDataTypeSet = matlab.system.StringSet({'single','double'});
end

methods
    function obj = ChannelBase(varargin) % Constructor
        setProperties(obj,nargin,varargin{:});
        obj.pPathPowerdBs = 0;
    end

    function set.TransmitReceiveDistance(obj,val)
        propName = 'TransmitReceiveDistance';
        validateattributes(val,{'numeric'},{'real','scalar','>',0,'finite'},[class(obj) '.' propName],propName);  
        obj.TransmitReceiveDistance = val;
    end

    function set.Seed(obj, seed)
        propName = 'Seed';
        validateattributes(seed,{'double'},{'real','scalar','integer','nonnegative','finite'},[class(obj) '.' propName],propName); %#ok<*EMCA
        obj.Seed = seed;
    end
end

methods(Access = protected)
    function num = getNumInputsImpl(obj)
        if obj.ChannelFiltering
            num = 1;
        else
            num = 0;
        end
    end

    function num = getNumOutputsImpl(obj)
        if obj.ChannelFiltering
            num = 1+obj.PathGainsOutputPort;
        else
            num = 1;
        end
    end

    function varargout = isOutputFixedSizeImpl(obj)
        if propagatedInputFixedSize(obj,1)
            varargout = {true};
        else
            varargout = {false};
        end

        if obj.PathGainsOutputPort
            varargout{2} = propagatedInputFixedSize(obj,1);
        end
    end

    function varargout = getOutputSizeImpl(obj)
        Nt = obj.NumTransmitAntennas;
        Nr = obj.NumReceiveAntennas;

        % Check maximum size for the signal input, which is only available in the block propagators.
        inSigMaxDim = propagatedInputSize(obj,1);
        coder.internal.errorIf((length(inSigMaxDim)~=2) || (inSigMaxDim(2)~=Nt),'wlan:wlanChannel:InvalidBlkSignalInput');

        % Set block output (max) dimension
        Ns = inSigMaxDim(1);
        varargout = {[Ns,Nr]};

        if obj.PathGainsOutputPort
            NP = getNumMultipaths(obj);
            varargout{2} = [Ns,NP,Nt,Nr];
        end
    end

    function varargout = getOutputDataTypeImpl(obj)
        varargout = {propagatedInputDataType(obj,1)};
        if obj.PathGainsOutputPort
            varargout{2} = propagatedInputDataType(obj,1);
        end
    end

    function varargout = isOutputComplexImpl(obj)
        varargout = {true};
        if obj.PathGainsOutputPort
            varargout{2} = true;
        end
    end

    function validateInputsImpl(obj,x)
        if obj.ChannelFiltering
            validateattributes(x,{'single','double'},{'2d','finite','ncols',obj.NumTransmitAntennas},[class(obj) '.' 'Signal input'],'Signal input');    
        end
    end

    function setupImpl(obj,varargin)
    % Initialization of TGn, TGac, TGah and TGax channel model parameters

        % Get input data type: double or single
        if obj.ChannelFiltering == true
            obj.pInputDataType = class(varargin{1});
        else
            obj.pInputDataType = obj.OutputDataType;
        end

        out = getInfoParameters(obj);

        % Computation of PDP for LOS and NLOS scenario
        ricianComponents(obj,out.PathPower,out.TxLOSRadians,out.RxLOSRadians);

        % Setup filter weights (Doppler filter coefficients)
        obj.pNumeratorB = [2.785150513156437e-04
                          -1.289546865642764e-03
                           2.616769929393532e-03
                          -3.041340177530218e-03
                           2.204942394725852e-03
                          -9.996063557790929e-04
                           2.558709319878001e-04
                          -2.518824257145505e-05];
        obj.pDenominatorB = [1.000000000000000
                            -5.945307133332568
                             1.481117656568614e+01
                            -1.985278212976179e+01
                             1.520727030904915e+01
                            -6.437156952794267
                             1.279595585941577
                            -6.279622049460144e-02];
        obj.pNumeratorS = [7.346653645411014e-02
                          -2.692961866120396e-01-3.573876752780644e-02i
                           5.135568284321728e-01+1.080031147197969e-01i
                          -5.941696436704196e-01-1.808579163219880e-01i
                           4.551285303843579e-01+1.740226068499579e-01i
                          -2.280789945309740e-01-1.111510216362428e-01i
                           7.305274345216785e-02+4.063385976397657e-02i
                          -1.281829045132903e-02-9.874529878635624e-03i];
        obj.pDenominatorS = [1.0
                            -4.803186161814090e+00-6.564741337993197e-01i
                             1.083699602445439e+01+2.655291948209460e+00i
                            -1.461669273797422e+01-5.099798708358494e+00i
                             1.254720870662511e+01+5.723905805435745e+00i
                            -6.793962089799931e+00-3.887940726966912e+00i
                             2.107762007599925e+00+1.503178356895452e+00i
                            -2.777250532557400e-01-2.392692168502482e-01i];

        setupRNG(obj);
    end

    function setupRNG(obj)
        if ~strcmp(obj.RandomStream,'Global stream')
            if coder.target('MATLAB')
                obj.pRNGStream = RandStream('mt19937ar','Seed',obj.Seed);
            else
                obj.pRNGStream = coder.internal.RandStream('mt19937ar','Seed',obj.Seed);
            end
        end

        if obj.pLegacyGenerator && coder.target('MATLAB')
            obj.pStream = RandStream.getGlobalStream;
            % The obj.pLegacyState is used to initialize the legacy version
            % of the code. The legacy implementation is used for testing
            % only. The legacy implementation compares the channel samples
            % with actual Laurent model. Unlike the shipping version the
            % legacy implementation generates the noise sample row wise.
            obj.pLegacyState = obj.pStream.State;
        end
    end

    function resetRNG(obj)
    % Reset random number generator if it is not a global stream
        if ~strcmp(obj.RandomStream,'Global stream')
            reset(obj.pRNGStream,obj.Seed);
        end
    end

    function resetImpl(obj)
        resetRNG(obj);
        wgnoise = generateWGNoise(obj);
        obj.pShadowFading = wgnoise(1,1).*obj.pDefaultShadowFading;

        % Initialize Doppler filter
        filterOrder = 7;
        obj.pFilterState = complex(zeros(filterOrder,obj.pNt*obj.pNr*obj.pNumPaths));

        % Initialize the filter in order to avoid transient state
        temp = generateNoiseSamples(obj,1000); %#ok<NASGU>

        % Initialization of fluorescent effects random variables
        GaussianStandardDeviation = 0.0107;
        GaussianMean = 0.0203;

        % Noise generation
        wgnoise = generateWGNoise(obj);

        obj.pRandomInterfererToCarrierRatio = (wgnoise(1,1)*GaussianStandardDeviation+GaussianMean).^2;

        % Set random phase
        if strcmp(obj.RandomStream,'Global stream')
            wgnoise = rand(1,obj.pInputDataType);
        else
            wgnoise = rand(obj.pRNGStream,1,obj.pInputDataType);
        end
        obj.pRandomPhase = wgnoise(1,1)*2*pi;

        if obj.ChannelFiltering
            reset(obj.cChannelFilter);
        end

        % Setup large scale fading effect for the simulation
        if ~strcmp(obj.LargeScaleFadingEffect,'None')
            switch obj.LargeScaleFadingEffect
                case 'Shadowing'
                    obj.pLargeScaleLosses = 1/sqrt(10.^(0.1.*(obj.pShadowFading)));
                case 'Pathloss'
                    obj.pLargeScaleLosses = 1/sqrt(10.^(0.1.*(obj.pPathloss)));
                otherwise
                    obj.pLargeScaleLosses = 1/sqrt(10.^(0.1.*(obj.pPathloss+obj.pShadowFading)));
           end
        end

        % Initialization
        obj.pOffset = 0;
        obj.pLastTwoRows = coder.nullcopy(complex(zeros(2,obj.pNumPaths*obj.pNumLinks,obj.pInputDataType)));
        obj.pRunningTimeInstant = cast(0,obj.pInputDataType);
        obj.pFadingOffset = cast(0,obj.pInputDataType);
        obj.pOversampledFadingTime = zeros(1,1,obj.pInputDataType);
        obj.pOversampledFadingMatrix = complex(zeros(1,1,obj.pInputDataType));
        obj.pFadingTime = zeros(1,1,obj.pInputDataType);

        if obj.pIsStaticChannel
            % Generate a fading sample for each link
            staticChannelPathGains = generateNoiseSamples(obj,1);

            % Add antenna correlation and scale fading sample by the power in each multipath. 
            % Rician phasor is 1 as (exp(1i.2.pi.obj.pDoppler.cos(pi/4).*obj.pFadingTime)=1, when obj.pFadingTime=0 as is in this case.
            ricianPhasor = 1;
            staticChannelPathGains = scalePathGain(obj,staticChannelPathGains,ricianPhasor);

            % Include fluorescent light effects in models D and E
            if obj.pInFluorescentEffect
                % Estimate Fluorescent light effects at time zero
                staticChannelPathGains = fluorescentEffects(obj,staticChannelPathGains,0);
            end

            % Large-scale fading
            if ~strcmp(obj.LargeScaleFadingEffect,'None')
                staticChannelPathGains = staticChannelPathGains.*obj.pLargeScaleLosses;
            end

            % Set static channel tap gains
            obj.pStaticChannelPathGains = staticChannelPathGains.';
        end
    end

    function varargout = stepImpl(obj,input)

        if obj.ChannelFiltering
            Ns = size(input,1);
        else
            Ns = obj.NumSamples;
        end

        nTx = obj.pNt;
        nRx = obj.pNr;
        numPaths = obj.pNumPaths;

        % Output empty signals and path gains for an empty input
        if Ns == 0
            varargout{1} = zeros(Ns,nRx,obj.pInputDataType);
            if obj.PathGainsOutputPort
                varargout{2} = NaN(Ns,numPaths,nTx,nRx);
            end
            return;
        end

        if ~obj.pIsStaticChannel % Non-Static channel
            % Number of samples in time
            chSampleTime = 1/obj.pFc;
            inpSampleTime = 1/obj.SampleRate;
            Nt = Ns*inpSampleTime;

            runningTime = obj.pRunningTimeInstant:inpSampleTime:(Ns-1)*inpSampleTime+obj.pRunningTimeInstant;

            if runningTime(1)==0
                numChSamples = double(ceil(Nt/chSampleTime)+1); % For codegen
                pathGains = generateFadingSamples(obj,runningTime,numChSamples);
                obj.pOffset = 1;
            else
                if runningTime(end) < obj.pOversampledFadingTime(end)
                    % No additional channel samples are required to process the input samples
                    pathGains = (interp1(obj.pOversampledFadingTime.',obj.pOversampledFadingMatrix.',runningTime.','linear'));
                else
                    numInterpolatedSamples = size(runningTime,2);
                    % Use the remaining samples before generating more
                    previousIdx = find(runningTime<obj.pFadingTime(end));

                    % Generate output samples before generating new channel samples
                    H1 = (interp1(obj.pOversampledFadingTime.',obj.pOversampledFadingMatrix.',runningTime(previousIdx).','linear'));

                    % Additional samples needed to process the input
                    newInterpolatedSamples = numInterpolatedSamples-size(previousIdx,2);

                    % Time required to process the remaining interpolated samples
                    timeInterpolatedSamples = newInterpolatedSamples*inpSampleTime;

                    % Number of channel samples required to process this input
                    numChannelSamples = ceil(timeInterpolatedSamples/chSampleTime)+1;

                    % The isempty check is to avoid the special case when number of
                    % interpolated channel samples are exact match to the length of
                    % samples between two channel samples
                    runningTimeInstant = runningTime(1,size(runningTime,2)+isempty(previousIdx)-newInterpolatedSamples)+inpSampleTime*(1-isempty(previousIdx));

                    runningTime = runningTimeInstant:inpSampleTime:(newInterpolatedSamples-1)*inpSampleTime+runningTimeInstant;

                    H2 = generateFadingSamples(obj,runningTime,numChannelSamples);
                    pathGains = [H1;H2];
                end
            end

            % Update states
            obj.pFadingOffset = obj.pFadingTime(size(obj.pFadingTime,2))+chSampleTime;
            obj.pRunningTimeInstant = runningTime(1,size(runningTime,2))+inpSampleTime;
            % Reshape pathGains for channel filtering
            h = reshape(pathGains,Ns,nRx,nTx,numPaths);
        else % Static channel
            % Use previously saved path gains for static channels
            pathGains = obj.pStaticChannelPathGains;
            % Reshape pathGains for channel filtering, there is no changes in pathGains over time
            h = reshape(pathGains,1,nRx,nTx,numPaths); % For codegen
        end

        if obj.ChannelFiltering
            varargout{1} = obj.cChannelFilter(input,h);

            if obj.PathGainsOutputPort
                if obj.pIsStaticChannel
                    p = repmat(h,Ns,1);
                else
                    p = h;
                end
                varargout{2} = permute(p,[1,4,3,2]);
            end
        else
            if obj.pIsStaticChannel
                p = repmat(h,Ns,1);
            else
                p = h;
            end
            varargout{1} = permute(p,[1,4,3,2]);
        end
    end

    function flag = isInactivePropertyImpl(obj,prop)
        fd = fadingDisabled(obj);
        if any(strcmpi(prop,{'FluorescentEffect','PowerLineFrequency'}))
            flag = ~any(strcmpi(obj.DelayProfile,{'Model-D','Model-E'}));
        elseif strcmpi(prop,'Seed')
            flag = strcmp(obj.RandomStream,'Global stream') || fd;
        elseif strcmpi(prop,'PathGainsOutputPort')
            flag = obj.ChannelFiltering==false;
        elseif any(strcmpi(prop,{'NumSamples','OutputDataType'}))
            flag = obj.ChannelFiltering==true;
        elseif any(strcmpi(prop,{'TransmitReceiveDistance','RandomStream','NormalizePathGains'}))
            flag = fd;
        else
            flag = false;
        end
    end

    function releaseImpl(obj)
        release(obj.cChannelFilter);
    end

    function s = saveObjectImpl(obj)
        s = saveObjectImpl@matlab.System(obj);
        if isLocked(obj)
            s.pNt = obj.pNt;
            s.pNr = obj.pNr;
            s.pNumPaths = obj.pNumPaths;
            s.pPathPower = obj.pPathPower;
            s.pPathPowerdBs = obj.pPathPowerdBs;
            s.pNumLinks = obj.pNumLinks;
            s.pLegacyState = obj.pLegacyState;
            s.pRunningTime = obj.pRunningTime;
            s.pOffset = obj.pOffset;
            s.pFc = obj.pFc;
            s.pRandomPhase = obj.pRandomPhase;
            s.pRicianLOS = obj.pRicianLOS;
            s.pRicianNLOS = obj.pRicianNLOS;
            s.pPathPower = obj.pPathPower;
            s.pAntennaCorrelation23b = obj.pAntennaCorrelation23b;
            s.pPathloss = obj.pPathloss;
            s.pDoppler = obj.pDoppler;
            s.pShadowFading = obj.pShadowFading;
            s.pFilterState = obj.pFilterState;
            s.pLastTwoRows = obj.pLastTwoRows;
            s.pRunningTime = obj.pRunningTime;
            s.pRandomPhase = obj.pRandomPhase;
            s.pRandomInterfererToCarrierRatio = obj.pRandomInterfererToCarrierRatio;
            s.pLargeScaleLosses = obj.pLargeScaleLosses;
            s.pPowerLineFrequency = obj.pPowerLineFrequency;
            s.pNumeratorB = obj.pNumeratorB;
            s.pDenominatorB = obj.pDenominatorB;
            s.pNumeratorS = obj.pNumeratorS;
            s.pDenominatorS = obj.pDenominatorS;
            s.pLegacyGenerator = obj.pLegacyGenerator;
            s.pRunningTimeInstant = obj.pRunningTimeInstant;
            s.pOversampledFadingTime = obj.pOversampledFadingTime;
            s.pOversampledFadingMatrix = obj.pOversampledFadingMatrix;
            s.pFadingTime = obj.pFadingTime;
            s.pFadingOffset = obj.pFadingOffset;
            s.pPathDelays = obj.pPathDelays;
            s.pDefaultShadowFading = obj.pDefaultShadowFading;
            s.pInFluorescentEffect = obj.pInFluorescentEffect;
            s.pStream = obj.pStream;
            s.pRNGStream = obj.pRNGStream;
            s.pIsStaticChannel = obj.pIsStaticChannel;
            s.pStaticChannelPathGains = obj.pStaticChannelPathGains;
            s.cChannelFilter = matlab.System.saveObject(obj.cChannelFilter);
            s.pInputDataType = obj.pInputDataType;
        end
    end

    function loadObjectImpl(obj,s,wasLocked)
        if wasLocked
            obj.pNt = s.pNt;
            obj.pNr = s.pNr;
            obj.pNumPaths = s.pNumPaths;
            obj.pPathPower = s.pPathPower;
            obj.pPathPowerdBs = s.pPathPowerdBs;
            obj.pNumLinks = s.pNumLinks;
            obj.pLegacyState = s.pLegacyState;
            obj.pRunningTime = s.pRunningTime;
            obj.pOffset = s.pOffset;
            obj.pFc = s.pFc;
            obj.pRandomPhase = s.pRandomPhase;
            obj.pRicianLOS = s.pRicianLOS;
            obj.pRicianNLOS = s.pRicianNLOS;
            obj.pPathPower = s.pPathPower;
            obj.pDoppler = s.pDoppler;
            obj.pPathloss = s.pPathloss;
            obj.pShadowFading = s.pShadowFading;
            obj.pFilterState = s.pFilterState;
            obj.pRunningTime = s.pRunningTime;
            obj.pRandomPhase = obj.pRandomPhase;
            obj.pRandomInterfererToCarrierRatio = s.pRandomInterfererToCarrierRatio;
            obj.pLargeScaleLosses = s.pLargeScaleLosses;
            obj.pPowerLineFrequency = s.pPowerLineFrequency;
            obj.pNumeratorB = s.pNumeratorB;
            obj.pDenominatorB = s.pDenominatorB;
            obj.pNumeratorS = s.pNumeratorS;
            obj.pDenominatorS = s.pDenominatorS;
            obj.pLegacyGenerator = s.pLegacyGenerator;
            obj.pRunningTimeInstant = s.pRunningTimeInstant;
            obj.pOversampledFadingTime = s.pOversampledFadingTime;
            obj.pOversampledFadingMatrix = s.pOversampledFadingMatrix;
            obj.pFadingTime = s.pFadingTime;
            obj.pFadingOffset = s.pFadingOffset;
            obj.pPathDelays = s.pPathDelays;
            obj.pDefaultShadowFading = s.pDefaultShadowFading;
            obj.pInFluorescentEffect = s.pInFluorescentEffect;
            obj.pStream = s.pStream;

            % New property in R2017b
            if isfield(s,'pStream') && ~isempty(s.pStream) && ~s.pLegacyGenerator
                % Mapping for pre R2017b users
                obj.pRNGStream = RandStream('mt19937ar');
                obj.pRNGStream.State = s.pStream.State;
            elseif isfield(s,'pRNGStream') && ~isempty(s.pRNGStream)
                obj.pRNGStream = RandStream('mt19937ar','Seed',obj.Seed);
                obj.pRNGStream.State = s.pRNGStream.State;
            end

            % New property in R2018a
            if isfield(s,'pIsStaticChannel')
                obj.pIsStaticChannel = s.pIsStaticChannel;
                obj.pStaticChannelPathGains = s.pStaticChannelPathGains;
            end

            % Instantiate a channel filter object if saved prior to 20b
            if ~isfield(s,'cChannelFilter') || ...
               (isfield(s.cChannelFilter, 'ClassNameForLoadTimeEval') && ...
                 strcmp(s.cChannelFilter.ClassNameForLoadTimeEval, ...
                'comm.internal.channel.ChannelFilter'))
                    obj.cChannelFilter = comm.ChannelFilter( ...
                        'SampleRate', s.SampleRate, ...
                        'PathDelays', double(s.pPathDelays), ...
                        'NormalizeChannelOutputs', s.NormalizeChannelOutputs);
                    obj.cChannelFilter.setUsePublicGainDim(false);
            else                
                obj.cChannelFilter = matlab.System.loadObject(s.cChannelFilter);         
            end

            % New property in R2020a
            if isfield(s,'pInputDataType')
                obj.pInputDataType = s.pInputDataType;
            end

            % New properties in R2023b pAntennaCorrelation23b and
            % pLastTwoRows, replace pAntennaCorrelation and pLastTwoColumn
            if isfield(s,'pAntennaCorrelation23b')
                obj.pAntennaCorrelation23b = s.pAntennaCorrelation23b;
                obj.pLastTwoRows = s.pLastTwoRows;
            else
                % Convert pAntennaCorrelation to pAntennaCorrelation23b.
                % Extract NumLinks-by-NumLinks blocks from the diagonal.
                obj.pAntennaCorrelation23b = coder.nullcopy(complex(zeros(obj.pNumLinks,obj.pNumLinks,obj.pNumPaths,obj.pInputDataType)));
                for i = 1:obj.pNumPaths
                    idx = (i-1)*obj.pNumLinks+(1:obj.pNumLinks);
                    obj.pAntennaCorrelation23b(:,:,i) = s.pAntennaCorrelation(idx,idx);
                end
                obj.pLastTwoRows = s.pLastTwoColumn.';
            end
        end
        loadObjectImpl@matlab.System(obj,s);
    end

    function flag = isInputSizeMutableImpl(~,~)
        flag = true;
    end

    function flag = isInputComplexityMutableImpl(~,~)
        flag = true;
    end

    function s = infoImpl(obj)
        % info Returns characteristic information about the channel
        %    S = info(OBJ) returns a structure containing characteristic
        %    information, S, about the fading channel. A description of the
        %    fields and their values are as follows:
        %
        %    ChannelFilterDelay        - Channel filter delay (samples)
        %    ChannelFilterCoefficients - Coefficient matrix used to convert
        %                                path gains to channel filter tap gains
        %                                for each sample and each pair of
        %                                transmit and receive antennas.
        %    PathDelays                - Multipath delay of the discrete paths 
        %                                (seconds).
        %    AveragePathGains          - Average gains of the paths (dB).
        %    Pathloss                  - Path loss (dB).

        if ~coder.target('MATLAB') || ~isLocked(obj)
            getInfoParameters(obj);
        end

        chFilterInfo = info(obj.cChannelFilter);

        s.ChannelFilterDelay = chFilterInfo.ChannelFilterDelay;
        s.ChannelFilterCoefficients = chFilterInfo.ChannelFilterCoefficients;
        s.PathDelays = double(obj.pPathDelays);
        s.AveragePathGains = obj.pPathPowerdBs;
        s.Pathloss = 0;

        if strcmp(obj.LargeScaleFadingEffect,'Pathloss') || strcmp(obj.LargeScaleFadingEffect,'Pathloss and shadowing')
            s.Pathloss = obj.pPathloss;
        end
    end
end

methods(Access = private)   
    function y = initializeRice(cfg,txLOSRadians,rxLOSRadians)
        nTx = cfg.NumTransmitAntennas;
        txSpacingNormalized = cfg.TransmitAntennaSpacing;
        nRx = cfg.NumReceiveAntennas;
        rxSpacingNormalized = cfg.ReceiveAntennaSpacing;

        stepTx = exp(1i*2*pi*txSpacingNormalized*sin(txLOSRadians));
        vectorTx = stepTx.^(0:nTx-1);
        stepRx = exp(1i*2*pi*rxSpacingNormalized*sin(rxLOSRadians));
        vectorRx = stepRx.^((0:nRx-1).');
        y = vectorRx*vectorTx;
    end

    function ricianComponents(obj,pathPowerIn,txLOSRadians,rxLOSRadians)
        if fadingDisabled(obj)
            pt = cast(1i,obj.pInputDataType);
            obj.pRicianLOS = zeros(obj.pNumLinks,1,'like',pt);
            obj.pRicianNLOS = ones(obj.pNumLinks,1,'like',pt);
            obj.pPathPower = pathPowerIn;
            return
        end

        % Computation of Rician steering matrix
        ricianMatrix = initializeRice(obj,txLOSRadians,rxLOSRadians);

        % Initialization of the LOS component
        riceFactor = 10.^(.1.*obj.pKfactor);
        ricianLOS = coder.nullcopy(complex(zeros(obj.pNumPaths*obj.pNumLinks,1,obj.pInputDataType)));
        ricianNLOS = coder.nullcopy(complex(zeros(obj.pNumPaths*obj.pNumLinks,1,obj.pInputDataType)));

        % Computation of the power delay profile of the (LOS+NLOS) power
        % The PDP is defined as the time dispersion of the NLOS power. The
        % addition of the LOS component modifies the time dispersion of the
        % total power.

        pathPowerOut = pathPowerIn.*(1+riceFactor);

        % Normalization of the power delay profile of the (LOS+NLOS) power
        if obj.NormalizePathGains
            pathPowerOut = pathPowerOut./sum(pathPowerOut);
        end

        out = reshape(ricianMatrix,obj.pNumLinks,1);

        for i = 1:obj.pNumPaths
            ricianLOS(1+(i-1)*obj.pNumLinks:i*obj.pNumLinks,1) = sqrt(complex(pathPowerOut(1,i))).*sqrt(riceFactor(i)/(riceFactor(i)+1)).*out;
            ricianNLOS(1+(i-1)*obj.pNumLinks:i*obj.pNumLinks,1)= sqrt(1/(riceFactor(i)+1)).*ones(obj.pNumLinks,1,obj.pInputDataType);
        end

        obj.pRicianLOS = ricianLOS;
        obj.pRicianNLOS = ricianNLOS;
        obj.pPathPower = pathPowerOut;
    end

    function fadingSamples = generateNoiseSamples(obj,N)

        if fadingDisabled(obj)
            d = dftmtx(max(obj.pNt,obj.pNr));
            df = reshape(d(1:obj.pNr,1:obj.pNt),[],1).';
            fadingSamples = repmat(complex(cast(df,obj.pInputDataType)),N,1);
            return
        end

        NP = obj.pNumPaths;
        NL = obj.pNt*obj.pNr;
        M  = NP*NL;
        const = sqrt(.5);

        if strcmp(obj.RandomStream,'Global stream')
            if obj.pLegacyGenerator && coder.target('MATLAB')
                % Legacy branch only used for testing
                stream = RandStream.getGlobalStream;
                stream.State = obj.pLegacyState;
                wgnoise = const*complex(randn(M,N),randn(M,N));
                obj.pLegacyState = stream.State;
             else
                w = (randn(2*M,N)).';
                wgnoise = const*(w(:,1:M)+1i*w(:,M+1:end));
             end
        else % 'mt19937ar with seed' branch
            w = (randn(obj.pRNGStream,2*M,N)).';
            wgnoise = const*(w(:,1:M)+1i*w(:,M+1:end));
        end

        switch obj.DelayProfile
            case 'Model-F'
                % Indoor, bell shape Doppler spectrum with spike
                filterStateIn = obj.pFilterState;

                SpikePos = 3; % Tap with Bell+Spike shape
                % Index of Bell shaped fading coefficients
                BellTapsPositions = [1:(SpikePos-1)*NL ((SpikePos)*NL+1):M];
                % Index of Bell+Spike shaped fading coefficients
                SpikeTapsPositions = ((SpikePos-1)*NL+1):(SpikePos)*NL;

                % Pre-allocate out
                out = coder.nullcopy(complex(zeros(N,M)));

                if obj.pLegacyGenerator
                    % Bell shaped fading
                    [FadingMatrixTimeBellTap,obj.pFilterState(:,BellTapsPositions)] = filter(obj.pNumeratorB,obj.pDenominatorB,wgnoise(BellTapsPositions,:),filterStateIn(:,BellTapsPositions),2);

                    % Bell+Spike shaped fading
                    [FadingMatrixTimeSpikeTap,obj.pFilterState(:,SpikeTapsPositions)] = filter(obj.pNumeratorS,obj.pDenominatorS,wgnoise(SpikeTapsPositions,:),filterStateIn(:,SpikeTapsPositions),2);

                    % Fading Matrix Time with bell+spike on the 3-rd tap
                    out(:,BellTapsPositions) = FadingMatrixTimeBellTap.';
                    out(:,SpikeTapsPositions) = FadingMatrixTimeSpikeTap.';
                else
                    % Bell shaped fading
                    [FadingMatrixTimeBellTap,obj.pFilterState(:,BellTapsPositions)] = filter(obj.pNumeratorB,obj.pDenominatorB,wgnoise(:,BellTapsPositions),filterStateIn(:,BellTapsPositions),1);

                    % Bell+Spike shaped fading
                    [FadingMatrixTimeSpikeTap,obj.pFilterState(:,SpikeTapsPositions)] = filter(obj.pNumeratorS,obj.pDenominatorS,wgnoise(:,SpikeTapsPositions),filterStateIn(:,SpikeTapsPositions),1);

                    % Fading Matrix Time with bell+spike on the 3-rd tap
                    out(:,BellTapsPositions) = FadingMatrixTimeBellTap;
                    out(:,SpikeTapsPositions) = FadingMatrixTimeSpikeTap;
                end
            otherwise
                % Indoor, bell shape Doppler spectrum
                if obj.pLegacyGenerator
                    [filterOut,obj.pFilterState] = filter(obj.pNumeratorB,obj.pDenominatorB,wgnoise,obj.pFilterState,2);
                    out = filterOut.';
                else
                    [out,obj.pFilterState] = filter(obj.pNumeratorB,obj.pDenominatorB,wgnoise,obj.pFilterState,1);
                end
        end
        fadingSamples = cast(out,obj.pInputDataType);
    end

    function out = fluorescentEffects(obj,FadingMatrix,fadingSamplingTime)
        % Add fluorescent effects

        amplitudes = [0 -15 -20]; % Amplitudes of the modulating signal
        tapsModelD = [12 14 16]; % Taps to be used in model D
        tapsModelE = [3 5 7]; % Taps to be used in model E

        % Initialization of the modulation matrix
        ModulationMatrix = complex(zeros(size(FadingMatrix)));

        % Computation of the modulation function g(t)
        g = coder.nullcopy(complex(zeros(3,size(fadingSamplingTime,2))));

        for k = coder.unroll(1:3)
            g(k,:) = (10^(amplitudes(k)/20)).*exp(1i.*(4.*pi.*(2*(k-1)+1).*obj.pPowerLineFrequency.*fadingSamplingTime+obj.pRandomPhase));
        end

        modulationFunction = sum(g);

        % Modulation matrix
        if strcmpi(obj.DelayProfile,'Model-D')
            for i = coder.unroll(1:obj.pNt)
                for j = coder.unroll(1:obj.pNr)
                    for k = coder.unroll(1:3)
                        ModulationMatrix((((tapsModelD(k)-1)*obj.pNt*obj.pNr)+((i-1)*obj.pNr)+j),:) = modulationFunction;
                    end
                end
            end
        else
            for i = coder.unroll(1:obj.pNt)
                for j = coder.unroll(1:obj.pNr)
                    for k = coder.unroll(1:3)
                        ModulationMatrix((((tapsModelE(k)-1)*obj.pNt*obj.pNr)+((i-1)*obj.pNr)+j),:) = modulationFunction;
                    end
                end
            end
        end

        % Multiplication of the modulation matrix and the fading matrix
        ModulationMatrix = ModulationMatrix.*FadingMatrix;

        if obj.pLegacyGenerator
            % Calculation of the energy of both matrices
            ModulationMatrixEnergy = sum(sum(abs(ModulationMatrix).^2));
            FadingMatrixEnergy = sum(sum(abs(FadingMatrix).^2));

            % Comparison and calculation of the normalization constant alpha
            RealInterfererToCarrierRatio = ModulationMatrixEnergy/FadingMatrixEnergy;
            NormalizationConstant = sqrt(double(obj.pRandomInterfererToCarrierRatio/RealInterfererToCarrierRatio));

            out = FadingMatrix + NormalizationConstant(1,1) .* ModulationMatrix;
        else
            % Calculation of the energy of both matrices
            ModulationMatrixEnergy = (sum(abs(ModulationMatrix).^2));
            FadingMatrixEnergy = (sum(abs(FadingMatrix).^2));

            % Comparison and calculation of the normalization constant alpha
            RealInterfererToCarrierRatio = ModulationMatrixEnergy./FadingMatrixEnergy;
            NormalizationConstant = sqrt(double(obj.pRandomInterfererToCarrierRatio./RealInterfererToCarrierRatio));

            NC = repmat(NormalizationConstant,size(ModulationMatrix,1),1);
            out = FadingMatrix + NC .* ModulationMatrix;
        end
    end

    function out = generateWGNoise(obj)
        if strcmp(obj.RandomStream,'Global stream')
            out = randn(1,obj.pInputDataType);
        else
            out = randn(obj.pRNGStream,1,obj.pInputDataType);
        end
    end

    function H = generateFadingSamples(obj,runningTime,numChSamples)
        fadingSamplingTime = cast(1/obj.pFc,obj.pInputDataType);

        % Time references
        obj.pFadingTime = obj.pFadingOffset-(obj.pFadingOffset~= 0)*2*fadingSamplingTime:fadingSamplingTime:obj.pFadingOffset+((numChSamples-1)*fadingSamplingTime);
        obj.pOversampledFadingTime = obj.pFadingTime(1):obj.InterpolationFactor*fadingSamplingTime:obj.pFadingTime(size(obj.pFadingTime,2));

        % Computation of the matrix of fading coefficients
        newFadingMatrixTime = generateNoiseSamples(obj,numChSamples);

        % State retention
        if obj.pOffset==0
            fadingMatrixTime = newFadingMatrixTime;
        else
            fadingMatrixTime = [obj.pLastTwoRows; newFadingMatrixTime];
        end

        obj.pLastTwoRows = newFadingMatrixTime(numChSamples-1:numChSamples,:);

        % Calculation of the Rician phasor. The AoA/AoD are hard-coded to 45 degrees
        ricePhasor = exp(1i.*2.*pi.*obj.pDoppler.*cos(pi/4).*obj.pFadingTime);

        fadingMatrix = scalePathGain(obj,fadingMatrixTime,ricePhasor);

        % First (partial) interpolation, at 10*FadingSamplingFrequency_Hz
        % to avoid aliasing of the fluorescent effect
        obj.pOversampledFadingMatrix = (interp1(obj.pFadingTime.',fadingMatrix.',obj.pOversampledFadingTime.','linear')).';

        % Include fluorescent light effects in models D and E
        if obj.pInFluorescentEffect
            obj.pOversampledFadingMatrix = fluorescentEffects(obj,obj.pOversampledFadingMatrix,obj.pOversampledFadingTime);
        end

        % Large-scale fading
        if ~strcmp(obj.LargeScaleFadingEffect,'None')
            obj.pOversampledFadingMatrix = obj.pOversampledFadingMatrix.*obj.pLargeScaleLosses;
        end

        % Second interpolation, at SamplingRate_Hz
        H = interp1(obj.pOversampledFadingTime.',obj.pOversampledFadingMatrix.',runningTime.','linear');
    end

    function out = scalePathGain(obj,fadingMatrixTime,ricePhasor)
        [NL,~,NP] = size(obj.pAntennaCorrelation23b); % NL = NT*NR, NP - number of paths
        [N,M] = size(fadingMatrixTime); % N - number of samples, M = NP*NL

        % Add spatial correlation into the fading matrix
        tmp = permute(reshape(fadingMatrixTime,N,NL,NP),[2 1 3]);
        fadingMatrixTimeSpatialCorr = pagemtimes(obj.pAntennaCorrelation23b,tmp);

        % Normalization of the correlated fading processes
        tmp = permute(sqrt(obj.pPathPower),[1 3 2]).*fadingMatrixTimeSpatialCorr;
        fadingMatrixTimeNorm = reshape(permute(tmp,[1 3 2]),M,N);

        % Addition of the Rice component
        out = (obj.pRicianLOS*ricePhasor)+obj.pRicianNLOS.*fadingMatrixTimeNorm;
    end
 
    function setupChannelFilter(obj)
        obj.cChannelFilter = comm.ChannelFilter( ...
            'SampleRate', obj.SampleRate, ...
            'PathDelays', double(obj.pPathDelays), ...
            'NormalizeChannelOutputs', obj.NormalizeChannelOutputs);
        obj.cChannelFilter.setUsePublicGainDim(false);        
    end

    function out = getInfoParameters(obj)
        % Setup parameters
        obj.pNt = obj.NumTransmitAntennas;
        obj.pNr = obj.NumReceiveAntennas;
        obj.pNumLinks = obj.pNt*obj.pNr;

        % Set static channel flag
        obj.pIsStaticChannel = obj.EnvironmentalSpeed == 0 || fadingDisabled(obj);

        % Set power line frequency
        if strcmp(obj.PowerLineFrequency,'50Hz')
            obj.pPowerLineFrequency = 50;
        else
            obj.pPowerLineFrequency = 60;
        end

        % Include fluorescent light effects in models D and E
        obj.pInFluorescentEffect = obj.FluorescentEffect && (strcmpi(obj.DelayProfile,'Model-D') || strcmpi(obj.DelayProfile,'Model-E'));

        coder.extrinsic('wlan.internal.spatialCorrelation');
        modelConfig = struct( ...
                      'NumTransmitAntennas',obj.NumTransmitAntennas, ...
                      'NumReceiveAntennas',obj.NumReceiveAntennas, ...
                      'TransmitAntennaSpacing',obj.TransmitAntennaSpacing, ...
                      'ReceiveAntennaSpacing',obj.ReceiveAntennaSpacing, ...
                      'DelayProfile',obj.DelayProfile, ...
                      'UserIndex',obj.UserIndex, ...
                      'ChannelBandwidth',obj.ChannelBandwidth, ...
                      'TransmitReceiveDistance',obj.TransmitReceiveDistance, ...
                      'CarrierFrequency',obj.CarrierFrequency, ...
                      'TransmissionDirection',obj.TransmissionDirection, ...
                      'NumPenetratedFloors',obj.NumPenetratedFloors, ...
                      'NumPenetratedWalls',obj.NumPenetratedWalls, ...
                      'WallPenetrationLoss',obj.WallPenetrationLoss, ...
                      'FormatType',class(obj), ...
                      'InputDataType',obj.pInputDataType);

        if coder.target('MATLAB')
            out = wlan.internal.spatialCorrelation(modelConfig);                          
        else
            out = coder.const((wlan.internal.spatialCorrelation(modelConfig)));
        end

        obj.pAntennaCorrelation23b = coder.const(out.AntennaCorrelation);
        obj.pPathDelays = out.PathDelays;
        obj.pPathloss = out.Pathloss;
        obj.pDefaultShadowFading = coder.const(out.ShadowFading);
        obj.pKfactor = coder.const(out.Kfactor);
        obj.pNumPaths = size(out.PathPower,2);

        % This is to display the initial shadow fading value through an info function
        obj.pShadowFading = out.ShadowFading;

        % Path power in dBs returned by the info function
        obj.pPathPowerdBs = double(10*log10(out.PathPower));

        % Validate channel parameters
        validateChannelParameters(obj);

        % Setup channel filter
        setupChannelFilter(obj);
    end

    function validateChannelParameters(obj)
        coder.extrinsic('sprintf');
        if ~obj.pIsStaticChannel
            % Doppler components
            wavelength = 3e8/obj.CarrierFrequency;           

            % Cut-off frequency (Hz)
            obj.pDoppler = (obj.EnvironmentalSpeed*(5/18))/wavelength; % Change km/h to m/s

            % Normalization factor
            normalizationFactor = 1/300;

            % Channel sampling frequency
            obj.pFc = coder.const(obj.pDoppler/normalizationFactor);

            % Limitation between sample rate and cut-off frequency
            coder.internal.errorIf(any(obj.SampleRate < (1/obj.InterpolationFactor)*obj.pFc), ...
                 'wlan:wlanChannel:MaxDopplerAndInputSamplingRate',sprintf('%f',(1/obj.InterpolationFactor)*obj.pFc),sprintf('%f',obj.SampleRate));

            % Display the minimum carrier frequency value in the error message. The
            % Nyquist frequency of the first interpolation factor should be greater
            % than the highest harmonic due to the Fluorescent effect.
            coder.internal.errorIf(obj.pInFluorescentEffect && (10*obj.pPowerLineFrequency)>((0.5*1/obj.InterpolationFactor)*obj.pFc), ...
                'wlan:wlanChannel:AliasingfluorescentFrequency', sprintf('%f',(0.5*1/obj.InterpolationFactor)*obj.pFc), sprintf('%f',10*obj.pPowerLineFrequency));
        end
        % Large-scale fading only applicable when fading enabled
        coder.internal.errorIf(fadingDisabled(obj) && ~strcmp(obj.LargeScaleFadingEffect,'None'), 'wlan:wlanChannel:FadingDisabledLargeScaleFadingEnabled');
    end


end

methods (Access=protected)
    function f = fadingDisabled(obj)
        f = strcmpi(obj.DelayProfile,'none');
    end
end
end

function numPaths = getNumMultipaths(obj)
% Calculate the number of multipaths for all delay profiles. Only required
% for Simulink.
    modelType = obj.DelayProfile;
    cbw = obj.ChannelBandwidth;
    switch modelType
        case {'Model-A','None'}
            numPaths = 1; % For CBW1, CBW2, CBW4, CBW8, CBW16, CBW20, CBW40, CBW80 and CBW160
        case 'Model-B'
            switch cbw
                case {'CBW80','CBW8'}
                    numPaths = 17;
                case {'CBW160','CBW16'}
                    numPaths = 33;
                case 'CBW320'
                    numPaths = 65;
                otherwise % For CBW1, CBW2, CBW4, CBW20 and CBW40
                    numPaths = 9;
            end
        case 'Model-C'
            switch cbw
                case {'CBW80','CBW8'}
                    numPaths = 27;
                case {'CBW160','CBW16'}
                    numPaths = 53;
                case 'CBW320'
                    numPaths = 105;
                otherwise % For CBW1, CBW2, CBW4, CBW20 and CBW40
                    numPaths = 14;
            end
        case 'Model-F'
            switch cbw
                case {'CBW80','CBW8'}
                    numPaths = 34;
                case {'CBW160','CBW16'}
                    numPaths = 66;
                case 'CBW320'
                    numPaths = 130;
                otherwise % For CBW1, CBW2, CBW4, CBW20 and CBW40
                    numPaths = 18;
            end
        otherwise % Model D and Model E
            switch cbw
                case {'CBW80','CBW8'}
                    numPaths = 35;
                case {'CBW160','CBW16'}
                    numPaths = 69;
                case 'CBW320'
                    numPaths = 137;
                otherwise % For CBW1, CBW2, CBW4, CBW20 and CBW40
                    numPaths = 18;
            end
    end
end