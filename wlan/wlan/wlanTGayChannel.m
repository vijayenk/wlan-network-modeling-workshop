classdef (StrictDefaults) wlanTGayChannel < matlab.System
%wlanTGayChannel Filter input signal through an IEEE 802.11ay channel
%   CHAN = wlanTGayChannel creates a System object, CHAN, for the IEEE
%   802.11ay millimeter-wave channel model as specified in [1], which
%   follows the quasi-deterministic (Q-D) modeling approach. This object
%   filters an input signal through the channel to obtain the impaired
%   complex signal.
%
%   CHAN = wlanTGayChannel(Name,Value) creates an 802.11ay channel object,
%   CHAN, with the specified property Name set to the specified Value.
%   You can specify additional name-value pair arguments in any order as
%   (Name1,Value1,...,NameN,ValueN).
%
%   Step method syntax:
%
%   Y = step(CHAN,X) filters input signal X through an IEEE 802.11ay
%   millimeter-wave fading channel and returns the result in Y. The input X
%   must be a double or single precision, Ns-by-NTS matrix, where Ns is the
%   number of samples and NTS is the number of input streams to the
%   channel. The output Y is a Ns-by-NRS channel impaired signal with the
%   same data type as X, where NRS is the number of output streams from the
%   channel. NTS and NRS are derived from the channel object's
%   configuration and available in the object's info method return.
%   
%   For SU-MIMO with one transmit and receive array, when NTS = 1, X is the
%   vertically polarized stream to the array. When NTS/NRS = 2, the first
%   and second columns in X/Y are the vertically and horizontally polarized
%   streams to/from the array, respectively.
%
%   For SU-MIMO with two transmit and receive arrays, when NTS = NRS = 2,
%   the first and second columns in X/Y are the vertically polarized stream
%   to/from the first array and horizontally polarized stream to/from the
%   second array, respectively. When NTS = NRS = 4, the first two columns
%   in X/Y are the vertically and horizontally polarized streams to/from
%   the first array, respectively, and the last two columns in X/Y are the
%   vertically and horizontally polarized streams to/from the second array,
%   respectively.
%   
%   [Y,CIR] = step(CHAN,X) returns the channel impulse response (CIR) for
%   all the simulated rays. CIR is a complex-valued,
%   Ns-by-Nray-by-NTS-by-NRS array, where Nray is the number of rays.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
% 
%   wlanTGayChannel methods:
%
%   step            - Filter input signal through an 802.11ay channel (see above)
%   release         - Allow property value and input characteristics changes
%   clone           - Create 802.11ay channel object with same property values
%   isLocked        - Locked status (logical)
%   reset           - Regenerate R-Rays and intra-cluster rays when the 
%                     RandomStream property is set to 'Global stream'.
%                     Reset channel filter.
%   info            - Return characteristic information about the channel 
%   showEnvironment - Display a 3D map for the specified environment and 
%                     D-Rays from ray-tracing.
%
%   wlanTGayChannel properties:
%
%   SampleRate                 - Sample rate (Hz)
%   CarrierFrequency           - Carrier frequency (Hz)
%   Environment                - Channel model environment
%   RoadWidth                  - Street canyon road width (m)
%   SidewalkWidth              - Street canyon sidewalk width (m)
%   RoomDimensions             - Hotel lobby length, width and height (m)
%   UserConfiguration          - User configuration
%   ArraySeparation            - Array separation (m)
%   ArrayPolarization          - Array polarization type
%   TransmitArray              - Transmit antenna array
%   TransmitArrayPosition      - Transmit antenna array position (m)
%   TransmitArrayOrientation   - Transmit antenna array orientation
%   TransmitArrayPolarization  - Transmit antenna array polarization type
%   ReceiveArray               - Receive antenna array
%   ReceiveArrayPosition       - Receive antenna array position (m)
%   ReceiveArrayOrientation    - Receive antenna array orientation
%   ReceiveArrayPolarization   - Receive antenna array polarization type
%   ReceiveArrayVelocitySource - Receive antenna array velocity source
%   ReceiveArrayVelocity       - Receive antenna array velocity (m/s)
%   RandomRays                 - Model random rays (R-Rays) (logical)
%   IntraClusterRays           - Model intra-cluster rays (logical)
%   OxygenAbsorption           - Oxygen absorption (dB/m)
%   BeamformingMethod          - Beamforming method
%   TransmitBeamformingVectors - Transmit beamforming vectors
%   ReceiveBeamformingVectors  - Receive beamforming vectors
%   NormalizeImpulseResponses  - Normalize channel impulse responses (logical)
%   NormalizeChannelOutputs    - Normalize output by number of output streams (logical)
%   RandomStream               - Source of random number stream
%   Seed                       - Initial seed
%
%   % References:
%   % [1] A. Maltsev and et. al, Channel Models for IEEE 802.11ay, 
%   % IEEE 802.11-15/1150r9, Mar. 2017.
%   % [2] A. Maltsev and et. al, Channel Models for 60GHz WLAN Systems, 
%   % IEEE 802.11-09/0334r8, May 2010.
%   % [3] WiMEBA, WP5: Propagation, Antennas and Multi-Antenna Techniques, 
%   % D5.1: Channel Modeling and Characterization, Jun. 2014. 

% Copyright 2018-2024 The MathWorks, Inc.
%#codegen

properties (Nontunable)
    %SampleRate Sample rate (Hz)
    %   Specify the sample rate of the input signal in Hz as a double
    %   precision, real, positive scalar. The default value of this
    %   property is 2.64e9 Hz.
    SampleRate = 2.64e9;
    %CarrierFrequency Carrier frequency (Hz)
    %   Specify the center frequency of the input signal in Hz as a double
    %   precision, real, positive scalar. The default value of this
    %   property is 60e9 Hz.
    CarrierFrequency = 60e9;
    %Environment Channel model environment
    %   Specify the channel model environment, defined in [1] as one of
    %   'Open area hotspot' | 'Street canyon hotspot' | 'Large hotel
    %   lobby'. The default value of this property is 'Open area hotspot'.
    Environment = 'Open area hotspot'
    %RoadWidth Street canyon road width (m)
    %   Specify the road width in meters as a double precision, real,
    %   positive scalar. The road is parallel to and has its center on the
    %   y-axis. This property applies when you set the Environment property
    %   to 'Street canyon hotspot'. The default value of this property is
    %   16m.
    RoadWidth = 16; 
    %SidewalkWidth Street canyon sidewalk width (m)
    %   Specify the sidewalk width in meters as a double precision, real,
    %   positive scalar. The road is parallel to and has its center on the
    %   y-axis. This property applies when you set the Environment property
    %   to 'Street canyon hotspot'. The default value of this property is
    %   6m.
    SidewalkWidth = 6;
    %RoomDimensions Hotel lobby length, width and height (m)
    %   Specify the length, width and height of the hotel lobby in meters
    %   as a double precision, real, positive, 1-by-3 vector. The lobby has
    %   its ground center at the coordinate origin and its length, width
    %   and height are along the x-axis, y-axis and z-axis respectively.
    %   This property applies when you set the Environment property to
    %   'Large hotel lobby'. The default value of this property is [20, 15,
    %   6].
    RoomDimensions = [20 15 6]
    %UserConfiguration User configuration
    %   Specify the user configuration as one of 'SU-SISO' | 'SU-MIMO 1x1'
    %   | 'SU-MIMO 2x2', where 1x1 means one transmit and receive array and
    %   2x2 means two transmit and receive arrays. There is one stream at
    %   transmitter and receiver for 'SU-SISO'. There are two streams at
    %   transmitter and/or receiver for 'SU-MIMO 1x1'. There are two or
    %   four streams at transmitter and receiver for 'SU-MIMO 2x2'. Refer
    %   to Table 3-2 in [1]. The default value of this property is
    %   'SU-SISO'.
    UserConfiguration = 'SU-SISO'
    %ArraySeparation Array separation (m)
    %   Specify the transmit and receive array separation in meters as a
    %   double precision, real, positive, 1-by-2 vector. This property
    %   applies when you set the UserConfiguration property to 'SU-MIMO
    %   2x2'. The default value of this property is [0.5 0.5].
    ArraySeparation = [0.5 0.5];
    %ArrayPolarization Array polarization type
    %   Specify the transmit and receive antenna array polarization type
    %   for SU-MIMO as one of 'Single, Single' | 'Dual, Dual' | 'Single,
    %   Dual'. This property applies when you set the UserConfiguration
    %   property to 'SU-MIMO 1x1' or 'SU-MIMO 2x2'. Refer to Table 3-2 in
    %   [1]. The default value of this property is 'Single, Single'.
    ArrayPolarization = 'Single, Single'
    %TransmitArray Transmit antenna array
    %   Specify the transmit antenna array as a wlanURAConfig object.    
    %   You can set the object's Size property to have it represent a
    %   uniform rectangular array (URA), uniform linear array (ULA), or
    %   single element. The default value of this property is a 2x2 URA
    %   with element spacing of 0.2m.
    TransmitArray
    %TransmitArrayPosition Transmit antenna array position (m)
    %   Specify the position of the transmit antenna array's phase center
    %   in meters as a double precision, real, 3-by-1 vector in the form of
    %   [x; y; z]. The default value of this property is [0; 0; 5].
    TransmitArrayPosition = [0;0;5]
    %TransmitArrayOrientation Transmit antenna array orientation
    %   Specify the orientation of the transmit antenna array(s) in degrees
    %   as a double precision, real, 3-by-1 vector. The 3 entries in the
    %   vector specify 3 sequential rotations to transform the global
    %   coordinate system into the local coordinate system of the array.
    %   The first rotation is around the z-axis, determining the target
    %   azimuth angle; the second rotation is around the rotated x-axis,
    %   determining the target elevation angle; the third rotation is
    %   around the rotated z-axis, specified for non-symmetric azimuth
    %   distribution of the antenna gain. Refer to Section 6.3.3 in [2].
    %   The default value of this property is [0; 0; 0].
    TransmitArrayOrientation = zeros(3,1)
    %TransmitArrayPolarization Transmit antenna array polarization type
    %   Specify the transmit antenna array polarization type for SU-SISO as
    %   one of 'None' | 'Vertical' | 'Horizontal' | 'LHCP' | 'RHCP'. This
    %   property applies when you set the UserConfiguration property to
    %   'SU-SISO'. The default value of this property is 'None'.
    TransmitArrayPolarization = 'None'
    %ReceiveArray Receive antenna array
    %   Specify the receive antenna array as a wlanURAConfig object. 
    %   You can set the object's Size property to have it represent a
    %   uniform rectangular array (URA), uniform linear array (ULA), or
    %   single element. The default value of this property is a 2x2 URA
    %   with element spacing of 0.2m.
    ReceiveArray
    %ReceiveArrayPosition Receive antenna array position (m)
    %   Specify the position of the receive antenna array's phase center
    %   in meters as a double precision, real, 3-by-1 vector in the form of
    %   [x; y; z]. The default value of this property is [8; 0; 1.5].
    ReceiveArrayPosition = [8;0;1.5]
    %ReceiveArrayOrientation Receive antenna array orientation
    %   Specify the orientation of the receive antenna array(s) in degrees
    %   as a double precision, real, 3-by-1 vector. The 3 entries in the
    %   vector specify 3 sequential rotations to transform the global
    %   coordinate system into the local coordinate system of the array.
    %   The first rotation is around the z-axis, determining the target
    %   azimuth angle; the second rotation is around the rotated x-axis,
    %   determining the target elevation angle; the third rotation is
    %   around the rotated z-axis, specified for non-symmetric azimuth
    %   distribution of the antenna gain. Refer to Section 6.3.3 in [2].
    %   The default value of this property is [0; 0; 0].
    ReceiveArrayOrientation = zeros(3,1)
    %ReceiveArrayPolarization Receive antenna array polarization type
    %   Specify the receive antenna array polarization type for SU-SISO as
    %   one of 'None' | 'Vertical' | 'Horizontal' | 'LHCP' | 'RHCP'. This
    %   property applies when you set the UserConfiguration property to
    %   'SU-SISO'. The default value of this property is 'None'.
    ReceiveArrayPolarization = 'None'
    %ReceiveArrayVelocitySource Receive antenna array velocity source
    %   Specify the source of the receive antenna array velocity as one of
    %   'Auto' | 'Custom'. The default value of this property is 'Auto',
    %   for which the receive array velocity is randomly generated as
    %   specified in [1].
    ReceiveArrayVelocitySource = 'Auto'
    %ReceiveArrayVelocity Receive antenna array velocity (m/s)
    %   Specify the receive antenna array velocity in meters per second as
    %   a double precision, real, 3-by-1 vector in the form of [x; y; z].
    %   The default value of this property is [1; 1; 0].
    ReceiveArrayVelocity = [1; 1; 0]; 
    %OxygenAbsorption Oxygen absorption (dB/m)
    %   Specify the oxygen absorption in dB/m as a double-precision, real,
    %   non-negative scalar. The default value of this property is 0.015
    %   dB/m, which is typical for 60 GHz carrier frequency.
    OxygenAbsorption = 0.015
    %BeamformingMethod Beamforming method
    %   Specify the beamforming method as one of 'Maximum power ray' |
    %   'Custom'. Refer to Section 6.5 in [2] for the maximum power ray
    %   method. The default value of this property is 'Maximum power ray'.
    BeamformingMethod = 'Maximum power ray'
    %RandomStream Source of random number stream
    %   Specify the source of random number stream as one of 'Global
    %   stream' | 'mt19937ar with seed'. If RandomStream is set to 'Global
    %   stream', the current global random number stream is used for random
    %   number generation. In this case, the reset method regenerates
    %   random rays (R-Rays) when RandomRays is set to true, intra-cluster
    %   rays when IntraClusterRays is set to true, and the receive array
    %   velocity when ReceiveArrayVelocitySource is set to 'Auto'. If
    %   RandomStream is set to 'mt19937ar with seed', the mt19937ar
    %   algorithm is used for a self-contained random number generation.
    %   The default value of this property is 'Global stream'.
    RandomStream = 'Global stream';  
    %Seed Initial seed
    %   Specify the initial seed of a mt19937ar random number generator
    %   algorithm as a double precision, real, nonnegative integer scalar.
    %   This property applies when you set the RandomStream property to
    %   'mt19937ar with seed'. The default value of this property is 73.
    Seed = 73;
end

properties
    %TransmitBeamformingVectors Transmit beamforming vectors
    %   Specify the transmit beamforming vectors as a double precision,
    %   NTE-by-NTS matrix, where NTE is the number of elements in each
    %   transmit antenna array and NTS is the number of input streams to
    %   the channel. This property applies when you set the
    %   BeamformingMethod property to 'Custom'. The default value of this
    %   property is [0.5; 0.5; 0.5; 0.5].
    TransmitBeamformingVectors = .5*ones(4,1)
    %ReceiveBeamformingVectors Receive beamforming vectors
    %   Specify the receive beamforming vectors as a double precision,
    %   NRE-by-NRS matrix, where NRE is the number of elements in each
    %   receive antenna array and NRS is the number of output streams from
    %   the channel. This property applies when you set the
    %   BeamformingMethod property to 'Custom'. The default value of this
    %   property is [0.5; 0.5; 0.5; 0.5].
    ReceiveBeamformingVectors = .5*ones(4,1)
end

properties (Nontunable)    
    %NormalizeImpulseResponses Normalize channel impulse responses
    %   Set this property to true to normalize the channel impulse
    %   responses (CIR) to 0 dB per stream. The default value of this
    %   property is true.
    NormalizeImpulseResponses (1, 1) logical = true
    %NormalizeChannelOutputs Normalize output by number of output streams
    %   Set this property to true to normalize the channel output by the
    %   number of output streams. The default value of this property is
    %   true.
    NormalizeChannelOutputs (1, 1) logical = true
    %RandomRays Model random rays (R-Rays)
    %   Set this property to true to generate random rays (R-Rays) in the
    %   channel model. The default value of this property is true.
    RandomRays (1, 1) logical = true
    %IntraClusterRays Model intra-cluster rays
    %   Set this property to true to generate intra-cluster rays in the
    %   channel model. The default value of this property is true.
    IntraClusterRays (1, 1) logical = true
end

properties(Constant, Hidden)
    EnvironmentSet = matlab.system.StringSet({ ...
        'Open area hotspot', 'Street canyon hotspot', 'Large hotel lobby'});
    UserConfigurationSet = matlab.system.StringSet({ ...
        'SU-SISO', 'SU-MIMO 1x1', 'SU-MIMO 2x2'});
    ArrayPolarizationSet = matlab.system.StringSet({ ...
        'Single, Single', 'Dual, Dual', 'Single, Dual'});
    TransmitArrayPolarizationSet = matlab.system.StringSet({ ...
        'None', 'Vertical', 'Horizontal', 'LHCP', 'RHCP'});
    ReceiveArrayPolarizationSet = matlab.system.StringSet({ ...
        'None', 'Vertical', 'Horizontal', 'LHCP', 'RHCP'});
    ReceiveArrayVelocitySourceSet = matlab.system.StringSet( ...
        {'Auto', 'Custom'});
    BeamformingMethodSet = matlab.system.StringSet({ ...
        'Maximum power ray', 'Custom'});
    RandomStreamSet = matlab.system.StringSet({ ...
        'Global stream', 'mt19937ar with seed'});
    % Refer to Table 2-3, 2-4, 2-5 in [1]
    MaterialLibrary = [ ...
        comm.internal.channel.Material( ... % Ground for open area
            'Name',                 'Asphalt', ...
            'RelativePermittivity', 4+0.2j, ...
            'Roughness',            3e-4), ...
        comm.internal.channel.Material( ... % Road and sidewalk for street canyon
            'Name',                 'Asphalt', ...
            'RelativePermittivity', 4+0.2j, ...
            'Roughness',            2e-4), ...
        comm.internal.channel.Material( ... % Wall for street canyon
            'Name',                 'Concrete', ...
            'RelativePermittivity', 6.25+0.3j, ...
            'Roughness',            5e-4), ...
        comm.internal.channel.Material( ... % Floor for hotel lobby
            'Name',                 'Concrete', ...
            'RelativePermittivity', 4+0.2j, ...
            'Roughness',            1e-4), ...
        comm.internal.channel.Material( ... % Wall for hotel lobby
            'Name',                 'Concrete', ...
            'RelativePermittivity', 4+0.2j, ...
            'Roughness',            2e-4), ...
        comm.internal.channel.Material( ... % Ceiling for hotel lobby
            'Name',                 'Plasterboard', ...
            'RelativePermittivity', 6.25+0.3j, ...
            'Roughness',            2e-4)];            
end

properties (Access = private, Nontunable) 
    % Number of Tx arrays    
    pNumTxArray
    % Number of Rx arrays   
    pNumRxArray
    % Number of Tx streams
    pNumTxStreams
    % Number of Rx streams
    pNumRxStreams
    % Tx array centroid position(s) in GCS 
    pTxPosition
    % Rx array centroid position(s) in GCS
    pRxPosition
    % Case number for one of the 7 supported cases
    pIOStreamCase
end

properties (Access = private)
    % D-Rays from ray-tracing
    pDRays
    % All rays including D-Rays, R-Rays and intra-cluster rays
    pAllRays
    % Time of arrival for all rays
    pToA
    % Number of rays
    pNumRays
    % Tx array phasor/steering vector
    pTxPV    
    % Rx array phasor/steering vector
    pRxPV
    % Amplitude and phase (in a complex number) for each ray
    pRayGain
    % CIR without Doppler shift
    pStaticCIR
    % Doppler shift from Rx velocity
    pDopplerShift
    % RNG stream
    pRNGStream
    % Number of samples that have been processed by the channel
    pNumSampProcessed = 0
    % 3D figure handle from showEnvironment method
    pEnvFig
    % Cell array of channel filter objects
    cChannelFilter
    % Azimuth and elevation angle of departure in degrees of rays between transmit and receive antennas 
    pAnglesOfArrival
    % Azimuth and elevation angle of arrival in degrees of rays between transmit and receive antennas 
    pAnglesOfDeparture
end

methods
  function obj = wlanTGayChannel(varargin)
    setProperties(obj, nargin, varargin{:});
    if isempty(coder.target)
        if isempty(obj.TransmitArray)
            obj.TransmitArray = wlanURAConfig;
        end
        if isempty(obj.ReceiveArray)
            obj.ReceiveArray = wlanURAConfig;
        end
    else
        if ~coder.internal.is_defined(obj.TransmitArray)
            obj.TransmitArray = wlanURAConfig;
        end
        if ~coder.internal.is_defined(obj.ReceiveArray)
            obj.ReceiveArray = wlanURAConfig;
        end
    end
  end
  
  function set.SampleRate(obj, Rs)
    propName = 'SampleRate';
    validateattributes(Rs, {'double'}, ...
        {'real','positive','scalar','finite'}, ...
        [class(obj) '.' propName], propName); 

    obj.SampleRate = Rs;    
  end
    
  function set.CarrierFrequency(obj, fc)
    propName = 'CarrierFrequency';
    validateattributes(fc, {'double'}, ...
        {'real','positive','scalar','finite'}, ...
        [class(obj) '.' propName], propName); 

    obj.CarrierFrequency = fc;    
  end
    
  function set.RoadWidth(obj, rw)
    propName = 'RoadWidth';
    validateattributes(rw, {'double'}, ...
        {'real','positive','scalar','finite'}, ...
        [class(obj) '.' propName], propName); 

    obj.RoadWidth = rw;
  end
  
  function set.SidewalkWidth(obj, sww)
    propName = 'SidewalkWidth';
    validateattributes(sww, {'double'}, ...
        {'real','positive','scalar','finite'}, ...
        [class(obj) '.' propName], propName); 

    obj.SidewalkWidth = sww;
  end
  
  function set.RoomDimensions(obj, rd)
    propName = 'RoomDimensions';
    validateattributes(rd, {'double'}, ...
        {'real','positive','finite','size',[1 3]}, ...
        [class(obj) '.' propName], propName); 

    obj.RoomDimensions = rd;
  end
  
  function set.ArraySeparation(obj, arraySep)
    propName = 'ArraySeparation';
    validateattributes(arraySep, {'double'}, ...
        {'real','positive','finite','size',[1 2]}, ...
        [class(obj) '.' propName], propName); 

    obj.ArraySeparation = arraySep;
  end
  
  function set.TransmitArray(obj, txArray)
    propName = 'TransmitArray';
    validateattributes(txArray, {'wlanURAConfig'}, ...
        {'scalar'}, [class(obj) '.' propName], propName); 

    obj.TransmitArray = txArray;      
  end
  
  function set.TransmitArrayPosition(obj, txPos)
    propName = 'TransmitArrayPosition';
    validateattributes(txPos, {'double'}, ...
        {'real','finite','size',[3 1]}, ...
        [class(obj) '.' propName], propName);

    obj.TransmitArrayPosition = txPos;
  end
  
  function set.TransmitArrayOrientation(obj, txOri)
    propName = 'TransmitArrayOrientation';
    validateattributes(txOri, {'double'}, ...
        {'real','finite','size',[3 1]}, ...
        [class(obj) '.' propName], propName);
    
    obj.TransmitArrayOrientation = txOri;       
  end
  
  function set.ReceiveArray(obj, rxArray)
    propName = 'ReceiveArray';
    validateattributes(rxArray, {'wlanURAConfig'}, ...
        {'scalar'}, [class(obj) '.' propName], propName); 

    obj.ReceiveArray = rxArray;      
  end
  
  function set.ReceiveArrayPosition(obj, rxPos)
    propName = 'ReceiveArrayPosition';
    validateattributes(rxPos, {'double'}, ...
        {'real','finite','size',[3 1]}, ...
        [class(obj) '.' propName], propName);
    
    obj.ReceiveArrayPosition = rxPos;      
  end
  
  function set.ReceiveArrayOrientation(obj, rxOri)
    propName = 'ReceiveArrayOrientation';
    validateattributes(rxOri, {'double'}, ...
        {'real','finite','size',[3 1]}, ...
        [class(obj) '.' propName], propName);
    
    obj.ReceiveArrayOrientation = rxOri;       
  end
 
  function set.ReceiveArrayVelocity(obj, rxVel)
    propName = 'ReceiveArrayVelocity';
    validateattributes(rxVel, {'double'}, ...
        {'real','finite','size',[3 1]}, ...
        [class(obj) '.' propName], propName);
    
    obj.ReceiveArrayVelocity = rxVel;
  end
  
  function set.OxygenAbsorption(obj, oa)
    propName = 'OxygenAbsorption';
    validateattributes(oa, {'double'}, ...
        {'real','nonnegative','scalar','finite'}, ...
        [class(obj) '.' propName], propName);
    
    obj.OxygenAbsorption = oa;       
  end
  
  function set.TransmitBeamformingVectors(obj, txBF)
    propName = 'TransmitBeamformingVectors';
    validateattributes(txBF, {'double'}, {'finite','2d'}, ...
        [class(obj) '.' propName], propName);
    
    obj.TransmitBeamformingVectors = txBF;
  end
  
  function set.ReceiveBeamformingVectors(obj, rxBF)
    propName = 'ReceiveBeamformingVectors';
    validateattributes(rxBF, {'double'}, {'finite','2d'}, ...
        [class(obj) '.' propName], propName);
    
    obj.ReceiveBeamformingVectors = rxBF;       
  end
  
  function set.Seed(obj, seed)
    propName = 'Seed';
    validateattributes(seed, {'double'}, ...
        {'real','nonnegative','integer','scalar','finite'}, ...
        [class(obj) '.' propName], propName); 

    obj.Seed = seed;
  end
  
  function showEnvironment(obj, varargin)
    %SHOWENVIRONMENT Display specified environment with D-Rays from ray-tracing
    %   showEnvironment(CHAN) shows a 3-D figure for the specified
    %   environment and the transmit and receive antenna arrays therein,
    %   based on the configuration of the wlanTGayChannel object, CHAN.
    %   When the environment and array specifications are valid,
    %   ray-tracing is performed and D-Rays are also shown from each
    %   transmit to each receive array.
    % 
    %   showEnvironment(CHAN, ENVONLY) optionally turns off ray-tracing. No
    %   D-Ray is shown. ENVONLY is a logical variable and defaults to false
    %   if not specified.

    coder.internal.errorIf(~isempty(coder.target), ...
        'wlan:wlanTGayChannel:NoCodegenForVisual');
    
    narginchk(1,2);    
    
    if nargin == 2
        validateattributes(varargin{1}, {'logical'}, {'scalar'}, ...
            [class(obj) '.showEnvironment' ], 'the ray-tracing input');
        envOnly = varargin{1};
    else
        envOnly = false;
    end    
   
    % Set up figure
    if isempty(obj.pEnvFig) || ~isvalid(obj.pEnvFig)
        obj.pEnvFig = figure('Tag', [class(obj), 'Environment']);
    else        
        set(0,'CurrentFigure',obj.pEnvFig);
        clf(obj.pEnvFig);
    end

    % Configure figure
    hold on; grid on; xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)'); view(10, 10);
    ax = gca;
    ax.Color = 'none';
    axis(ax,'equal');
    
    switch obj.Environment
        case 'Open area hotspot'
            if envOnly
                titleStr = getString(message('wlan:wlanTGayChannel:PlotTitleOpenArea'));
            else % with D-Rays
                titleStr = getString(message('wlan:wlanTGayChannel:PlotTitleOpenAreaDRays'));
            end
        case 'Street canyon hotspot'
            if envOnly
                titleStr = getString(message('wlan:wlanTGayChannel:PlotTitleStreetCanyon'));
            else % with D-Rays
                titleStr = getString(message('wlan:wlanTGayChannel:PlotTitleStreetCanyonDRays'));
            end
        otherwise % Large hotel lobby
            if envOnly
                titleStr = getString(message('wlan:wlanTGayChannel:PlotTitleLargeHotel'));
            else % with D-Rays
                titleStr = getString(message('wlan:wlanTGayChannel:PlotTitleLargeHotelDRays'));
            end
    end
    title(titleStr, 'Tag', [class(obj), 'EnvironmentTitle']);
    
    % Parameters
    groundColor   = '--mw-graphics-colorNeutral-line-primary';   % Ground color
    wallColor     = '--mw-graphics-colorNeutral-line-primary';  % Wall color
    sidewalkColor = '--mw-graphics-colorNeutral-region-secondary';  % Sidewalk color
    ceilingColor  = '--mw-graphics-colorNeutral-line-primary';  % Ceiling color
        
    % Get Tx/Rx array and element positions    
    [txPos, rxPos, txElPosLCS, rxElPosLCS, ...
          txElPosGCS, rxElPosGCS] = getArrayPositions(obj);

    % Get triangulation facets for the specified environment
    [~, facets] = wlanTGayChannel.buildEnvironment( ...
        obj.Environment, ...
        obj.RoadWidth, ...
        obj.SidewalkWidth, ...
        obj.RoomDimensions, ...
        txPos, ...
        rxPos);

    % Draw environment
    if strcmp(obj.Environment, 'Open area hotspot')
        % Draw the ground
        themeablePatch(facets(1,:), facets(2,:), facets(3,:), ...
            groundColor, 'Tag', [class(obj), 'OpenAreaGround']);
        zlim([0, max([txPos(3,:), rxPos(3, :)]) * 1.2]);
    elseif strcmp(obj.Environment, 'Street canyon hotspot')        
        % Limit view between the walls
        xlim([-obj.RoadWidth/2-obj.SidewalkWidth ...
               obj.RoadWidth/2+obj.SidewalkWidth]);
        zlim([0, max([txPos(3,:), rxPos(3,:)]) * 1.2]);
        
        % Draw the road
        themeablePatch(facets(1,:,1), facets(2,:,1), facets(3,:,1), ...
            groundColor, 'Tag', [class(obj), 'StreetCanyonGround']);
        % Draw the sidewalks
        themeablePatch(facets(1,:,2), facets(2,:,2), facets(3,:,2), ...
            sidewalkColor, 'FaceAlpha', .8,'Tag', [class(obj), 'StreetCanyonSidewalk1']);
        themeablePatch(facets(1,:,3), facets(2,:,3), facets(3,:,3), ...
            sidewalkColor, 'FaceAlpha', .8, 'Tag', [class(obj), 'StreetCanyonSidewalk2']);
        % Draw the walls
        themeablePatch(facets(1,:,4), facets(2,:,4), facets(3,:,4), ...
            wallColor, 'FaceAlpha', .7, 'Tag', [class(obj), 'StreetCanyonWall1']);
        themeablePatch(facets(1,:,5), facets(2,:,5), facets(3,:,5), ...
            wallColor, 'FaceAlpha', .7, 'Tag', [class(obj), 'StreetCanyonWall2']);
    else % Large hotel lobby
        xlim([-obj.RoomDimensions(1)/2 obj.RoomDimensions(1)/2]);
        ylim([-obj.RoomDimensions(2)/2 obj.RoomDimensions(2)/2]);
        zlim([0 obj.RoomDimensions(3)]);
        
        % Draw the ground
        themeablePatch(facets(1,:,1), facets(2,:,1), facets(3,:,1), ...
            groundColor, 'Tag', [class(obj), 'HotelLobbyGround']);
        % Draw the walls
        themeablePatch(facets(1,:,2), facets(2,:,2), facets(3,:,2), ...
            wallColor, 'FaceAlpha', .4, 'Tag', [class(obj), 'HotelLobbyWall1']);
        themeablePatch(facets(1,:,3), facets(2,:,3), facets(3,:,3), ...
            wallColor, 'FaceAlpha', .4, 'Tag', [class(obj), 'HotelLobbyWall2']);
        themeablePatch(facets(1,:,4), facets(2,:,4), facets(3,:,4), ...
            wallColor,'FaceAlpha', .4, 'Tag', [class(obj), 'HotelLobbyWall3']);
        themeablePatch(facets(1,:,5), facets(2,:,5), facets(3,:,5), ...
            wallColor, 'FaceAlpha', .4, 'Tag', [class(obj), 'HotelLobbyWall4']);
        % Draw the ceiling
        themeablePatch(facets(1,:,6), facets(2,:,6), facets(3,:,6), ...
            ceilingColor, 'FaceAlpha', .4, 'Tag', [class(obj), 'HotelLobbyCeil']);
    end
    
    % Skip plotting Tx & Rx for invalid element positions
    try  %#ok<EMTC>
        validateArrayPositions(obj);
    catch
        warndlg( ...
            getString(message('wlan:wlanTGayChannel:InvalidArrayForVisual')), ...
            getString(message('wlan:wlanTGayChannel:WarnDialogTitle')));
        return;
    end
    
    % Draw Tx array(s)
    plotArrays(obj, 'Tx', txPos, txElPosLCS, txElPosGCS);
   
    % Draw Rx array(s)
    plotArrays(obj, 'Rx', rxPos, rxElPosLCS, rxElPosGCS);

    % Draw D-rays 
    if ~envOnly
        for k = 1:size(txPos, 2)
            for j = 1:size(rxPos, 2)
                wlanTGayChannel.performRaytracing( ...
                    obj.CarrierFrequency, ...
                    obj.Environment, ...
                    obj.RoadWidth, ...
                    obj.SidewalkWidth, ...
                    obj.RoomDimensions, ...
                    obj.OxygenAbsorption, ...
                    txPos(:,k), ...
                    rxPos(:,j), ...
                    getLCStoGCSRotationMatrix(obj.TransmitArrayOrientation), ...
                    getLCStoGCSRotationMatrix(obj.ReceiveArrayOrientation), ...
                    0, ...
                    true);
            end
        end
    end
  end
end

methods(Access = protected)         
  function validatePropertiesImpl(obj)
    % Validate SU-SISO and SU-MIMO configs against supported ones in [1].
    validateUserConfig(obj);
    
    % Check Tx/Rx array element positions are within specified environment
    validateArrayPositions(obj);
    
    % Validate Tx beamforming vector dimension
    NTE = obj.TransmitArray.getNumElements;
    NTS = obj.pNumTxStreams;
    coder.internal.errorIf(strcmp(obj.BeamformingMethod, 'Custom') && ...
        any(size(obj.TransmitBeamformingVectors) ~= [NTE, NTS]), ...
        'wlan:wlanTGayChannel:InvalidTxBFVectorSize');
    
    % Validate Rx beamforming vector dimension
    NRE = obj.ReceiveArray.getNumElements;
    NRS = obj.pNumRxStreams;
    coder.internal.errorIf(strcmp(obj.BeamformingMethod, 'Custom') && ...
        any(size(obj.ReceiveBeamformingVectors) ~= [NRE, NRS]), ...
        'wlan:wlanTGayChannel:InvalidRxBFVectorSize');    
  end
   
  function validateInputsImpl(obj, x)
    validateattributes(x, {'double','single'}, ...
        {'ncols', obj.pNumTxStreams, 'finite'}, ...
        class(obj), 'the signal input');
  end

  function setupImpl(obj)
    coder.extrinsic('wlanTGayChannel.performRaytracing');
    
    % Set up RNG
    setupRNG(obj);

    % Perform ray-tracing to figure out D-Rays for each Tx-Rx pair
    obj.pDRays = cell(obj.pNumTxArray, obj.pNumRxArray);
    for k = coder.unroll(1:obj.pNumTxArray)
        for j = coder.unroll(1:obj.pNumRxArray)
            [toa, aod, aoa, amplitude, phaseShift, polMatrix] = ...
                coder.const(@wlanTGayChannel.performRaytracing, ...
                obj.CarrierFrequency, ...
                obj.Environment, ...
                obj.RoadWidth, ...
                obj.SidewalkWidth, ...
                obj.RoomDimensions, ...
                obj.OxygenAbsorption, ...
                obj.pTxPosition(:,k), ...
                obj.pRxPosition(:,j), ...
                getLCStoGCSRotationMatrix(obj.TransmitArrayOrientation), ...
                getLCStoGCSRotationMatrix(obj.ReceiveArrayOrientation), ...
                obj.pIOStreamCase, ...
                false);
            
            obj.pDRays{k,j} = struct( ...
                'TimeOfArrival',        toa, ...
                'AngleOfDeparture',     aod, ...
                'AngleOfArrival',       aoa, ...
                'Amplitude',            amplitude, ...
                'PhaseShift',           phaseShift, ...
                'PolarizationMatrix',   polMatrix);            
        end
    end

    % Generate R-Rays and intra-cluster rays as specified. Sort out all
    % rays based upon ToA.
    generateAllRays(obj);

    % Calculate CIR with beamforming applied
    calculateCIR(obj);

    % Calculate Doppler shift for each ray after generating Rx velocity
    % randomly
    generateDopplerShifts(obj);

    % Set up channel filters
    setupChannelFilters(obj);
  end
   
  function resetImpl(obj)    
    % Reset RNG
    resetRNG(obj);
    
    % For the global stream option, R-Rays and intra-cluster rays are
    % regenerated at each reset call after the first frame
    if strcmp(obj.RandomStream, 'Global stream') && (obj.pNumSampProcessed > 0)
        % Regenerate R-Rays and intra-cluster rays as specified. Sort out
        % all rays based upon ToA.
        generateAllRays(obj);

        % Re-calculate CIR with beamforming applied
        calculateCIR(obj);

        % Re-calculate Doppler shift for each ray after regenerating Rx
        % velocity randomly
        generateDopplerShifts(obj);

        % Update channel filter path delays using new ToA. Doing this will
        % also reset the channel filters.
        updateChannelFilterDelays(obj);
    else
        % Reset channel filters
        resetChannelFilters(obj);
    end
    
    % Reset number of samples processed
    obj.pNumSampProcessed = 0;     
  end
  
  function processTunedPropertiesImpl(obj)    
    if strcmp(obj.BeamformingMethod, 'Custom')
        numTxArray = obj.pNumTxArray;
        numRxArray = obj.pNumRxArray;

        % Parse beamforming vectors
        txBF = cell(numTxArray, numRxArray);
        rxBF = cell(numTxArray, numRxArray);
        for k = coder.unroll(1:numTxArray)
            for j = coder.unroll(1:numRxArray)
                switch obj.pIOStreamCase
                    case 4
                        txBF{k,j} = obj.TransmitBeamformingVectors(:,k);  % [NTE, NTS_K]
                        rxBF{k,j} = obj.ReceiveBeamformingVectors(:,j);   % [NRE, NRS_J]
                    case 5
                        txBF{k,j} = obj.TransmitBeamformingVectors(:,2*(k-1)+(1:2));  % [NTE, NTS_K]
                        rxBF{k,j} = obj.ReceiveBeamformingVectors(:, 2*(j-1)+(1:2));  % [NTE, NRS_J]
                    otherwise % 0, 1, 2, 3, 6
                        txBF{k,j} = obj.TransmitBeamformingVectors; % [NTE NTS] = [NTE NTS_K]
                        rxBF{k,j} = obj.ReceiveBeamformingVectors;  % [NRE NRS] = [NRE NRS_K]
                end
            end
        end
        
        % Update CIR
        updateCIR(obj, txBF, rxBF);
    end
  end

  function [y, CIR] = stepImpl(obj, x)
    numTxArray = obj.pNumTxArray;
    numRxArray = obj.pNumRxArray;
  
    % Parse input
    switch obj.pIOStreamCase
        case 4 % 2 Tx and Rx arrays. NTS = NRS = 2. 
            % First Tx gets V stream and second Tx gets H stream
            allX = {x(:,1) x(:,1); x(:,2) x(:,2)};
        case 5 % 2 Tx and Rx arrays. NTS = NRS = 4
            % First Tx gets V&H streams and second Tx gets another V&H
            % streams
            allX = {x(:,1:2) x(:,1:2); x(:,3:4) x(:,3:4)};
        otherwise % 1 Tx and Rx array
            allX = {x};
    end
    
    % Get time duration for this frame
    Ns = size(x, 1);
    duration = (obj.pNumSampProcessed + (0:(Ns-1))') / obj.SampleRate; % [Ns, 1]
    
    % Calculate signal outputs at Rx arrays
    allY = cell(numTxArray, numRxArray);
    g = cell(numTxArray, numRxArray);    
    for k = coder.unroll(1:numTxArray)
        for j = coder.unroll(1:numRxArray)
            staticCIR = obj.pStaticCIR{k,j}; % [1 NRS_J NTS_K NP]
            fd = obj.pDopplerShift{k,j};     % [1 1 1 NP]
            
            % Apply Doppler shift for each ray to formulate 4-D CIR array
            g{k,j} = cast(exp(1i*2*pi*duration.*fd).*staticCIR,'like',x); % [Ns, NRS_J, NTS_K, NP]
            % Perform channel filtering for each Tx-Rx array pair
            %#exclude step
            allY{k,j} = step(obj.cChannelFilter{k,j}, allX{k,j}, g{k,j});
        end
    end
        
    % Combine signals at Rx
    if obj.pNumTxArray == 1
        y = allY{1,1};
    else
        y = [allY{1,1} + allY{2,1}, ...
             allY{1,2} + allY{2,2}];
    end
    
                
    % Normalize channel outputs
    if obj.NormalizeChannelOutputs 
        y = y/sqrt(obj.pNumRxStreams);
    end            

    % Formulate CIR output as requested
    if nargout == 2        
        if numTxArray > 1 
            % In some rare cases, the CIR for each Tx-Rx pair may have
            % different number of rays. Do zero padding along the ray
            % dimension before concatenating them.
            NTS = obj.pNumTxStreams;
            NRS = obj.pNumRxStreams;
            maxNumRays = max(obj.pNumRays(:));
            CIR = complex(zeros(Ns, maxNumRays, NTS, NRS, 'like', g{1,1}));
            % Aggregate CIRs for different Tx-Rx pairs into one 4D array.
            % We can use "cat" function to simply the code. Writing it this
            % way for codegen to work. 
            for k = coder.unroll(1:numTxArray)
                for j = coder.unroll(1:numRxArray)
                    CIR(:,1:obj.pNumRays(k,j), ...
                        (k-1)*NTS/2+(1:NTS/2), ...
                        (j-1)*NRS/2+(1:NRS/2)) = permute(g{k,j}, [1 4 3 2]);
                end
            end
        else
            CIR = permute(g{1,1}, [1 4 3 2]); % [Ns NP NTS NRS]
        end
    end
     
   % Update number of samples processed
   obj.pNumSampProcessed = obj.pNumSampProcessed + Ns;
  end
  
  function releaseImpl(obj)
    for k = coder.unroll(1:obj.pNumTxArray)
        for j = coder.unroll(1:obj.pNumRxArray)
            obj.cChannelFilter{k,j}.release;
        end
    end
    obj.pNumSampProcessed = 0;
  end
  
  function flag = isInactivePropertyImpl(obj, prop) 
    if any(strcmp(prop, {'RoadWidth', 'SidewalkWidth'}))
        flag = ~strcmp(obj.Environment, 'Street canyon hotspot');
    elseif strcmp(prop, 'RoomDimensions') 
        flag = ~strcmp(obj.Environment, 'Large hotel lobby'); 
    elseif strcmp(prop, 'ArrayPolarization')
        flag = strcmp(obj.UserConfiguration, 'SU-SISO');
    elseif strcmp(prop, 'ArraySeparation')
        flag = ~strcmp(obj.UserConfiguration, 'SU-MIMO 2x2');
    elseif any(strcmp(prop, {'TransmitArrayPolarization', 'ReceiveArrayPolarization'}))
        flag = ~strcmp(obj.UserConfiguration, 'SU-SISO');
    elseif any(strcmp(prop, {'TransmitBeamformingVectors', 'ReceiveBeamformingVectors'}))
        flag = strcmp(obj.BeamformingMethod, 'Maximum power ray');
    elseif strcmp(prop, 'ReceiveArrayVelocity')
        flag = strcmp(obj.ReceiveArrayVelocitySource, 'Auto');
    elseif strcmp(prop, 'Seed')
        flag = strcmp(obj.RandomStream, 'Global stream');
    else
        flag = false;
    end
  end
  
  function s = infoImpl(obj)
    %info Returns characteristic information about the channel
    %   S = info(OBJ) returns a structure containing characteristic
    %   information, S, about the 802.11ay channel. A description of the
    %   fields and their values is as follows:
    %
    %   ChannelFilterDelay  - Channel filter delay (samples)
    %   NumSamplesProcessed - Number of samples the channel has processed
    %                         since the last reset
    %   NumTxStreams        - Number of transmit streams
    %   NumRxStreams        - Number of receive streams
    %   NumTxElements       - Number of elements in each transmit array
    %   NumRxElements       - Number of elements in each receive array
    %   AnglesOfDeparture   - Azimuth and elevation angles of departure for
    %                         each Tx-Rx array pair. This field is only
    %                         available when the object is in lock state.
    %   AnglesOfArrival     - Azimuth and elevation angles of arrival for
    %                         each Tx-Rx array pair. This field is only
    %                         available when the object is in lock state.
    %   PathDelays          - Path delays for each Tx-Rx array pair. This
    %                         field is only available when the object is in
    %                         lock state.
    %   DopplerShifts       - Doppler shifts per path per Tx-Rx array pair.
    %                         This field is only available when the object
    %                         is in lock state.

    if ~isempty(coder.target) || ~isLocked(obj)
        validateUserConfig(obj);
    end
    
    s.ChannelFilterDelay  = 7;
    s.NumSamplesProcessed = obj.pNumSampProcessed;
    s.NumTxStreams        = obj.pNumTxStreams;
    s.NumRxStreams        = obj.pNumRxStreams;
    s.NumTxElements       = obj.TransmitArray.getNumElements;
    s.NumRxElements       = obj.ReceiveArray.getNumElements;

    %#exclude coder.internal.prop_has_class
    if (isempty(coder.target) && isLocked(obj)) || (~isempty(coder.target) && coder.internal.prop_has_class(obj,'pToA'))
        if obj.pNumTxArray == 1 && obj.pNumRxArray == 1
            s.AnglesOfDeparture = obj.pAnglesOfDeparture{1,1};
            s.AnglesOfArrival = obj.pAnglesOfArrival{1,1};
            s.PathDelays = obj.pToA{1};
            s.DopplerShifts = shiftdim(obj.pDopplerShift{1}, 2);
        else
            s.AnglesOfDeparture = obj.pAnglesOfDeparture;
            s.AnglesOfArrival = obj.pAnglesOfArrival;
            s.PathDelays = obj.pToA;
            s.DopplerShifts = cell(size(obj.pDopplerShift));
            for i=1:numel(obj.pDopplerShift)
                s.DopplerShifts{i} = squeeze(obj.pDopplerShift{i}).';
            end
        end
    end
  end
  
  function s = saveObjectImpl(obj)
    s = saveObjectImpl@matlab.System(obj);
    if isLocked(obj)
        s.pNumTxArray        = obj.pNumTxArray;
        s.pNumRxArray        = obj.pNumRxArray;
        s.pNumTxStreams      = obj.pNumTxStreams;
        s.pNumRxStreams      = obj.pNumRxStreams;
        s.pTxPosition        = obj.pTxPosition;
        s.pRxPosition        = obj.pRxPosition;
        s.pIOStreamCase      = obj.pIOStreamCase;
        s.pDRays             = obj.pDRays;
        s.pAllRays           = obj.pAllRays;
        s.pToA               = obj.pToA;
        s.pNumRays           = obj.pNumRays;
        s.pTxPV              = obj.pTxPV;
        s.pRxPV              = obj.pRxPV;
        s.pRayGain           = obj.pRayGain;
        s.pStaticCIR         = obj.pStaticCIR;
        s.pDopplerShift      = obj.pDopplerShift;
        s.pRNGStream         = obj.pRNGStream;
        s.pNumSampProcessed  = obj.pNumSampProcessed;
        s.pEnvFig            = obj.pEnvFig;
        s.pAnglesOfDeparture = obj.pAnglesOfDeparture;
        s.pAnglesOfArrival   = obj.pAnglesOfArrival;
        s.cChannelFilter     = cellfun( ...
            @(x)matlab.System.saveObject(x), obj.cChannelFilter, ...
            'UniformOutput', false);
    end
  end  
  
  function loadObjectImpl(obj, s, wasLocked)
    if wasLocked
        obj.pNumTxArray       = s.pNumTxArray;
        obj.pNumRxArray       = s.pNumRxArray;
        obj.pNumTxStreams     = s.pNumTxStreams;
        obj.pNumRxStreams     = s.pNumRxStreams;
        obj.pTxPosition       = s.pTxPosition;
        obj.pRxPosition       = s.pRxPosition;
        obj.pIOStreamCase     = s.pIOStreamCase;
        obj.pDRays            = s.pDRays;
        obj.pAllRays          = s.pAllRays;
        obj.pToA              = s.pToA;
        obj.pNumRays          = s.pNumRays;
        obj.pTxPV             = s.pTxPV;
        obj.pRxPV             = s.pRxPV;
        obj.pRayGain          = s.pRayGain;
        obj.pStaticCIR        = s.pStaticCIR;
        obj.pDopplerShift     = s.pDopplerShift;
        obj.pRNGStream        = s.pRNGStream;
        obj.pNumSampProcessed = s.pNumSampProcessed;
        obj.pEnvFig           = s.pEnvFig;
        obj.cChannelFilter    = cellfun( ...
            @(x)matlab.System.loadObject(x), s.cChannelFilter, ...
            'UniformOutput', false);

        % New property in R2022a
        if isfield(s,'pAngleOfDeparture') && isfield(s,'pAngleOfArrival')
            obj.pAnglesOfDeparture = s.pAnglesOfDeparture;
            obj.pAnglesOfArrival = s.pAnglesOfArrival;
        end
    end
    loadObjectImpl@matlab.System(obj, s);
  end

  function flag = isInputSizeMutableImpl(~,~)
    flag = true;
  end

  function flag = isInputComplexityMutableImpl(~,~)
    flag = true;
  end
end

methods(Static, Access = protected)
  function groups = getPropertyGroupsImpl
    groups = matlab.system.display.Section( ...
        'Title', 'Parameters', ...
        'PropertyList', {'SampleRate', 'CarrierFrequency', ...
        'Environment', 'RoadWidth', 'SidewalkWidth', 'RoomDimensions', ...
        'UserConfiguration', 'ArraySeparation', 'ArrayPolarization',  ...     
        'TransmitArray', 'TransmitArrayPosition', ...
        'TransmitArrayOrientation', 'TransmitArrayPolarization', ...
        'ReceiveArray', 'ReceiveArrayPosition', ...
        'ReceiveArrayOrientation', 'ReceiveArrayPolarization', ...
        'ReceiveArrayVelocitySource', 'ReceiveArrayVelocity', ...
        'RandomRays', 'IntraClusterRays', 'OxygenAbsorption', ...
        'BeamformingMethod', ...
        'TransmitBeamformingVectors', 'ReceiveBeamformingVectors', ...
        'NormalizeImpulseResponses', 'NormalizeChannelOutputs', ...
        'RandomStream', 'Seed'});        
  end
end

methods (Access = private)  % Validation related methods    
  function validateUserConfig(obj)
    % Validate against SU-SISO (polarization or not) or SU-MIMO
    % polarization configs. Refer to Table 3-2 in [1].
    
    obj.pNumTxArray = 1 + strcmp(obj.UserConfiguration, 'SU-MIMO 2x2');
    obj.pNumRxArray = obj.pNumTxArray;

    switch obj.UserConfiguration
        case 'SU-SISO'
            obj.pNumTxStreams = 1;
            obj.pNumRxStreams = 1;
            if strcmp(obj.TransmitArrayPolarization, 'None') && ...
                strcmp(obj.ReceiveArrayPolarization,  'None')
                obj.pIOStreamCase = 0;
            elseif ~strcmp(obj.TransmitArrayPolarization, 'None') && ...
                ~strcmp(obj.ReceiveArrayPolarization,  'None')
                obj.pIOStreamCase = 1;
            else
                coder.internal.error( ...
                    'wlan:wlanTGayChannel:InvalidPolForSUSISO');
            end
        case 'SU-MIMO 1x1'
            switch obj.ArrayPolarization
                case 'Single, Single'
                    obj.pNumTxStreams = 2;
                    obj.pNumRxStreams = 2;
                    obj.pIOStreamCase = 2;
                case 'Dual, Dual'
                    obj.pNumTxStreams = 2;
                    obj.pNumRxStreams = 2;
                    obj.pIOStreamCase = 3;
                otherwise % 'Single, Dual'
                    obj.pNumTxStreams = 1;
                    obj.pNumRxStreams = 2;
                    obj.pIOStreamCase = 6;
            end
        otherwise % SU-MIMO 2x2'
            switch obj.ArrayPolarization
                case 'Single, Single'
                    obj.pNumTxStreams = 2;
                    obj.pNumRxStreams = 2;
                    obj.pIOStreamCase = 4;
                case 'Dual, Dual'
                    obj.pNumTxStreams = 4;
                    obj.pNumRxStreams = 4;
                    obj.pIOStreamCase = 5;
                otherwise % 'Single, Dual'
                    coder.internal.error( ...
                        'wlan:wlanTGayChannel:InvalidPolForSUMIMO');
            end
    end
  end    
  
  function [txPos, rxPos, txElPosLCS, rxElPosLCS, ...
          txElPosGCS, rxElPosGCS] = getArrayPositions(obj)
    
    % Centroid [x;y;z] positions for the primary Tx/Rx array in GCS
    txPrimPos = obj.TransmitArrayPosition; 
    rxPrimPos = obj.ReceiveArrayPosition;
    
    % Element [x;y;z] positions for the primary Tx/Rx array in LCS
    txElPrimPosLCS = obj.TransmitArray.getElementPosition;
    rxElPrimPosLCS = obj.ReceiveArray.getElementPosition;        
    
    % Tx/Rx array orientation
    txOri = obj.TransmitArrayOrientation;
    rxOri = obj.ReceiveArrayOrientation;
    
    % Get Tx/Rx array centroid positions (for ray-tracing) and Tx/Rx
    % element positions in GCS
    if strcmp(obj.UserConfiguration, 'SU-MIMO 2x2')       
        txPos = [txPrimPos, convertPosLCStoGCS( ...
            [obj.ArraySeparation(1); 0; 0], txOri, txPrimPos)];
        rxPos = [rxPrimPos, convertPosLCStoGCS( ...
            [obj.ArraySeparation(2); 0; 0], rxOri, rxPrimPos)];
        txElPosLCS = [txElPrimPosLCS, ...
                        txElPrimPosLCS+[obj.ArraySeparation(1); 0; 0]];
        rxElPosLCS = [rxElPrimPosLCS, ...
                        rxElPrimPosLCS+[obj.ArraySeparation(2); 0; 0]];
    else
        txPos = txPrimPos;
        rxPos = rxPrimPos;
        txElPosLCS = txElPrimPosLCS;
        rxElPosLCS = rxElPrimPosLCS;
    end
    
    txElPosGCS = convertPosLCStoGCS(txElPosLCS, txOri, txPrimPos);
    rxElPosGCS = convertPosLCStoGCS(rxElPosLCS, rxOri, rxPrimPos);
  end
  
  function validateArrayPositions(obj)
    % Get array related LCS and GCS positions
    [obj.pTxPosition, obj.pRxPosition, txElPosLCS, rxElPosLCS, ...
          txElPosGCS, rxElPosGCS] = getArrayPositions(obj);
        
    % Check elements are not overlapping when there are 2 Tx/Rx arrays
    coder.internal.errorIf( ...
        strcmp(obj.UserConfiguration, 'SU-MIMO 2x2') && ...
        2*max(txElPosLCS(1, 1:end/2)) >= obj.ArraySeparation(1), ...
        'wlan:wlanTGayChannel:OverlappedTxArrays');
    coder.internal.errorIf( ...
       strcmp(obj.UserConfiguration, 'SU-MIMO 2x2') && ...
        2*max(rxElPosLCS(1, 1:end/2)) >= obj.ArraySeparation(2), ...
        'wlan:wlanTGayChannel:OverlappedRxArrays');

    % Check no Tx-Tx pair coincides with each other
    for k = coder.unroll(1:obj.pNumTxArray)
        for j = coder.unroll(1:obj.pNumRxArray)
            coder.internal.errorIf( ...
                norm(obj.pTxPosition(:,k) - obj.pRxPosition(:,j)) < sqrt(eps('double')), ...
                'wlan:wlanTGayChannel:InvalidTxRxPositions');
        end
    end
    
    % Check all Tx/Rx elements must be above the ground in all scenarios.
    % And this is all we need to check for the open area scenario.
    coder.internal.errorIf(any(txElPosGCS(3,:) <= 0), ...
        'wlan:wlanTGayChannel:ElementBelowGround', 'transmit');    
    coder.internal.errorIf(any(rxElPosGCS(3,:) <= 0), ...
        'wlan:wlanTGayChannel:ElementBelowGround', 'receive');    
    
    if strcmp(obj.Environment, 'Street canyon hotspot')
        rw = obj.RoadWidth;
        sww = obj.SidewalkWidth;
        
        % All elements of Tx must be between the two walls (x-axis)
        coder.internal.errorIf( ...
            any(txElPosGCS(1,:) <= -(rw/2 + sww)) || ...
            any(txElPosGCS(1,:) >=  (rw/2 + sww)), ...
            'wlan:wlanTGayChannel:ElementBeyondWall', 'transmit');
        
        % All elements of Rx must be between the two walls (x-axis)
        coder.internal.errorIf( ...
            any(rxElPosGCS(1,:) <= -(rw/2 + sww)) || ...
            any(rxElPosGCS(1,:) >=  (rw/2 + sww)), ...
            'wlan:wlanTGayChannel:ElementBeyondWall', 'receive');
        
        % No position check on the y-axis
    elseif strcmp(obj.Environment, 'Large hotel lobby')
        rd = obj.RoomDimensions;
        
        % x, y, z must be within the room for Tx
        coder.internal.errorIf( ...
            any(txElPosGCS(1,:) <= -rd(1)/2) || ...
            any(txElPosGCS(1,:) >=  rd(1)/2) || ...
            any(txElPosGCS(2,:) <= -rd(2)/2) || ...
            any(txElPosGCS(2,:) >=  rd(2)/2) || ...
            any(txElPosGCS(3,:) >=  rd(3)), ...
            'wlan:wlanTGayChannel:ElementOutsideLobby', 'transmit');
        
        % x, y, z must be within the room for Rx
        coder.internal.errorIf( ...
            any(rxElPosGCS(1,:) <= -rd(1)/2) || ...
            any(rxElPosGCS(1,:) >=  rd(1)/2) || ...
            any(rxElPosGCS(2,:) <= -rd(2)/2) || ...
            any(rxElPosGCS(2,:) >=  rd(2)/2) || ...
            any(rxElPosGCS(3,:) >=  rd(3)), ...
            'wlan:wlanTGayChannel:ElementOutsideLobby', 'receive');
    end
  end 
end

methods (Access = private) % Visualization related methods
  function plotArrays(obj, whichArray, posGCS, elPosLCS, elPosGCS) 
    if strcmp(whichArray, 'Tx')
        array = obj.TransmitArray;
        ori   = obj.TransmitArrayOrientation;
        color = '--mw-graphics-colorOrder-5-primary';
    else
        array = obj.ReceiveArray;
        ori   = obj.ReceiveArrayOrientation;
        color = '--mw-graphics-colorOrder-11-quaternary';
    end
        
    numEl = array.getNumElements;
    spacing = array.ElementSpacing;
    boxColor = '--mw-graphics-colorNeutral-line-primary';    

    % Draw all elements
    themeableScatter3(elPosGCS(1,:), elPosGCS(2,:), elPosGCS(3,:), 5, ...
        color, 'filled', 'Tag', [class(obj), 'Array', whichArray]);
   
    if numEl == 1 % No need to draw a panel for single element
        text(posGCS(1,1), posGCS(2,1), posGCS(3,1) + 0.25, ...
            whichArray,'FontWeight', 'bold');
    else
        % Draw a panel to cover the array in LCS
        boxCorner = [elPosLCS(1, 1) - spacing(2)/5;
            elPosLCS(2, 1) + spacing(1)/5;
            0];
        boxLCS = [boxCorner, ...
            boxCorner .* [1; -1;  1], ...
            boxCorner .* [-1; -1; 1], ...
            boxCorner .* [-1; 1;  1]]; % 3 x 4
        
        % Convert the panel into GCS and draw it
        boxGCS = zeros(3, 8);
        for i = 1:size(posGCS, 2)
            idx = (i-1)*4 + (1:4);
            boxGCS(:, idx) = ...
                convertPosLCStoGCS(boxLCS, ori, posGCS(:,i));
            themeablePatch(boxGCS(1,idx), boxGCS(2,idx), boxGCS(3,idx), ...
                boxColor, 'Tag', [class(obj), 'BoxArray', whichArray]);
        end
        
        % Label array
        text(posGCS(1,1), posGCS(2,1), max(boxGCS(3,:)) + 0.25, ...
            whichArray, 'FontWeight', 'bold');
    end    
  end
end

methods (Access = private) % CIR calculation related methods
  function generateAllRays(obj)
    numTxArrays = obj.pNumTxArray;
    numRxArrays = obj.pNumRxArray;
    
    % Generate random R-Rays. Section 4.3 in [1]
    if obj.RandomRays
        RRays = generateRRays(obj);
    else 
        RRays = cell(numTxArrays, numRxArrays);
        for i = 1:numel(RRays) % For codegen to work
            RRays{i} = [];
        end
    end
    
    % Intra-cluster expansion. Section 4.4 in [1]
    if obj.IntraClusterRays
        ICRays = generateIntraClusterRays(obj, RRays);
    else 
        ICRays = cell(numTxArrays, numRxArrays);
        for i = 1:numel(ICRays) % For codegen to work
            ICRays{i} = [];
        end
    end
    
    % Aggregate rays and sort them based on ToA for each Tx-Rx pair
    obj.pAllRays = cell(numTxArrays, numRxArrays);
    obj.pToA = cell(numTxArrays, numRxArrays);
    obj.pNumRays = zeros(numTxArrays, numRxArrays);
    for k = coder.unroll(1:numTxArrays)
        for j = coder.unroll(1:numRxArrays)
            % Aggregate D-Rays, R-Rays and intra-cluster rays
            obj.pAllRays{k,j} = [obj.pDRays{k,j}, RRays{k,j}, ICRays{k,j}]; 
            obj.pToA{k,j} = arrayfun(@(x)x.TimeOfArrival, obj.pAllRays{k,j});
            
            % Sort the rays based on ToA
            [obj.pToA{k,j}, idx] = sort(obj.pToA{k,j});
            obj.pAllRays{k,j} = obj.pAllRays{k,j}(idx);
            obj.pNumRays(k,j) = length(obj.pAllRays{k,j});
        end
    end
  end

  function rays = generateRRays(obj)
    switch obj.Environment
        case 'Open area hotspot' % Refer to Table 5-1 in [1]
            numRRays = 3;
            arrivalRate = 1/(0.05e-9);
            powerDecayTime = 15e-9;
            KFactor = 6; % in dB
            AoD_az_range = 180;
            AoD_el_range = 20;
            AoA_az_range = 180;
            AoA_el_range = 20;
        case 'Street canyon hotspot' % Refer to Table 5-5 in [1]
            numRRays = 5;
            arrivalRate = 1/(0.03e-9);
            powerDecayTime = 20e-9;
            KFactor = 10; % in dB
            AoD_az_range = 180;
            AoD_el_range = 20;
            AoA_az_range = 180;
            AoA_el_range = 20;
        otherwise % Large hotel lobby. Refer to Table 5-8 in [1]
            numRRays = 5;
            arrivalRate = 1/(0.01e-9);
            powerDecayTime = 15e-9;
            KFactor = 10; % in dB
            AoD_az_range = 180;
            AoD_el_range = 80;
            AoA_az_range = 180;
            AoA_el_range = 80;
    end

    % Initialize R-Rays
    rays = cell(obj.pNumTxArray, obj.pNumRxArray);
    for k = coder.unroll(1:obj.pNumTxArray)
        for j = coder.unroll(1:obj.pNumRxArray)
            rays{k,j} = repmat(struct( ...
                'TimeOfArrival',        0, ...
                'AngleOfDeparture',     zeros(2,1), ...
                'AngleOfArrival',       zeros(2,1), ...
                'Amplitude',            0, ...
                'PhaseShift',           0, ...
                'PolarizationMatrix',   complex(zeros(2))), ...
                1, numRRays);

            % Assign AoD
            aod = [(2*generateRand(obj, 1, numRRays)-1) * AoD_az_range; ...
                   (2*generateRand(obj, 1, numRRays)-1) * AoD_el_range];            

            % Assign AoA
            aoa = [(2*generateRand(obj, 1, numRRays)-1) * AoA_az_range; ...
                   (2*generateRand(obj, 1, numRRays)-1) * AoA_el_range];
               
            % Get LOS D-Ray
            LOSRay = obj.pDRays{k,j}(1); 

            % Assign ToA. Refer to Section 4.3.1 in [1].
            tau = poissonRnd(obj, arrivalRate, 1, numRRays);
            toa = LOSRay.TimeOfArrival + tau;
 
            % Rayleigh distributed amplitude. The amplitude calculation for
            % R-Rays is based upon the LOS D-Ray amplitude. So it has no
            % reflection loss and is independent of polarization types. If
            % the LOS ray gain is 1, the total energy of the R-Rays is
            % 1/K. Refer to (4.2) and (4.3) in [1].
            KfactorLinear = 10^(KFactor/10);
            power = (LOSRay.Amplitude^2 / KfactorLinear) * ...
                exp(-tau/powerDecayTime); 
            amplitude = rayleighRnd(obj, sqrt(power));
            
            % Uniformly distributed phase. Refer to Section 4.3.1 in [1].
            phase = 2*pi*generateRand(obj, ...
                size(amplitude, 1), size(amplitude, 2)); 

            % Random polarization matrix. Refer to Section 4.3.1 in [1].
            polMtx = ones(2, 2*numRRays);
            polMtx(2, 1:2:end) = .1;
            polMtx(1, 2:2:end) = .1*(2*(generateRand(obj, 1, numRRays) > 0.5)-1); 
            polMtx(2, 2:2:end) = (2*(generateRand(obj, 1, numRRays) > 0.5)-1); 
            
            % Pack everything into a structure
            for i = 1:numRRays
                rays{k,j}(i).TimeOfArrival      = toa(i);
                rays{k,j}(i).AngleOfDeparture   = aod(:,i);
                rays{k,j}(i).AngleOfArrival     = aoa(:,i);                    
                rays{k,j}(i).Amplitude          = amplitude(i);
                rays{k,j}(i).PhaseShift         = phase(i);
                rays{k,j}(i).PolarizationMatrix = polMtx(:,(i-1)*2+(1:2));
            end
        end
    end
  end
   
  function rays = generateIntraClusterRays(obj, RRays)
    switch obj.Environment
        case 'Open area hotspot' % Refer to Table 5-2 in [1]
            numICRays = 4;  % Number of intra-cluster rays
            arrivalRate = 1/(0.31e-9);
            powerDecayTime = 4.5e-9;
            KFactor = 4; % in dB
        case 'Street canyon hotspot' % Refer to Table 5-6 in [1]
            numICRays = 4;  % Number of intra-cluster rays
            arrivalRate = 1/(0.31e-9);
            powerDecayTime = 4.5e-9;
            KFactor = 4; % in dB
        otherwise % Large hotel lobby. Refer to Table 5-9 in [1]
            numICRays = 6;  % Number of intra-cluster rays
            arrivalRate = 1/(0.31e-9);
            powerDecayTime = 4.5e-9;
            KFactor = 10; % in dB
    end

    % Cursor rays are combined D-Rays and R-Rays, with LOS ray excluded.
    rays = cell(obj.pNumTxArray, obj.pNumRxArray);
    for k = coder.unroll(1:obj.pNumTxArray)
        for j = coder.unroll(1:obj.pNumRxArray)
            cursorRays = [obj.pDRays{k,j}(2:end), RRays{k,j}];
            rays{k,j} = repmat(struct( ...
                'TimeOfArrival',        0, ...
                'AngleOfDeparture',     zeros(2,1), ...
                'AngleOfArrival',       zeros(2,1), ...
                'Amplitude',            0, ...
                'PhaseShift',           0, ...
                'PolarizationMatrix',   complex(zeros(2))), ...
                1, length(cursorRays) * numICRays);

            % Iterate through all cursor rays to expand them into clusters
            for rayIdx = 1:length(cursorRays)
                % Assign ToA. Refer to Section 4.4. in [1].
                tau = poissonRnd(obj, arrivalRate, 1, numICRays);
                toa = cursorRays(rayIdx).TimeOfArrival + tau;

                % Assign AoD: RMS angle spread is 5 degree for both az and el.
                % Refer to the 2nd paragraph of Section 4.4 in [1].
                aod = cursorRays(rayIdx).AngleOfDeparture + ...
                        generateRandn(obj,2,numICRays) * 5;
                aod = convertToValidAngles(aod);

                % Assign AoA: RMS angle spread is 5 degree for both az and el.
                % Refer to the 2nd paragraph of Section 4.4 in [1].
                aoa = cursorRays(rayIdx).AngleOfArrival + ...
                        generateRandn(obj,2,numICRays) * 5;
                aoa = convertToValidAngles(aoa);

                % Rayleigh distributed amplitude. If the cursor ray gain is
                % 1, the total energy of the cluster is 1/K. Refer to (4.6)
                % and (4.7) in [1].
                KfactorLinear = 10^(KFactor/10);
                power = (cursorRays(rayIdx).Amplitude^2 / KfactorLinear) * ...
                    exp(-tau/powerDecayTime); 
                amplitude = rayleighRnd(obj, sqrt(power));
                
                % Uniformly distributed phase. Refer to Section 4.4. in
                % [1].
                phase = 2*pi*generateRand(obj, ...
                    size(amplitude, 1), size(amplitude, 2)); 
                
                % Polarization matrix is the same as cursor ray. Refer to
                % the last sentence of Section 5.3.4.4 and 5.3.4.5 in [3]. 
                polMtx = cursorRays(rayIdx).PolarizationMatrix;
                
                % Pack everything into a structure
                for i = 1:numICRays
                    idx = (rayIdx-1)*numICRays + i;
                    rays{k,j}(idx).TimeOfArrival      = toa(i);
                    rays{k,j}(idx).AngleOfDeparture   = aod(:,i);
                    rays{k,j}(idx).AngleOfArrival     = aoa(:,i);
                    rays{k,j}(idx).Amplitude          = amplitude(i);
                    rays{k,j}(idx).PhaseShift         = phase(i);
                    rays{k,j}(idx).PolarizationMatrix = polMtx;
                end                
            end
        end
    end
  end
  
  function calculateCIR(obj)    
    txOri = obj.TransmitArrayOrientation;
    rxOri = obj.ReceiveArrayOrientation;
    fc = obj.CarrierFrequency;
    numTxArray = obj.pNumTxArray;
    numRxArray = obj.pNumRxArray;

    % Initialization
    obj.pTxPV    = cell(numTxArray, numRxArray); % Tx steering vectors
    obj.pRxPV    = cell(numTxArray, numRxArray); % Tx steering vectors   
    obj.pRayGain = cell(numTxArray, numRxArray); % Gain of each ray 
    txBF         = cell(numTxArray, numRxArray); % Tx beamforming vectors
    rxBF         = cell(numTxArray, numRxArray); % Rx beamforming vectors
    obj.pAnglesOfDeparture = cell(numTxArray, numRxArray); % Azimuth and elevation angles of departure
    obj.pAnglesOfArrival   = cell(numTxArray, numRxArray); % Azimuth and elevation angles of arrival

    % Calculate CIR for each Tx-Rx array pair
    for k = coder.unroll(1:numTxArray)
        for j = coder.unroll(1:numRxArray)
            allRays = obj.pAllRays{k,j};
          
            % Get AoD and AoA in GCS
            allAoD = [arrayfun(@(x)x.AngleOfDeparture(1), allRays);
                      arrayfun(@(x)x.AngleOfDeparture(2), allRays)];
            allAoA = [arrayfun(@(x)x.AngleOfArrival(1),   allRays);
                      arrayfun(@(x)x.AngleOfArrival(2),   allRays)];

            obj.pAnglesOfDeparture{k,j} = allAoD;
            obj.pAnglesOfArrival{k,j} = allAoA;

            % Convert AoD and AoA from GCS to LCS
            allAoD = convertAngleGCStoLCS(allAoD, txOri);
            allAoA = convertAngleGCStoLCS(allAoA, rxOri);
            
            % Get Tx and Rx phasor/steering vector for each ray
            obj.pTxPV{k,j} = obj.TransmitArray.getPhasorVector( ...
                fc, allAoD); % [NTE NP]
            obj.pRxPV{k,j} = obj.ReceiveArray.getPhasorVector( ...
                fc, allAoA); % [NRE NP]

            % Get amplitude
            amplitude = arrayfun(@(x)x.Amplitude, allRays);
            
            % Get phase (in radian)
            phase = arrayfun(@(x)x.PhaseShift, allRays);

            % Get polarization/reflection loss. NTS_K and NRS_J are the
            % number of input and output streams on this pair of Tx and Rx
            % arrays. NTS_K = NTS and NRS_K = NRS when there is 1 Tx and Rx
            % array.
            switch obj.pIOStreamCase
                case 0  % SU-SISO, 1 Tx & Rx array, no pol, NTS = NRS = 1
                    polLoss = 1;
                case 1  % SU-SISO, 1 Tx & Rx array, pol, NTS = NRS = 1
                    txJV = getJonesVector(obj.TransmitArrayPolarization);
                    rxJV = getJonesVector(obj.ReceiveArrayPolarization);
                    polLoss = shiftdim(arrayfun( ...
                        @(x)rxJV'*x.PolarizationMatrix*txJV, allRays), ... % [1 NP]
                        -2); % [1 NRS_J NTS_K NP]
                case 2  % SU-MIMO, 1 Tx & Rx array, V-V pol, NTS = NRS = 2
                    % V-V pol, it is equivalent to the (1,1) element of the
                    % pol matrix
                    polLoss = shiftdim( ...
                        arrayfun(@(x)x.PolarizationMatrix(1,1), allRays), ... % [1 NP]
                        -2); % [1 1 1 NP]
                case {3, 5} % SU-MIMO, 1 or 2 Tx & Rx array, dual pol, 
                    % NTS = NRS = 2 for case 3 and 4 for case 5.
                    % (VV, VH; HV, HH) pol for each Tx-Rx array pair. It is
                    % equivalent to the pol matrix itself. 
                    polLoss = shiftdim(reshape([...
                        arrayfun(@(x)x.PolarizationMatrix(1,1), allRays); ...
                        arrayfun(@(x)x.PolarizationMatrix(2,1), allRays); ...
                        arrayfun(@(x)x.PolarizationMatrix(1,2), allRays); ... 
                        arrayfun(@(x)x.PolarizationMatrix(2,2), allRays)], ...; [NRS_J*NTS_K NP]
                        2, 2, []), -1); % [1 NRS_J NTS_K NP] 
                case 4 % SU-MIMO, 2 Tx & Rx array, dual pol, NTS = NRS = 2
                    % VV, VH; HV, HH pol for different array pairs. The
                    % polarization matrix has rows along Rx and columns
                    % along Tx. 
                    polLoss = shiftdim( ...
                        arrayfun(@(x)x.PolarizationMatrix(j,k), allRays), ... [1 NP]
                        -2); % [1 NRS_J NTS_K NP]
                otherwise % SU-MIMO, 1 Tx & Rx array, dual pol, NTS = 1, NRS = 2
                    % (VV, VH) pol, it is equivalent to the first column of
                    % the pol matrix
                    polLoss = shiftdim(reshape([...
                        arrayfun(@(x)x.PolarizationMatrix(1,1), allRays); ...
                        arrayfun(@(x)x.PolarizationMatrix(2,1), allRays)], ... [NRS NP]
                        2, 1, []), -1); % [1 NRS_J NTS_K NP]
            end

            % Calculate total amplitude and phase changes. Note that
            % polarization loss is a complex number also indicating some
            % phase change.
            obj.pRayGain{k,j} = shiftdim(amplitude.*exp(1i*phase),-2) .* ... % [1 1 1 NP]
                polLoss; % [1 1 1 NP] for case 2 or [1 NRS_J NTS_K NP] otherwise
            
            % Get BF vectors. For 2x2 I/O streams, the stream order is V
            % and H at both Tx and Rx. For 4x4 I/O streams, the stream
            % order is V, H, V, H at both Tx and Rx. 
            if strcmp(obj.BeamformingMethod, 'Maximum power ray') 
                A = obj.pRayGain{k,j};
                txPV = obj.pTxPV{k,j};
                rxPV = obj.pRxPV{k,j};
                if obj.pIOStreamCase == 2
                    % Special case: two streams are beamed to the same
                    % direction
                    [~, idx] = max(abs(A(:)));
                    txBF{k,j} = conj(txPV(:, [idx idx]));
                    rxBF{k,j} = conj(rxPV(:, [idx idx]));
                else
                    % Find the max power ray for the Tx V/H stream
                    % respectively.
                    [~, idx] = max(max(abs(A), [], 2), [], 4);
                    txBF{k,j} = conj(txPV(:, idx));
                    % Find the max power ray for the Rx V/H stream
                    % respectively.
                    [~, idx] = max(max(abs(A), [], 3), [], 4);
                    rxBF{k,j} = conj(rxPV(:, idx));
                end
            else                
                % Parse Tx/Rx beamforming vectors
                switch obj.pIOStreamCase
                    case 4
                        txBF{k,j} = ...
                            obj.TransmitBeamformingVectors(:,k);  % [NTE NTS_K]
                        rxBF{k,j} = ...
                            obj.ReceiveBeamformingVectors(:,j);   % [NRE NRS_J]
                    case 5
                        txBF{k,j} = ...
                            obj.TransmitBeamformingVectors(:,2*(k-1)+(1:2));  % [NTE NTS_K]
                        rxBF{k,j} = ...
                            obj.ReceiveBeamformingVectors(:, 2*(j-1)+(1:2));  % [NTE NRS_J]
                    otherwise % 0, 1, 2, 3, 6
                        txBF{k,j} = obj.TransmitBeamformingVectors; % [NTE NTS] = [NTE NTS_K]
                        rxBF{k,j} = obj.ReceiveBeamformingVectors;  % [NRE NRS] = [NRE NRS_J]
                end
            end
        end
    end
    
    % Update CIR to include beamforming vectors
    updateCIR(obj, txBF, rxBF);
  end
  
  function updateCIR(obj, txBF, rxBF)
    numTxArray = obj.pNumTxArray;
    numRxArray = obj.pNumRxArray;

    obj.pStaticCIR = cell(numTxArray, numRxArray);
    for k = coder.unroll(1:numTxArray)
        for j = coder.unroll(1:numRxArray)
            NP = length(obj.pAllRays{k,j});
            
            % Tx/Rx gains from phasor vector and beamforming
            txGain = obj.pTxPV{k,j}.' * txBF{k,j}; % [NP  NTS_K]
            rxGain = rxBF{k,j}.' * obj.pRxPV{k,j}; % [NRS_J  NP]
            
            % Channel CIR without phase changes from Doppler shifts
            obj.pStaticCIR{k,j} = ...                     % [1  NRS_J  NTS_K  NP]
                obj.pRayGain{k,j} .* ...                  % [1  NRS_J  NTS_K  NP] or [1 1 1 NP]
                reshape(txGain.', 1, 1, [], NP) .* ...    % [1  1      NTS_K  NP]
                reshape(rxGain,   1, [], 1, NP);          % [1  NRS_J  1      NP]

            % Normalize CIR 
            if obj.NormalizeImpulseResponses
                for idxRx = 1:size(obj.pStaticCIR{k,j}, 2)
                    for idxTx = 1:size(obj.pStaticCIR{k,j}, 3)
                        temp = obj.pStaticCIR{k,j}(1,idxRx,idxTx,:); 
                        obj.pStaticCIR{k,j}(1,idxRx,idxTx,:) = temp/norm(temp(:));
                    end
                end
            end
        end
    end
  end
  
  function generateDopplerShifts(obj)
    % Generate random Rx velocity
    velRx = generateRxVelocity(obj);
    
    % Calculate Doppler shift for each ray. Refer to (4.8) and (4.9) in
    % [1].
    numTxArray = obj.pNumTxArray;
    numRxArray = obj.pNumRxArray;
    obj.pDopplerShift = cell(numTxArray, numRxArray);
    for k = coder.unroll(1:numTxArray)
        for j = coder.unroll(1:numRxArray)
            allAoA = ...
                [arrayfun(@(x)x.AngleOfArrival(1), obj.pAllRays{k,j}); ...
                 arrayfun(@(x)x.AngleOfArrival(2), obj.pAllRays{k,j})];
            allAoA = allAoA*(pi/180); % Convert angle in degree to radians 
            [dirX, dirY, dirZ] = sph2cart(allAoA(1, :), allAoA(2, :), 1);
            dir = [dirX; dirY; dirZ];
            obj.pDopplerShift{k,j} = shiftdim((velRx' * dir) * ...
                obj.CarrierFrequency / physconst('lightspeed'), -2); % [1 1 1 NP]
        end
    end
  end

  function vel = generateRxVelocity(obj)
    switch obj.Environment
        case 'Open area hotspot' % Refer to Table 5-3 in [1]
            sigmaX = 1;
            sigmaY = 1;
            sigmaZ = 0.05;
            tauZ   = 1;
            f0     = 2; 
        case 'Street canyon hotspot' % Refer to Table 5-7 in [1]
            sigmaX = 1;
            sigmaY = 0.1;
            sigmaZ = 0.05;
            tauZ   = 1;
            f0     = 2; 
        otherwise % Large hotel lobby. Refer to Table 5-10 in [1]
            sigmaX = 0.1;
            sigmaY = 0.1;
            sigmaZ = 0;
    end
        
    % Generate velocity in x and y. Refer to (4.11) in [1].
    v_x = sigmaX * generateRandn(obj, 1, 1);
    v_y = sigmaY * generateRandn(obj, 1, 1);
    
    % Generate velocity in z. Refer to (4.12) in [1].
    if sigmaZ > 0          
        % The Ts choice is tricky. 0.1 second seems reasonable because of
        % no dramatic velocity change during 0.1s for a hand-holding phone
        % or tablet. It is also worth trying other numbers. 
        Ts = .1;
        
        % Get covariance matrix. Given the f0, tauZ values above and
        % reasonably small Ts (<<1), M is always positive semi-definite.
        K_z = sigmaZ^2 * exp(-Ts^2/tauZ^2) * cos(2*pi*f0*Ts); 
        M = [sigmaZ^2 K_z; K_z sigmaZ^2];
        
        % Generate 2 samples from gaussian random process with zero mean.
        % Borrow this code from mvnrnd to avoid product dependency. In
        % mvnrnd, cholcov(M) is used instead of chol(M). But for a positive
        % semi-definite M, they are the same. 
        z_t = generateRandn(obj, 1, 2) * chol(M);

        % Velocity in z is the first derivative of z(t)
        v_z = diff(z_t)/Ts; 
    else
        v_z = 0;
    end
    
    vel = [v_x; v_y; v_z];
  end    
end

methods(Access = private) % Channel filter related methods
  function setupChannelFilters(obj)
    obj.cChannelFilter = cell(obj.pNumTxArray, obj.pNumRxArray);
    for k = coder.unroll(1:obj.pNumTxArray)
        for j = coder.unroll(1:obj.pNumRxArray)
            obj.cChannelFilter{k,j} = ...
                comm.internal.channel.VariableDelayChannelFilter( ...
                    'SampleRate', obj.SampleRate, ...
                    'PathDelays', obj.pToA{k,j}, ...
                    'FilterDelaySource', 'Custom', ...
                    'FilterDelay', 7);
        end
    end
    
    updateChannelFilterDelays(obj);
  end
  
  function updateChannelFilterDelays(obj)
    % Get min ToA for all rays
    minToA = min([obj.pToA{:}], [], 2);
    
    for k = coder.unroll(1:obj.pNumTxArray)
        for j = coder.unroll(1:obj.pNumRxArray)
            obj.cChannelFilter{k,j}.PathDelays = obj.pToA{k,j} - minToA(1,1);
        end
    end
  end
  
  function resetChannelFilters(obj)
    % Reset channel filter for each Tx-Rx pair
    for k = coder.unroll(1:obj.pNumTxArray)
        for j = coder.unroll(1:obj.pNumRxArray)
            obj.cChannelFilter{k,j}.reset;
        end
    end      
  end
end

%#exclude coder.internal.RandStream
methods(Access = private) % RNG related methods
  function setupRNG(obj)
    if ~strcmp(obj.RandomStream, 'Global stream')
        if isempty(coder.target)
            obj.pRNGStream = RandStream('mt19937ar', 'Seed', obj.Seed);
        else
            obj.pRNGStream = ...
                coder.internal.RandStream('mt19937ar', 'Seed', obj.Seed);
        end
    end
  end
  
  function resetRNG(obj)
    % Reset random number generator if it is not global stream    
    if ~strcmp(obj.RandomStream, 'Global stream') 
        reset(obj.pRNGStream, obj.Seed);
    end
  end
  
  function y = generateRandn(obj, numRows, numCols) 
    % Generate Gaussian distributed random numbers row-wisely    

    if strcmp(obj.RandomStream, 'Global stream')
        y = (randn(numCols, numRows)).'; 
    else
        y = (randn(obj.pRNGStream, numCols, numRows)).';
    end
  end
  
  function y = generateRand(obj, numRows, numCols) 
    % Generate uniform distributed random numbers row-wisely
    
    if strcmp(obj.RandomStream, 'Global stream') 
        y = (rand(numCols, numRows)).'; 
    else
        y = (rand(obj.pRNGStream, numCols, numRows)).'; 
    end
  end
  
  function y = poissonRnd(obj, lambda, numRows, numCols)
    % Borrow this code from exprnd to avoid product dependency
    
    y = cumsum(-1/lambda .* log(generateRand(obj, numRows, numCols))); 
  end

  function y = rayleighRnd(obj, p)
    % Borrow this code from raylrnd to avoid product dependency

    y = sqrt(generateRandn(obj, size(p, 1), size(p, 2)).^2 + ...
             generateRandn(obj, size(p, 1), size(p, 2)).^2) .* p;
  end
end

methods (Static, Hidden) % Extrinsic methods
  function [envObj, facets] = ...
      buildEnvironment(env, roadWidth, sidewalkWidth, roomDim, txPos, rxPos)    
  
    switch env
      case 'Open area hotspot'
        % Derive vertex points
        txRxPos = [txPos(1,:), rxPos(1,:)];
        xRange = [min(txRxPos), max(txRxPos)];
        extraEdge = max(diff(xRange) * .2, 10);
        X = [xRange(1) - extraEdge, xRange(2) + extraEdge];
        txRxPos = [txPos(2,:), rxPos(2,:)];
        yRange = [min(txRxPos), max(txRxPos)];
        extraEdge = max(diff(yRange) * .2, 10);
        Y = [yRange(1) - extraEdge, yRange(2) + extraEdge];
        
        % Get ground dimension
        facets = [X(1),X(1),X(2),X(2); Y(1),Y(2),Y(2),Y(1); zeros(1, 4)];
        
        % Construct a triangulation object for the ground
        TRI = [4 3 2; 2 1 4];
        TR = triangulation(TRI, facets'); 
        
        % Material indices
        mtlIdx = [1; 1]; % 1 for ground
      case 'Street canyon hotspot'
        % Derive vertex points 
        Xrd = [-roadWidth/2, roadWidth/2];     % X range for road
        X = [-roadWidth/2 - sidewalkWidth, ... % X range including 
              roadWidth/2 + sidewalkWidth];    % sidewalk
        txRxPos = [txPos(2,:), rxPos(2,:)];
        yRange = [min(txRxPos), max(txRxPos)];
        extraEdge = max(diff(yRange) * .2, 10);
        Y = [yRange(1) - extraEdge, yRange(2) + extraEdge];
        Z = [0, max([txPos(3,:), rxPos(3,:)])*1.2];
        
        pts = [X(1),   Y(1), Z(1); ...
               X(2),   Y(1), Z(1); ...
               X(2),   Y(2), Z(1); ...
               X(1),   Y(2), Z(1); ...
               X(1),   Y(1), Z(2); ...
               X(2),   Y(1), Z(2); ...
               X(2),   Y(2), Z(2); ...
               X(1),   Y(2), Z(2); ...
               Xrd(1), Y(1), Z(1); ...
               Xrd(2), Y(1), Z(1); ...
               Xrd(2), Y(2), Z(1); ...
               Xrd(1), Y(2), Z(1)];
                       
        facets = zeros(3, 4, 5);
        % Get road dimension
        facets(:,:,1) = pts(9:12,:)'; 
        
        % Get sidewalk 1 dimension
        facets(:,:,2) = pts([1 9 12 4], :)';
        
        % Get sidewalk 2 dimension
        facets(:,:,3) = pts([10 2 3 11], :)';
        
        % Get wall 1 dimension
        facets(:,:,4) = pts([1 4 8 5], :)';
        
        % Get wall 2 dimension
        facets(:,:,5) = pts([2 3 7 6], :)';        
        
        % Construct a triangulation object
        TRI = [4 1 2; 2 3 4; ... % Ground
               4 8 5; 5 1 4; ... % Left wall
               6 7 3; 3 2 6];    % Right wall
        TR = triangulation(TRI, pts(1:8,:)); 
        
        % Material indices
        mtlIdx = [2; 2; ...    % 1 for road and sidewalk
                  3; 3; 3; 3]; % 3 for wall
      otherwise % Large hotel lobby        
        % Derive vertex points 
        X = [-roomDim(1)/2 roomDim(1)/2];
        Y = [-roomDim(2)/2 roomDim(2)/2];
        Z = [0 roomDim(3)];
        
        pts = [X(1), Y(1), Z(1); 
               X(2), Y(1), Z(1); 
               X(2), Y(2), Z(1); 
               X(1), Y(2), Z(1); 
               X(1), Y(1), Z(2); 
               X(2), Y(1), Z(2); 
               X(2), Y(2), Z(2); 
               X(1), Y(2), Z(2)]; 
        
        facets = zeros(3, 4, 6);
        % Get road dimension
        facets(:,:,1) = pts(1:4,:)'; 
        
        % Get walls dimension
        facets(:,:,2) = pts([1 2 6 5], :)';
        facets(:,:,3) = pts([2 3 7 6], :)';
        facets(:,:,4) = pts([3 4 8 7], :)';
        facets(:,:,5) = pts([4 1 5 8], :)';
        
        % Get ceiling dimension
        facets(:,:,6) = pts(5:8, :)';        

        % Construct a triangulation object
        TRI = [ ...
            4 1 2; 2 3 4; ... % Ground
            1 4 8; 8 5 1; ... % Left wall
            7 3 2; 2 6 7; ... % Right wall
            1 5 6; 6 2 1; ... % Near wall
            7 8 4; 4 3 7; ... % Far wall
            6 5 8; 8 7 6];    % Ceiling        
        TR = triangulation(TRI, pts); 
        
        % Material indices
        mtlIdx = [4; 4; ...                   % 4 for floor
                  5; 5; 5; 5; 5; 5; 5; 5; ... % 5 for wall
                  6; 6];                      % 6 for ceiling                      
    end
    
    envObj = comm.internal.channel.Environment( ...
        'Geometry', TR, ...
        'MaterialLibrarySource', 'Custom', ...
        'MaterialLibrary', wlanTGayChannel.MaterialLibrary, ...
        'MaterialLibraryIndex', mtlIdx);
  end
  
  function [toa, aod, aoa, amplitude, phaseShift, polMatrix] = ...
      performRaytracing(fc, env, roadWidth, sidewalkWidth, roomDim, A0, ...
      txPos, rxPos, txLCS2GCS, rxLCS2GCS, streamCase, plotRays)

    % Build comm.internal.channel.Environment object to pack geometry and
    % material info for the specified scenario
    envObj = wlanTGayChannel.buildEnvironment( ...
        env, roadWidth, sidewalkWidth, roomDim, txPos, rxPos);
    
    % Define order of reflections for different scenarios
    if strcmp(env, 'Large hotel lobby')
        refOrders = [0 1 2];
    else
        refOrders = [0 1];
    end    
    
    % Perform ray-tracing for each Tx-Rx pair. Calculate pathloss (in dB)
    % and phase shift.
    if (streamCase == 0) % Case 0: SU-SISO without pol. 
        rays = ...
            comm.internal.channel.raytracing( ...
                envObj, txPos, rxPos, refOrders, fc);
        % Include atmospheric loss    
        pl = [rays.Pathloss] + ...
            A0*physconst('lightspeed')*[rays.TimeOfArrival];
        phaseShift = [rays.PhaseShift];
    else % Case 1-6: Polarization is on 
        % Assume vertical pol for Tx and Rx when calculating pathloss
        % and phase shift.
        rays = ...
            comm.internal.channel.raytracing( ...
                envObj, txPos, rxPos, refOrders, fc, ...
                'Vertical', 'Vertical', txLCS2GCS, rxLCS2GCS);

        % Exclude polarization loss from V-V pol (the (1,1) element of
        % the pol matrix) and include atmospheric loss
        polMtx = [rays.PolarizationMatrix];
        pl = [rays.Pathloss] + 20*log10(abs(polMtx(1,1:2:end))) + ...
            A0*physconst('lightspeed')*[rays.TimeOfArrival];

        % Exclude phase shift from polarization
        phaseShift = [rays.PhaseShift] - angle(polMtx(1,1:2:end));
    end

    % Pack the structure outside this function for codegen
    toa = {rays.TimeOfArrival};
    aod = {rays.AngleOfDeparture};
    aoa = {rays.AngleOfArrival};
    amplitude = num2cell(10.^(pl/-20));
    phaseShift = num2cell(phaseShift);
    polMatrix = {rays.PolarizationMatrix};

    % Sanity check: The first ray should be LOS
    assert(rays(1).LineOfSight); 
    
    if plotRays
        plot(rays);
    end
  end
end

end

function R = getLCStoGCSRotationMatrix(ori)
% Calculate rotation matrix from local coordinate system (LCS) to global
% coordinate system (GCS) from Tx/Rx orientation, ORI. R' = inv(R) is the
% rotation matrix from GCS to LCS. Refer to Section 6.3.3 in [2].

phi   = ori(1);
theta = ori(2); 
psi   = ori(3);

R = ...
    ([cosd(psi) sind(psi) 0; -sind(psi) cosd(psi) 0; 0 0 1] * ...
     [1 0 0; 0 cosd(theta) sind(theta); 0 -sind(theta) cosd(theta)] * ...
     [cosd(phi) sind(phi) 0; -sind(phi) cosd(phi) 0; 0 0 1])';
end

function angleLCS = convertAngleGCStoLCS(angleGCS, oriLCS)
% Convert [az; el] angle from GCS to LCS given LCS orientation

angleGCS = angleGCS*(pi/180); % Convert angle in degree to radians

% Get [x;y;z] direction in GCS
[dirX, dirY, dirZ] = sph2cart(angleGCS(1,:), angleGCS(2,:), 1);

% Get [x;y;z] direction in LCS
R = getLCStoGCSRotationMatrix(oriLCS);
dirLCS = R'*[dirX; dirY; dirZ];

% Convert [x;y;z] direction to [az;el] in LCS
[azLCS, elLCS] = cart2sph(dirLCS(1,:), dirLCS(2,:), dirLCS(3,:));
angleLCS = [azLCS; elLCS]*180/pi; % In degrees

end

function posGCS = convertPosLCStoGCS(posLCS, oriLCS, originLCS)
% Convert [x;y;z] position from LCS to GCS, given LCS orientation and LCS
% center position in GCS. 

R = getLCStoGCSRotationMatrix(oriLCS);
posGCS = originLCS + R * posLCS;

end

function y = convertToValidAngles(x)
% Convert az and el angles in degree into valid range: az in (-180, 180]
% and el in [-90 90]. The 1st row of x represents az and the 2nd row of x
% represents el. 

az = x(1, :);
el = x(2, :); 

% First convert el into [-360, 360]
el = mod(el, sign(el)*360);

% Convert overflowed el in (90 270) and (-270 -90) into [-90, 90]. Also
% change az direction.
overflowElIdx = find((abs(el) > 90) & (abs(el) < 270));
if ~isempty(overflowElIdx)
    el(overflowElIdx) = 180*sign(el(overflowElIdx)) - el(overflowElIdx);
    az(overflowElIdx) = az(overflowElIdx) + 180; 
end

% Convert overflowed el in [270 360] and [-360 -270] into [-90, 90].
overflowElIdx = find(abs(el) >= 270);
if ~isempty(overflowElIdx)
    el(overflowElIdx) = el(overflowElIdx) - 360*sign(el(overflowElIdx));
end

% Convert overflowed az into (-180, 180]
az = mod(az - 180, -360) + 180; 

y = [az; el];

end

function jv = getJonesVector(pol)
% Get Jones vector for different polarization type. Refer to Table 3-2 in
% [1]. 

switch pol
    case {'Vertical'}
        jv = [1; 0];
    case 'Horizontal'
        jv = [0; 1];
    case 'LHCP'
        jv = 1/sqrt(2)*[1; 1i];
    case 'RHCP'
        jv = 1/sqrt(2)*[1; -1i];
end

end

function h = themeablePatch(X, Y, Z, semanticColor, varargin)

% Convert patch function to be MATLAB themeable
h = patch(X, Y, Z, '', varargin{:});
matlab.graphics.internal.themes.specifyThemePropertyMappings(...
    h, 'FaceColor', semanticColor);

end

function h = themeableScatter3(X, Y, Z, S, semanticColor, varargin)

% Convert scatter3 function to be MATLAB themeable
h = scatter3(X, Y, Z, S, varargin{:});
matlab.graphics.internal.themes.specifyThemePropertyMappings(...
    h, 'MarkerFaceColor', semanticColor);

end

% [EOF] 

