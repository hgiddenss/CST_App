% Copyright Henry Giddens, 2018

% Simulate a Z-directed line source
% Retrieve the farfield radiation pattern and plot it in Matlab
% Retrieve the electric field along different X, Y and Z planes, and plot
% in different Axes.

%% Setup Simulation
CST = CST_MicrowaveStudio(cd,'dipole');

CST.setFreq(2,3);
lamda = 3e8/2.5e9*1e3;

CST.addDiscretePort([0 0],[0 0],[-lamda/4 lamda/4],0.1,50);

CST.setBoundaryCondition('xmin','open add space','xmax','open add space','ymin','open add space',...
    'ymax','open add space','zmin','open add space','zmax','open add space')


CST.addFieldMonitor('farfield',2.5)
CST.addFieldMonitor('efield',2.5)
CST.runSimulation;

%% Retrieve the Farfield and plot
theta = 0:2:180;
phi = 0:2:360;

[Eabs] = CST.getFarField(2.5,theta,phi,'units','directivity');


[p,t] = meshgrid(phi,theta);

ax = axes('parent',figure);
surf(p,t,Eabs);
view([0 90])

ax.CLim(1) = ax.CLim(2) - 40;
xlabel('phi');
ylabel('theta');

%Plot 3D polar pattern:
Eabs(Eabs < -20) = -20;
Eabs1 = Eabs+20; %Make all positive as this is used as the radius

%Spherical coordinates in Matlab have theta -90:90 rather than 0:180
p = deg2rad(0:2:360);
t = deg2rad(90:-2:-90);
[p,t] = meshgrid(p,t);
[X,Y,Z] = sph2cart(p,t,Eabs1);

ax = axes('parent',figure);
surf(X,Y,Z,Eabs,'edgealpha',0.2)
axis equal
axis off;
grid off
colorbar

fprintf('\nMax Directivity = %.2f dBi\n\n',max(Eabs(:)));

%% Get the absolute electric field on the Z = 0 plnae. Plot the field at the 4th Y cell along in the XZ plane, and the 10th in the YZ plane. 

% You can also select Ex, Ey and Ez instead of 'abs' (complex values will
% be returned)

meshInfo = CST.getMeshInfo;
display(meshInfo);

hFig = figure;
hFig.Position(3) = 1200;
ax1 = subplot(1,3,1,'parent',hFig);

[Efield_absZ,x,y,zPos] = CST.getEFieldVector(2.5,'abs','xy',27);
s = surf(ax1,x,y,Efield_absZ);
s.EdgeAlpha = 0;
s.FaceColor = 'interp';
view([0 90]);
colorbar;
colormap(jet);
ax1.CLim(1) = 0;
axis equal;
xlabel('X (mm)');
ylabel('Y (mm)');
title("Z = " + zPos + " mm");

ax2 = subplot(1,3,2,'parent',hFig);
[Efield_absY,x,yPos,z] = CST.getEFieldVector(2.5,'abs','xz',4);
s = surf(ax2,x,z,Efield_absY);
s.EdgeAlpha = 0;
s.FaceColor = 'interp';
view([0 90]);
colorbar;
colormap(jet);
ax2.CLim(1) = 0;
axis equal;
xlabel('X (mm)');
ylabel('Z (mm)');
title("Y = " + yPos + " mm");

ax3 = subplot(1,3,3,'parent',hFig);
[Efield_absX,xPos,y,z] = CST.getEFieldVector(2.5,'abs','yz',10);
s = surf(ax3,y,z,Efield_absX);
s.EdgeAlpha = 0;
s.FaceColor = 'interp';
view([0 90]);
colorbar;
colormap(jet);
ax3.CLim(1) = 0;
axis equal;
xlabel('Y (mm)');
ylabel('Z (mm)');
title("X = " + xPos + " mm");

%% Plot the 3-Dimensional Mesh...


ax = axes('parent',figure);
hold on;
plot3Dmeshgrid(meshInfo.X,meshInfo.Y,meshInfo.Z,'FaceColor','none','EdgeAlpha',0.2,'EdgeColor',[0.2 0.7 0.2]);

[X,Y] = meshgrid(meshInfo.X,meshInfo.Y);
mesh(ax,X,Y,ones(size(Efield_absZ))*zPos,Efield_absZ,'FaceColor','interp');

[X,Z] = meshgrid(meshInfo.X,meshInfo.Z);
mesh(ax,X,ones(size(Efield_absY))*yPos,Z,Efield_absY,'FaceColor','interp');

[Y,Z] = meshgrid(meshInfo.Y,meshInfo.Z);
mesh(ax,ones(size(Efield_absX))*xPos,Y,Z,Efield_absX,'FaceColor','interp');

%axis equal
ax.CLim = [0 300];
