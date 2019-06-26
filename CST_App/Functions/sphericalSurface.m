function [varargout] = sphericalSurface(hAx,theta,phi,R,C,varargin)
%sphericalSurface(hAx,theta,phi,R,varargin) plots polar surface using spherical cooridnates
%theta, phi and r.
%Phi can range from deg2rad(0:360) or deg2rad(-180:180), theta ranges from
%deg2rad(-90:90)

%Assume that if range of values is greater than the limits in radians, then
%they have been entered in degrees
if any(abs(theta) > pi)
    warning('Converting input angle ranges into radians')
    theta = deg2rad(theta);
end
if any(abs(phi) > pi)
    warning('Converting input angle ranges into radians')
    phi = deg2rad(phi);
end

st = size(theta);

if any(st == 1)
[phi,theta] = meshgrid(phi,theta);
end
[X,Y,Z] = sph2cart(theta,phi,R);

s = surf(hAx,X,Y,Z,C,varargin{:});
if nargout == 1
    varargout{1} = s;    
end
    
end

