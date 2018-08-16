function [m] = plot3Dmeshgrid(varargin)
%PLOT3DMESHGRID     3D Mesh Grid
%   plot3Dmeshgrid(X,Y,Z) plots into the current window a 3D mesh that would
%   typically be returned by the function [Xgrid,Ygrid,Zgrid] =  meshgrid(X,Y,Z)
% 
%   plot3Dmeshgrid(...,'PropertyName',PropertyValue,...) sets the value of
%   the specified surface property.  Multiple property values can be set
%   with a single statement. Use the standard mesh object properties.
%
%   plot3Dmeshgrid(AX,...) plots into AX instead of GCA.
%
%   plot3Dmeshgrid returns a handle to a surface plot object.
%
%   If 'FaceColor', 'EdgeColor', and 'EdgeAlpha' are not specified as
%   property/value pair arguments, then they will be set to their defaults
%   which are:
%   'FaceColor' = 'none'
%   'EdgeColor' = [0.3 0.3 0.3]
%   'EdgeAlpha' = 0.1
%
%   AXIS, CAXIS, COLORMAP, HOLD, SHADING, HIDDEN and VIEW set figure,
%   axes, and surface properties which affect the display of the mesh.
%
%   See also MESH MESHC, MESHZ, CONTOURSLICE.
%
%   Copyright Henry Giddens 2018 (contact h.giddens@qmul.ac.uk)  



%Some of this code (used for input argument parsing) is copied from mesh.m
%(Copyright The Mathworks Inc) 
[~, cax, args] = parseplotapi(varargin{:},'-mfilename',mfilename);
[reg, prop]=parseparams(args);


if isempty(cax) || ishghandle(cax,'Axes')
    cax = newplot(cax);
else
    cax = ancestor(cax,'Axes');
end
cax.NextPlot = 'Add';

%Check if 'FaceColor', 'EdgeAlpha', or 'EdgeColor' are arguments in prop,
%if not set some default values.
if ~ any(cellfun(@(x)strcmpi(x,'FaceColor'),prop))
    prop{end+1} = 'FaceColor';
    prop{end+1} = 'none';
end
if ~any(cellfun(@(x)strcmpi(x,'EdgeAlpha'),prop))
    prop{end+1} = 'EdgeAlpha';
    prop{end+1} = 0.1;
end 
if ~any(cellfun(@(x)strcmpi(x,'EdgeColor'),prop))
    prop{end+1} = 'EdgeColor';
    prop{end+1} = [0.3 0.3 0.3];
end

x = reg{1};
y = reg{2};
z = reg{3};

nZ = numel(z);
nY = numel(y);

mm = gobjects(nY+nZ,1);

[X,Y] = meshgrid(x,y);
for i = 1:nZ
    mm(i) = mesh(cax,X,Y,ones(size(X)).*z(i),ones(size(X)),prop{:});
end

[X,Z] = meshgrid(x,z);
for i = 1:nY
    mm(nZ+i) = mesh(cax,X,ones(size(X))*y(i),Z,ones(size(X)),prop{:});
end

view(3);

if nargout == 1
    m = mm;
end

end

