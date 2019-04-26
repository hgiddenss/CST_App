function [varargout] = plot3DPatternCST(CST,f,ffid,EMin,hAx)
%READANDPLOTPATTERNCST Summary of this function goes here
%   Detailed explanation goes here

theta = 0:3:180;
phi = -180:3:180;

[Eabs] = CST.getFarField(f,theta,phi,'units','directivity','ffid',ffid);

EMax = max(Eabs(:));
EMax = ceil(EMax/5)*5;

EMin = EMax - abs(EMin);

Eabs(Eabs < -abs(EMin)) = -abs(EMin);
Eabs1 = Eabs+abs(EMin); %Make all positive as this is used as the radius

if nargin == 4
    hAx = gca;
end

t = deg2rad(90:-3:-90);
p = deg2rad(-180:3:180);

s = sphericalSurface(hAx,t,p,Eabs1,Eabs,'edgealpha',0.2,'FaceColor','interp');
axis equal
cbar = colorbar;

cbar.Position = [0.8338    0.240    0.0250  0.58];

cbar.Label.String = 'Directivity (dBi)';
hAx.CLim = [-abs(EMin) EMax];
try
    hAx.Colormap = antennaColormap;
catch
    hAx.Colormap = jet(64);
end

hAx.Visible = 'off';

if nargout == 1
    varargout{1} = s;
end

end

