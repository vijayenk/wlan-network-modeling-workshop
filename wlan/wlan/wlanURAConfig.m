classdef wlanURAConfig < comm.internal.ConfigBase
%wlanURAConfig Uniform rectangular array
%   URA = wlanURAConfig creates a uniform rectangular array (URA) object,
%   URA, for the wlanTGayChannel System object. This object models a URA 
%   formed with isotropic antenna elements. The default array is a 2x2 URA
%   with element spacing of 0.2 meters.
% 
%   URA = wlanURAConfig(Name,Value) creates a URA object, URA, with the
%   specified property Name set to the specified value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
% 
%   When one element of the Size property is 1, the array is reduced to
%   a uniform linear array (ULA). When both elements of the Size property
%   are 1, the array is reduced to one single element.
%
%   WLANURACONFIG properties:
%
%   Element        - Array element (read-only)
%   Size           - Array size
%   ElementSpacing - Element spacing (m)
%
%   % References:
%   % [1] A. Maltsev and et. al, Channel Models for IEEE 802.11ay, 
%   % IEEE 802.11-15/1150r9, Mar. 2017.
%   % [2] A. Maltsev and et. al, Channel Models for 60GHz WLAN Systems, 
%   % IEEE 802.11-09/0334r8, May 2010.

% Copyright 2018-2024 The MathWorks, Inc.

%#codegen

properties (Constant)
    %Element  Array element
    %   Element of the array is isotropic. 
    Element = 'isotropic'
end

properties 
    %Size Array size
    %   Specify the size of antenna array as a 1-by-2 positive, integer
    %   vector representing the number of rows and columns respectively.
    %   The rows of the array are along the y-axis; the columns of the
    %   array are along the x-axis. The array normal is along the z-axis.
    %   When one element of this property is 1, the array is reduced to a
    %   uniform linear array (ULA). When both elements of this property are
    %   1, the array is reduced to one single element. The default value of
    %   this property is [2 2].
    Size 
    %ElementSpacing Element spacing (m)
    %   Specify the element spacing in meters as a 1-by-2 positive, vector
    %   representing spacing between rows and columns respectively. The
    %   rows of the array are along the y-axis; the columns of the array
    %   are along the x-axis; The array normal is along the z-axis. The
    %   default value of this property is [0.2 0.2].
    ElementSpacing
end

methods
  function obj = wlanURAConfig(varargin)
    obj@comm.internal.ConfigBase(varargin{:});
    
    if isempty(coder.target)
        if isempty(obj.Size)
            obj.Size = [2 2];
        end
        if isempty(obj.ElementSpacing)
            obj.ElementSpacing = [0.2 0.2];
        end
    else
        if ~coder.internal.is_defined(obj.Size)
            obj.Size = [2 2];
        end
        if ~coder.internal.is_defined(obj.ElementSpacing)
            obj.ElementSpacing = [0.2 0.2];
        end
    end    
  end 
  
  function obj = set.Size(obj, size)
    propName = 'Size';
    validateattributes(size, {'double'}, ...
        {'real','positive','integer','size',[1 2]}, ...
        [class(obj) '.' propName], propName);
    obj.(propName) = size;    
  end
      
  function obj = set.ElementSpacing(obj, es)
    propName = 'ElementSpacing';
    validateattributes(es, {'double'}, ...
        {'real','positive','finite','size',[1 2]}, ...
        [class(obj) '.' propName], propName);
    obj.(propName) = es;    
  end
  
  function N = getNumElements(obj)
    %GETNUMELEMENTS Return the number of elements 
    %   N = getNumElements(AA) returns the number of elements, N, in the
    %   URA object, AA.
    N = arrayfun(@(x)(prod(x.Size)), obj);
  end

  function elementPos = getElementPosition(obj)
    %GETELEMENTPOSITION Return element position in local coordinate system
    %   POS = getElementPosition(AA) returns element positions, POS, in a
    %   3-by-N matrix with each column representing the [x; y; z] position
    %   of one element in the local coordinate system (LCS). N is the
    %   number of elements of the URA. The elements are ordered column-wise
    %   (along y-axis) from a view of positive z-axis in LCS.
    
    Nx = obj.Size(2);
    Ny = obj.Size(1);
    xPos = (0:Nx-1)*obj.ElementSpacing(2);
    xPos = xPos - xPos(end)/2;
    yPos = (0:Ny-1)*obj.ElementSpacing(1);
    yPos = yPos(end)/2 - yPos;
    
    elementPos = zeros(3, getNumElements(obj));
    elementPos(1, :) = kron(xPos, ones(1, Ny));
    elementPos(2, :) = repmat(yPos, 1, Nx);
  end
   
  function pv = getPhasorVector(obj, fc, angles)
    %GETPHASORVECTOR Return element phasor/steering vectors in local coordinate system
    %   PV = getPhasorVector(AA, FC, ANGLES) returns phasor/steering
    %   vectors, PV, for the URA object, AA, given the frequency, FC, and
    %   spherical angles, ANGLES. The FC must be a double precision,
    %   positive scalar. ANGLES must be a double precision, 2-by-M matrix
    %   representing M spherical angles in the local coordinate system. The
    %   first row of ANGLES represents the azimuth angles which are
    %   measured from the positive x-axis counterclockwise and must be in
    %   (-180, 180]. The second row of ANGLES represents the elevation
    %   angles which are measured from the x-y plane and must be in (-90,
    %   90]. PV is a double precision, N-by-M matrix with each column
    %   representing the phasor vector for the corresponding column in
    %   ANGLES, where N is the number of elements of the URA.
    
    %   Refer to (3.9)-(3.11) in [1].
    
    if all(obj.Size == 1)
        pv = ones(1, size(angles, 2)); 
        return;
    end
    
    % Convert angles from [az;el] to [x;y;z]. 
    az = angles(1,:);
    el = angles(2,:);
    dir = [cosd(el).*cosd(az);...
           cosd(el).*sind(az);...
           sind(el)];    
       
    % Get phasor/steering vector for the specified array
    NE = getNumElements(obj);
    ePos = getElementPosition(obj);
    pv = 1/sqrt(NE) * ...
        exp(1i * (2*pi*fc/physconst('lightspeed')) * ePos' * dir);
  end
end
end

% [EOF]
