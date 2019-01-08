% Copyright Henry Giddens, 2018

%Build and add a luneburg lens decritized into 10 layers into a cst file:

%Define descritized cylinders (default units is in mm):
% Lens Radius:
f = 60e9;
lamda = 3e8/f*1e3;
R = 1.5*lamda;

r = 0:R/30:R;

%Permittivity: 
Er = (2 - (r/R).^2);

%Plot in matlab:
theta = linspace(0,2*pi,31);
[th,rr] = meshgrid(theta,r);
[~,er] = meshgrid(theta,Er);
[x,y,z] = pol2cart(th,rr,er);
ax = axes('parent',figure);
s = surf(x,y,z);
s.EdgeAlpha = 0.1;
axis equal
view([0 90])
grid off;
box on;
cbar = colorbar;
cbar.Label.String = 'Relative Permittivity';


%% Build in CST:

%Create new CST_MWS session in current directory

CST = CST_MicrowaveStudio(cd,'LuneburgLens.cst');  %Note - file will only be saved if CST.save is called

% Add the descritized graded index material profile to the materials available in CST
Er_av = mapAverage(sqrt(Er)).^2; %take the average Er value assuming linearly spaced radii

map = parula(length(Er_av));
for i = 1:length(Er_av)
    C = (map(i,:));
    material = ['Material',num2str(i)];
    CST.addNormalMaterial(material,Er_av(i),1,C);
end

%Add the cylinders with each dielectric constant.
%Use a height of 0.5 wavelengths
Z = [-0.25 0.25].*lamda;

for i = 2:length(r)
    name = sprintf('cylinder %d',i);
    component = 'Component 1';
    material = ['Material',num2str(i-1)];
    %CST.addCylinder(r(i),r(i-1),'z',0,0,Z,name,component,material)
    
    CST.addSphere(0,0,R,r(i),0,0,name,component,material)
end

%Set the frequency span to 2-3 GHz
CST.setFreq(2,3)

%Add a line source to the side of the lens:
CST.addDiscretePort([0 0],[R R],Z,0.1,50)

%Set the Boundary Conditions:
CST.setBoundaryCondition('xmin','open add space','xmax','open add space','ymin',...
    'open add space','ymax','open add space')
CST.setBoundaryCondition('Zmin','Electric','ZMax','Electric');

%Set a symmetry plane on the y-z plane
CST.addSymmetryPlane('X','magnetic')
CST.addSymmetryPlane('Z','electric')

CST.setBackgroundLimits([lamda lamda],[lamda lamda],[0 0]);

%Add a field monitor at 2.4GHz
CST.addFieldMonitor('EField',2.4);
CST.addFieldMonitor('farfield',2.4);

% Choose the TD solver (default)
CST.setSolver('td')

%Run the simulation:
CST.runSimulation;

% Save the model
%CST.save;

%% Luneburg Transform:
g = geoTrans;
xy = 'C:\Users\Henry-Laptop\Documents\Pointwise\Practice\xy_luneburg.dat';
uv = 'C:\Users\Henry-Laptop\Documents\Pointwise\Practice\uv_luneburg.dat';
g.importGrid(uv,'uv');
g.importGrid(xy,'xy');
g.transform

g.U = g.U-4;

%[g.X,g.Y] = rotateMatrix(g.X,g.Y,45);
%[g.U,g.V] = rotateMatrix(g.U,g.V,45);

R = sqrt(2);

[th,r] = cart2pol(g.X,g.Y);

Er = (2 - (r./R).^2);

a = 1.5;
syms n t rr
expr2 = vpaintegral(asin(t/a)/(sqrt(t^2 - (n*rr)^2)),t,[1 a]);
f = n == (1+sqrt(1-(n*rr/a).^2))^0.5 * exp(-1/pi * expr2);

% for i = 1:10
%     rad = (i-1)/10;
% 
%     f1 = subs(f,'rr',rad);
%     n3(i) = double(vpasolve(f1));
%     display(i)
% end
% 
% n3(11) = 1;

rad = 0:0.1:1;
Er3 = n3.^2;
r1 = r/max(r(:));

Er1 = interp1(rad,Er3,r1);

[x,y,z] = pol2cart(th,r,Er1);
%ax = axes('parent',figure);
%s = surf(x,y,z);

g.Eps0 = Er1;
g.ErMin = 1;

%g.U(g.Y >= 0) = g.X(g.Y >= 0);
%g.V(g.Y >= 0) = g.Y(g.Y >= 0);

g.transform
g.Er(g.Er > 8) = 1;
ax = gca;
ax.CLim = [1 3];

f = 60e9;
lamda = 3e8/f*1e3;
g.U = g.U*2*lamda;
g.V = g.V*2*lamda;

f = 60;

[polyShapes,levels] = g.getContours(8);

if true
%CST = CST_MicrowaveStudio('C:\Users\Henry-Laptop\Documents\3D printing\LuneburgLens\','LuneburgFlat3D.cst');
CST = CST_MicrowaveStudio('C:\Users\Henry-Laptop\Documents\3D printing\LuneburgLens\','LuneburgDefocussedFlat2Da.cst');

Er = levels;
ColIdx = jet(numel(levels));

for i = 1:numel(levels)
    name = ['material',num2str(i)];
    CST.addNormalMaterial(name,Er(i),1,ColIdx(i,:));
end
CST.setUpdateStatus(false);
for i = 1:numel(polyShapes)
    name = ['shape',num2str(i)];
    component = 'component1';
    material = ['material',num2str(i)];
    CST.addPolygonBlock(polyShapes{i},1.89,name,component,material);
    %CST.rotateObject(component,name,[0 0 45],[0 0 0],true,7)
end

CST.setUpdateStatus(true);
CST.addToHistory;
CST.mergeCommonSolids('component1');
%CST,X,Y,Er,map,height,varargin)
CST.setBackgroundLimits([20 20],[10 80],[0 0])
CST.addFieldMonitor('EField',f)
CST.addFieldMonitor('FarField',f)
CST.setFreq(f*0.9,f*1.1);
%CST.addSymmetryPlane('X','Magnetic')
CST.addSymmetryPlane('Z','Electric')

end
%g.buildCST(f,lamda/4);

%% Square Luneburg Transform

[u,v] = meshgrid(-1:2/30:1,-1:2/30:1);

g1 = geoTrans;
xy = 'C:\Users\Henry-Laptop\Documents\Pointwise\Practice\xy_luneburg.dat';
g1.importGrid(xy,'xy');
g1.U = u;
g1.V = v;

R = sqrt(2);
[th,r] = cart2pol(g1.X,g1.Y);
Er = (2 - (r./R).^2);

a = 1.5;
syms n t rr
expr2 = vpaintegral(asin(t/a)/(sqrt(t^2 - (n*rr)^2)),t,[1 a]);
f = n == (1+sqrt(1-(n*rr/a).^2))^0.5 * exp(-1/pi * expr2);

for i = 1:10
    rad = (i-1)/10;

    f1 = subs(f,'rr',rad);
    n3(i) = double(vpasolve(f1));
    display(i)
end

n3(11) = 1;

rad = 0:0.1:1;
r1 = r/max(r(:));

Er1 = interp1(rad,Er3,r1);

[x,y,z] = pol2cart(th,r,Er1);

g1.Eps0 = Er1;
g1.transform
ax = gca;
ax.CLim = [0 4.5];

f = 60e9;
lamda = 3e8/f*1e3;
g1.U = g1.U*4*lamda;
g1.V = g1.V*4*lamda;

f = 60;
%g1.buildCST(f,lamda/4);
