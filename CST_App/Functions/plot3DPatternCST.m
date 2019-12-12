function [varargout] = plot3DPatternCST(CST,f,ffid,EMin,hAx,units)
%READANDPLOTPATTERNCST Summary of this function goes here
%   Detailed explanation goes here

if nargin==5
    units = 'directivity';
end

if strcmpi(units,'normalized')
    units = 'directivity';
    norm = true;
else
    norm = false;
end
    

d_Theta = 2;
d_Phi = 2;

theta = 0:d_Theta:180;
phi = -0:d_Phi:360;

[Eabs] = CST.getFarField(f,theta,phi,'units',units,'ffid',ffid);


EMax = max(Eabs(:));
if norm
    Eabs = Eabs - EMax;
end


EMax = max(Eabs(:));
EMax = ceil(EMax/5)*5;

EMin = EMax - abs(EMin);

Eabs(Eabs < -abs(EMin)) = -abs(EMin);
Eabs1 = Eabs+abs(EMin); %Make all positive as this is used as the radius

if nargin == 4
    hAx = gca;
end

t = deg2rad(90:-d_Theta:-90);
p = deg2rad(-180:d_Phi:180);

s = sphericalSurface(hAx,p,t,Eabs1',Eabs','edgealpha',0.2,'FaceColor','interp');
axis equal
cbar = colorbar;

%cbar.Position = [0.8338    0.240    0.0250  0.58];


switch lower(units)
    case 'directivity'
        cbar.Label.String = 'Directivity (dBi)';
    case {'gain','realised gain','realized gain'}
        cbar.Label.String = 'Gain (dB)';
end
if norm 
    cbar.Label.String = 'Normalized Gain (dB)';
end
    
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

