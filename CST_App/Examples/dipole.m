% Copyright Henry Giddens, 2018

%Simulate a Z-directed line source, retrieve the radiation pattern and plot it in Matlab

CST = CST_MicrowaveStudio(cd,'dipole');

CST.setFreq(2,3);
lamda = 3e8/2.5e9*1e3;

CST.addDiscretePort([0 0],[0 0],[-lamda/4 lamda/4],0.1,50);

CST.setBoundaryCondition('xmin','open add space','xmax','open add space','ymin','open add space',...
    'ymax','open add space','zmin','open add space','zmax','open add space')


CST.addFieldMonitor('farfield',2.5)
CST.runSimulation;

theta = 0:5:180;
phi = 0:5:360;

[Eabs] = CST.getFarField(2.5,theta,phi,'units','directivity');


[p,t] = meshgrid(phi,theta);

ax = axes('parent',figure);
surf(p,t,Eabs);
view([0 90])

ax.CLim(1) = ax.CLim(2) - 40;
xlabel('phi');
ylabel('theta');

%Plot 3D polar pattern:
Eabs(Eabs < -40) = -40;
Eabs1 = Eabs+40; %Make all positive as this is used as the radius

p = deg2rad(0:5:360);
t = deg2rad(90:-5:-90);
[p,t] = meshgrid(p,t);
[X,Y,Z] = sph2cart(p,t,Eabs1);

ax = axes('parent',figure);
surf(X,Y,Z,Eabs)
axis equal
axis off;
grid off
colorbar

fprintf('\nMax Directivity = %.2f dBi\n\n',max(Eabs(:)));