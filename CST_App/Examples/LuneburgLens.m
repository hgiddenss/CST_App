% Copyright Henry Giddens, 2018
% Build and add a luneburg lens decritized into 10 layers into a cst file:

%Define descritized cylinders (default units is in mm):
% Lens Radius:
f = 2.4e9;
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
    CST.addCylinder(r(i),r(i-1),'z',0,0,Z,name,component,material)
    
    %CST.addSphere(0,0,R,r(i),0,0,name,component,material)
end

%Set the frequency span to 2-3 GHz
CST.setFreq(2,3)

%Add a line source to the side of the lens:
CST.addDiscretePort([0 0],[R R],Z,0.1,50)
CST.addDiscretePort([R R]*cosd(45),[R R]*cosd(45),Z,0.1,50)
%Set the Boundary Conditions:
CST.setBoundaryCondition('xmin','open add space','xmax','open add space','ymin',...
    'open add space','ymax','open add space')
CST.setBoundaryCondition('Zmin','Electric','ZMax','Electric');

%Set a symmetry plane on the y-z plane
%CST.addSymmetryPlane('X','magnetic')
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
%%
theta = 90;
phi = 0:360;

[Eabs1] = CST.getFarField(2.4,theta,phi,'units','directivity','ffid','farfield (f=2.4) [1]');
[Eabs2] = CST.getFarField(2.4,theta,phi,'units','directivity','ffid','farfield (f=2.4) [2]');

minVal = -5;
Eabs1(Eabs1 < minVal) = minVal;
Eabs2(Eabs2 < minVal) = minVal;
%%
pax = polaraxes('parent',figure);
hold on
plot(pax,deg2rad(-180:180),Eabs1);
plot(pax,deg2rad(-180:180),Eabs2);
pax.RLim = [-5 10];
pax.ThetaLim = [0 180];




%CST.save;

