%This example takes a while to run, and is quite slow, but it is a pretty
%cool way to add 3D surfaces. If you give the surface a thickness, then it
%can be used to intersect solids and create nice shapes on the surface of
%different materials

%Create a sufrave which varies sinusoidally in the radial axis away from the center point

th = 0:2*pi/20:2*pi;
r = 0:0.1:1;   %Add more resolution if you can be prepared to wait for CST to build
r1 = 0.05:0.95/10:1; %Inner radius doesnt start at 0 to avoid singularity
[R,TH] = meshgrid(r1,th);
z = repmat((sin(r*6*pi)),21,1);

[X,Y,Z] = pol2cart(TH,R,z);
X = X*100;
Y = Y*100;
Z = (Z*10);

figure; surf(X,Y,Z); axis equal;

%%
%Use the add3DSurface function. add3DSurfaceCST triangulates the surface
%with each triangle lying in the same plane. This then calls a method
%called addPolygonBlock3D from the CST_MicrowaveStudio class.
CST = CST_MicrowaveStudio(cd,'test.cst');
add3DSurfaceCST(CST,X,Y,Z,0,'PEC','component1');


%%
%Copy the surface and transforom so it has a thickness. We cannot simply
%extrude each triangle as they are all at different angles
CST.addComponent('component2');
CST.translateObject('component1',0,0,1,1,'destination','component2');

%Connect the two surfaces using the matching faces
for i = 1:400
component1 = 'component1'; face1 = ['Brick',num2str(i)];
component2 = 'component2'; face2 = ['Brick',num2str(i)]; name = ['Solid',num2str(i)];
connectFaces(CST,component1,face1,component2,face2,'component3',name,'PEC'); 
end
CST.addCylinder(0.05*101,0,'z',0,0,[Z(1),Z(1)+1],'cylinder1','component3','PEC')

%You could now delete components 1 and 2 as they are not needed
